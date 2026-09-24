/// Shared route-backed modal, filter, calendar, and accessible-state primitives.
///
/// These widgets own interaction and accessibility mechanics only. Feature
/// routes remain the owners of durable identity, loading, and persistence.
library;

import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:mine_flow/core/navigation/route_observer.dart';
import 'package:mine_flow/l10n/app_localizations.dart';

/// The responsive presentation mode for an [AppResponsiveSheet].
enum AppResponsiveSheetMode { form, readOnlyInspector, selection }

/// Why a route-hosted presentation requested dismissal.
enum AppDismissReason {
  closeButton,
  cancel,
  barrier,
  escape,
  browserNavigation,
  systemBack,
  drag,
  parentNavigation,
}

/// Result of a dismissal request.
enum AppDismissDecision { dismiss, confirmDiscard, blockedBusy }

/// Resolves the common clean/dirty/busy dismissal contract.
class AppDismissController {
  /// Creates a controller for the current editable route state.
  AppDismissController({required this.isDirty, required this.isBusy});

  /// Whether user-editable data differs from its saved baseline.
  final bool isDirty;

  /// Whether an uncancellable operation is in progress.
  final bool isBusy;

  /// Evaluates a dismissal consistently, regardless of its source.
  AppDismissDecision requestDismiss(AppDismissReason reason) {
    if (isBusy) return AppDismissDecision.blockedBusy;
    if (isDirty) return AppDismissDecision.confirmDiscard;
    return AppDismissDecision.dismiss;
  }
}

/// Removes a final form/detail segment while preserving the URL query string.
Uri closeSheetUri(Uri current) {
  final segments = List<String>.of(current.pathSegments);
  if (segments.isEmpty) return current;
  if (segments.last == 'form' || segments.last == 'detail') {
    segments.removeLast();
  } else if (segments.length > 1) {
    segments.removeLast();
  }
  return current.replace(
    path: '/${segments.join('/')}',
    queryParameters: current.queryParameters.isEmpty
        ? null
        : current.queryParameters,
  );
}

/// Resolves the desktop sheet width without allowing viewport overflow.
double appResponsiveSheetWidth(double viewportWidth) =>
    (viewportWidth * .40).clamp(480.0, 600.0);

/// Parses a durable record identifier from a route parameter.
String? validRouteRecordId(String? value) {
  final candidate = value?.trim();
  if (candidate == null || candidate.isEmpty || candidate.contains('/')) {
    return null;
  }
  return candidate;
}

/// Wraps sheet footer actions in a responsive Wrap layout enforcing >=48dp touch targets.
Widget _wrapSheetFooter(Widget footer) {
  if (footer is Row) {
    final rawChildren = footer.children;
    final List<Widget> items = [];
    for (final c in rawChildren) {
      if (c is SizedBox && c.width != null && c.child == null) {
        continue;
      }
      Widget inner = c;
      if (inner is Expanded) inner = inner.child;
      if (inner is Flexible) inner = inner.child;
      // STEP-55.11: forui's `FButton.md` content constraint is 44x44 on touch
      // platforms (its own touch default), below this app's 48dp minimum
      // target standard. The outer ConstrainedBox alone is not sufficient —
      // the button's own constraint is what accessibility/tooling measures —
      // so promote the button to `FButtonSizeVariant.lg` (48x48 on touch,
      // 40x40 on desktop) when the inner action is a plain FButton.
      if (inner is FButton && inner.size == FButtonSizeVariant.md) {
        inner = FButton(
          key: inner.key,
          onPress: inner.onPress,
          onLongPress: inner.onLongPress,
          onDisabledPress: inner.onDisabledPress,
          onDoubleTap: inner.onDoubleTap,
          onSecondaryPress: inner.onSecondaryPress,
          onSecondaryLongPress: inner.onSecondaryLongPress,
          style: inner.style,
          variant: inner.variant,
          size: FButtonSizeVariant.lg,
          autofocus: inner.autofocus,
          focusNode: inner.focusNode,
          onFocusChange: inner.onFocusChange,
          onHoverChange: inner.onHoverChange,
          onVariantChange: inner.onVariantChange,
          shortcuts: inner.shortcuts,
          actions: inner.actions,
          semanticsLabel: inner.semanticsLabel,
          semanticsTooltip: inner.semanticsTooltip,
          selected: inner.selected,
          child: inner.child,
        );
      }
      items.add(
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: FittedBox(fit: BoxFit.scaleDown, child: inner),
        ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: items,
    );
  }
  return ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 48),
    child: footer,
  );
}

/// A modal, route-hosted sheet that changes geometry at the 800dp boundary.
class AppResponsiveSheet extends StatefulWidget {
  /// Creates a shared responsive sheet.
  const AppResponsiveSheet({
    super.key,
    required this.routeIdentity,
    required this.title,
    required this.mode,
    required this.body,
    required this.onDismissApproved,
    this.subtitle,
    this.footer,
    this.isDirty = false,
    this.isBusy = false,
    this.onRequestClose,
    this.onDiscard,
    this.mobileFullPage = false,
  });

  /// Durable route identity for restoration and semantics.
  final String routeIdentity;

  /// Visible and semantic sheet heading.
  final String title;

  /// Optional contextual subtitle.
  final String? subtitle;

  /// The intended presentation semantics.
  final AppResponsiveSheetMode mode;

  /// The scrollable body content.
  final Widget body;

  /// Optional fixed action area.
  final Widget? footer;

  /// Whether changes must be confirmed before closing.
  final bool isDirty;

  /// Whether dismissal is currently unavailable.
  final bool isBusy;

  /// Observes every close request before the shared policy evaluates it.
  final ValueChanged<AppDismissReason>? onRequestClose;

  /// Clears feature dirty state before the single approved route pop.
  final VoidCallback? onDiscard;

  /// Performs the one route pop authorized by the shared policy.
  final VoidCallback onDismissApproved;

  /// Allows the two approved long-record mobile details to render full page.
  final bool mobileFullPage;

  @override
  State<AppResponsiveSheet> createState() => _AppResponsiveSheetState();
}

class _AppResponsiveSheetState extends State<AppResponsiveSheet>
    with RouteAware {
  /// Whether an approval has already been issued for this sheet instance.
  ///
  /// STEP-55.11: dismissal is a one-shot transition. Once the shared policy
  /// has authorized a close, no further request may re-enter the flow.
  bool _hasApproved = false;

  /// Guards the single authorized route pop.
  ///
  /// STEP-55.11: `onPopInvokedWithResult` fires while the navigator is still
  /// locked from the prevented pop (`canPop: false`), so calling
  /// `onDismissApproved()` — which pops — synchronously inside it asserts
  /// `!_debugLocked`. Deferring to the next microtask lets the lock release
  /// first. The flag also prevents a second dismissal (e.g. the success
  /// listener's delayed close) from racing the first.
  bool _isDismissing = false;

  /// Guards the single discard-confirmation dialog.
  ///
  /// STEP-55.11: a rapid hammer (5x Escape, repeated barrier taps while dirty)
  /// reaches `_requestDismiss` before any of the earlier requests resolve,
  /// because `AppDirtyDismissDialog.show` awaits a user decision and the
  /// `_isDismissing` guard only trips after approval. Each unguarded request
  /// pushed its own dialog, stacking N dialogs for one sheet. Only the first
  /// request may open the dialog; later ones are dropped while it is open.
  bool _isConfirming = false;
  late final FocusScopeNode _focusScopeNode = FocusScopeNode(
    debugLabel: 'AppResponsiveSheetScope',
    traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
  );

  /// The modal route this sheet is hosted on, for [RouteAware] subscription.
  ModalRoute<void>? _subscribedRoute;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to the global route observer so we receive didPushNext/didPop
    // callbacks when the navigator changes routes above or beneath us.
    final route = ModalRoute.of<void>(context);
    if (route != _subscribedRoute) {
      if (_subscribedRoute != null) {
        routeObserver.unsubscribe(this);
      }
      _subscribedRoute = route;
      if (route != null) {
        routeObserver.subscribe(this, route);
      }
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _focusScopeNode.dispose();
    super.dispose();
  }

  @override
  void deactivate() {
    // STEP-55.0 RESIDUAL: when GoRouter declaratively replaces the page stack
    // (e.g. sidebar navigation, logout, or browser URL replacement while the
    // sheet is open), the framework deactivates the widget before disposal.
    // PopScope does not fire for declarative replacements, so this is the
    // last interception point. If the sheet is dirty and has not already been
    // approved, notify the observer so the dismiss event is auditable. We
    // cannot show the dirty dialog here — the element is already deactivating
    // — so this is an observability signal, not a veto.
    if (!_hasApproved && !_isDismissing && widget.isDirty) {
      widget.onRequestClose?.call(AppDismissReason.parentNavigation);
    }
    super.deactivate();
  }

  /// Called by [RouteAware] when another route is pushed on top of ours.
  ///
  /// STEP-55.0 RESIDUAL: this fires when a programmatic navigation replaces
  /// the current route (e.g. parent navigation while a form is open). If the
  /// sheet is dirty, request dismissal through the shared guard. The guard
  /// may show the dirty dialog because the sheet is still mounted at this
  /// point — the incoming route is being pushed, not yet displayed.
  @override
  void didPushNext() {
    if (widget.isDirty) {
      _requestDismiss(AppDismissReason.parentNavigation);
    }
  }

  Future<void> _requestDismiss(AppDismissReason reason) async {
    if (_isDismissing || !mounted) return;
    widget.onRequestClose?.call(reason);
    final decision = AppDismissController(
      isDirty: widget.isDirty,
      isBusy: widget.isBusy,
    ).requestDismiss(reason);
    switch (decision) {
      case AppDismissDecision.dismiss:
        _dismiss();
      case AppDismissDecision.confirmDiscard:
        if (_isConfirming || _isDismissing || !mounted) break;
        _isConfirming = true;
        try {
          // Defer to next turn so the navigator lock held during
          // onPopInvokedWithResult releases before pushing the dialog.
          await Future<void>.delayed(Duration.zero);
          if (!mounted || _isDismissing) break;
          final discard = await AppDirtyDismissDialog.show(context);
          if (discard && mounted) {
            widget.onDiscard?.call();
            _dismiss();
          }
        } finally {
          _isConfirming = false;
        }
      case AppDismissDecision.blockedBusy:
        final l10n = Localizations.of<AppLocalizations>(
          context,
          AppLocalizations,
        );
        unawaited(
          SemanticsService.sendAnnouncement(
            View.of(context),
            l10n?.processInProgress ?? 'Proses sedang berjalan',
            TextDirection.ltr,
          ),
        );
    }
  }

  /// Performs the one authorized route pop, after the navigator lock that
  /// `PopScope` held during the prevented pop has released.
  void _dismiss() {
    // STEP-55.11: dismissal is a one-shot transition. Once an approval has
    // been issued for this sheet instance, no further request may re-enter
    // the flow. In production the pop removes the sheet so later taps hit
    // nothing, but a host that declines to pop (or a widget harness) leaves
    // the sheet mounted and repeated requests must not fire again.
    if (_isDismissing || _hasApproved || !mounted) return;
    _isDismissing = true;
    WidgetsBinding.instance.scheduleFrame();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onDismissApproved();
        _hasApproved = true;
      }
      _isDismissing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 800;
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    // STEP-55.11 RESIDUAL: at extreme text scaling the pinned drag-handle +
    // header + footer chrome can exceed a fractionally-sized bottom sheet
    // (0.95 of a 640px viewport = 608px), overflowing the panel Column by a
    // few pixels. Give the sheet the full viewport height once text is scaled
    // past the large-text threshold so the chrome always fits; normal scales
    // keep the 0.85 partial-height bottom sheet.
    final mobileHeightFactor = textScale > 1.3 ? 1.0 : 0.85;

    final panel = CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          _requestDismiss(AppDismissReason.escape);
        },
      },
      child: FocusScope(
        node: _focusScopeNode,
        autofocus: true,
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          child: FocusTraversalGroup(
            child: Column(
              children: [
                // STEP-55.0 RESIDUAL: visible drag handle on the mobile
                // bottom sheet per D2. The handle receives vertical drag
                // gestures without conflicting with the scrollable body.
                if (!isWide && !widget.mobileFullPage)
                  _DragHandle(
                    isBusy: widget.isBusy,
                    onDragDismiss: () => _requestDismiss(AppDismissReason.drag),
                  ),
                _SheetHeader(
                  title: widget.title,
                  subtitle: widget.subtitle,
                  onClose: widget.isBusy
                      ? null
                      : () => _requestDismiss(AppDismissReason.closeButton),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    primary: true,
                    padding: const EdgeInsets.all(20),
                    child: widget.body,
                  ),
                ),
                if (widget.footer != null)
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _wrapSheetFooter(widget.footer!),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    return PopScope(
      canPop: false,
      // STEP-55.0 RESIDUAL: on web, the prevented pop is browser back/forward
      // navigation; on Android it is the system/predictive back gesture.
      onPopInvokedWithResult: (_, result) => _requestDismiss(
        kIsWeb
            ? AppDismissReason.browserNavigation
            : AppDismissReason.systemBack,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Semantics(
              label:
                  Localizations.of<AppLocalizations>(
                    context,
                    AppLocalizations,
                  )?.sheetBarrierLabel ??
                  'Tutup panel',
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.isBusy
                    ? null
                    : () => _requestDismiss(AppDismissReason.barrier),
                child: ColoredBox(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black.withValues(alpha: 0.60)
                      : Colors.black.withValues(alpha: 0.45),
                ),
              ),
            ),
          ),
          if (!isWide && widget.mobileFullPage)
            Positioned.fill(child: panel)
          else if (isWide)
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                key: ValueKey('app-responsive-sheet-${widget.routeIdentity}'),
                width: appResponsiveSheetWidth(
                  MediaQuery.sizeOf(context).width,
                ),
                height: double.infinity,
                child: panel,
              ),
            )
          else
            Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: mobileHeightFactor,
                widthFactor: 1,
                child: panel,
              ),
            ),
        ],
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
        AppAccessibleIconButton(
          tooltip:
              Localizations.of<AppLocalizations>(
                context,
                AppLocalizations,
              )?.sheetClose ??
              'Tutup',
          icon: Icons.close,
          onPressed: onClose,
        ),
      ],
    ),
  );
}

/// Visible drag handle for the mobile bottom sheet per D2.
///
/// STEP-55.0 RESIDUAL: receives vertical drag gestures and requests dismiss
/// when the user flings downward past 300 px/s or drags cumulatively past
/// 100dp. Busy state disables the gesture. The handle has an accessible
/// semantic label so screen readers can announce the drag affordance.
class _DragHandle extends StatefulWidget {
  const _DragHandle({required this.isBusy, required this.onDragDismiss});

  final bool isBusy;
  final VoidCallback onDragDismiss;

  @override
  State<_DragHandle> createState() => _DragHandleState();
}

class _DragHandleState extends State<_DragHandle> {
  double _dragAccumulator = 0;

  @override
  Widget build(BuildContext context) => Semantics(
    // Semantic label for the drag affordance, localized via sheetDragHandle
    // (STEP-55.0 RESIDUAL-2). Uses the same fallback pattern as
    // sheetBarrierLabel/sheetClose in this file; the fallback is
    // Indonesian-first, consistent with existing semantic fallbacks.
    label:
        Localizations.of<AppLocalizations>(
          context,
          AppLocalizations,
        )?.sheetDragHandle ??
        'Seret ke bawah untuk menutup',
    child: GestureDetector(
      key: const ValueKey('app-sheet-drag-handle'),
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: widget.isBusy
          ? null
          : (_) {
              _dragAccumulator = 0;
            },
      onVerticalDragUpdate: widget.isBusy
          ? null
          : (details) {
              _dragAccumulator += details.primaryDelta ?? 0;
            },
      onVerticalDragEnd: widget.isBusy
          ? null
          : (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity > 300 || _dragAccumulator > 100) {
                widget.onDragDismiss();
              }
              _dragAccumulator = 0;
            },
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    ),
  );
}

/// The non-dismissible confirmation required before discarding dirty changes.
class AppDirtyDismissDialog extends StatelessWidget {
  /// Creates the discard-changes dialog.
  const AppDirtyDismissDialog({super.key});

  /// Shows the dialog and returns true only after explicit discard confirmation.
  static Future<bool> show(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const AppDirtyDismissDialog(),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(l10n?.unsavedChangesTitle ?? 'Perubahan Belum Disimpan'),
        content: Text(
          l10n?.unsavedChangesBody ??
              'Anda memiliki perubahan yang belum disimpan. Yakin ingin membuangnya?',
        ),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n?.continueEditing ?? 'Lanjutkan Mengedit'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n?.discardChanges ?? 'Buang Perubahan'),
          ),
        ],
      ),
    );
  }
}

/// A named read-only adapter over [AppResponsiveSheet].
class AppDetailInspector extends StatelessWidget {
  /// Creates a route-backed read-only inspector.
  const AppDetailInspector({
    super.key,
    required this.routeIdentity,
    required this.title,
    required this.body,
    required this.onDismissApproved,
    this.mobileFullPage = false,
  });

  final String routeIdentity;
  final String title;
  final Widget body;
  final VoidCallback onDismissApproved;
  final bool mobileFullPage;

  @override
  Widget build(BuildContext context) => AppResponsiveSheet(
    routeIdentity: routeIdentity,
    title: title,
    mode: AppResponsiveSheetMode.readOnlyInspector,
    body: body,
    mobileFullPage: mobileFullPage,
    onDismissApproved: onDismissApproved,
  );
}

/// A labelled 48dp minimum-target icon action.
class AppAccessibleIconButton extends StatelessWidget {
  /// Creates an accessible icon button.
  const AppAccessibleIconButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: tooltip,
    child: SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        tooltip: tooltip,
        icon: Icon(icon),
        onPressed: onPressed,
      ),
    ),
  );
}

/// A compact semantic status label.
class AppStatusBadge extends StatelessWidget {
  /// Creates a semantic status badge.
  const AppStatusBadge({super.key, required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final statusText = l10n != null
        ? l10n.statusLabel(label)
        : 'Status: $label';
    return Semantics(
      label: statusText,
      child: Material(
        type: MaterialType.transparency,
        child: Chip(
          visualDensity: VisualDensity.compact,
          label: Text(label),
          backgroundColor: color?.withValues(alpha: .16),
        ),
      ),
    );
  }
}

/// An explicit offline/synchronization status badge.
class AppSyncStatusBadge extends AppStatusBadge {
  /// Creates a sync badge.
  const AppSyncStatusBadge({super.key, required super.label, super.color});
}

/// Shared loading, empty, error, offline, or permission state panel.
class AppStatePanel extends StatelessWidget {
  /// Creates a state panel with an optional recovery action.
  const AppStatePanel({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.info_outline,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    ),
  );
}

/// A labelled adaptive selection control.
class AppPlatformSelect<T> extends StatelessWidget {
  /// Creates a platform-neutral select control.
  const AppPlatformSelect({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) => InputDecorator(
    decoration: InputDecoration(labelText: label),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        items: items,
        onChanged: onChanged,
      ),
    ),
  );
}

/// One labelled filter menu with explicit apply/reset/cancel actions.
class AppFilterPopover extends StatelessWidget {
  /// Creates a filter popover body.
  const AppFilterPopover({
    super.key,
    required this.child,
    required this.onApply,
    required this.onReset,
    required this.onCancel,
  });

  final Widget child;
  final VoidCallback onApply;
  final VoidCallback onReset;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label:
        Localizations.of<AppLocalizations>(
          context,
          AppLocalizations,
        )?.filterLabel ??
        'Filter',
    child: Material(
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              child,
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton(onPressed: onCancel, child: const Text('Batal')),
                  TextButton(
                    onPressed: onReset,
                    child: const Text('Reset filter'),
                  ),
                  FilledButton(
                    onPressed: onApply,
                    child: const Text('Terapkan'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Opens a filter surface without changing the active route.
Future<T?> showAppFilterPopover<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) => showDialog<T>(context: context, builder: builder);

/// Opens one in-context date or date-range picker.
class AppCalendarDialog {
  AppCalendarDialog._();

  /// Shows a range calendar and returns only an explicitly applied value.
  static Future<DateTimeRange?> showRange(
    BuildContext context, {
    DateTimeRange? initialDateRange,
    required DateTime firstDate,
    required DateTime lastDate,
  }) => showDateRangePicker(
    context: context,
    initialDateRange: initialDateRange,
    firstDate: firstDate,
    lastDate: lastDate,
    helpText: 'Pilih rentang tanggal',
    cancelText: 'Batal',
    confirmText: 'Terapkan',
  );

  /// Shows a single-date calendar and returns only an explicitly applied value.
  static Future<DateTime?> showSingle(
    BuildContext context, {
    DateTime? initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) => showDatePicker(
    context: context,
    initialDate: initialDate ?? firstDate,
    firstDate: firstDate,
    lastDate: lastDate,
    helpText: 'Pilih tanggal',
    cancelText: 'Batal',
    confirmText: 'Terapkan',
  );
}
