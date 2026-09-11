/// Shared route-backed modal, filter, calendar, and accessible-state primitives.
///
/// These widgets own interaction and accessibility mechanics only. Feature
/// routes remain the owners of durable identity, loading, and persistence.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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

class _AppResponsiveSheetState extends State<AppResponsiveSheet> {
  Future<void> _requestDismiss(AppDismissReason reason) async {
    widget.onRequestClose?.call(reason);
    final decision = AppDismissController(
      isDirty: widget.isDirty,
      isBusy: widget.isBusy,
    ).requestDismiss(reason);
    switch (decision) {
      case AppDismissDecision.dismiss:
        widget.onDismissApproved();
      case AppDismissDecision.confirmDiscard:
        final discard = await AppDirtyDismissDialog.show(context);
        if (discard && mounted) {
          widget.onDiscard?.call();
          widget.onDismissApproved();
        }
      case AppDismissDecision.blockedBusy:
        unawaited(
          SemanticsService.sendAnnouncement(
            View.of(context),
            AppLocalizations.of(context).processInProgress,
            TextDirection.ltr,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 800;
    final panel = Material(
      color: Theme.of(context).colorScheme.surface,
      child: FocusTraversalGroup(
        child: Column(
          children: [
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
                  child: widget.footer!,
                ),
              ),
          ],
        ),
      ),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, result) =>
          _requestDismiss(AppDismissReason.systemBack),
      child: Stack(
        children: [
          Positioned.fill(
            child: Semantics(
              label: AppLocalizations.of(context).sheetBarrierLabel,
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
                heightFactor: .85,
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
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ],
          ),
        ),
        AppAccessibleIconButton(
          tooltip: AppLocalizations.of(context).sheetClose,
          icon: Icons.close,
          onPressed: onClose,
        ),
      ],
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
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: AlertDialog(
      title: Text(AppLocalizations.of(context).unsavedChangesTitle),
      content: Text(AppLocalizations.of(context).unsavedChangesBody),
      actions: [
        TextButton(
          autofocus: true,
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(AppLocalizations.of(context).continueEditing),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(AppLocalizations.of(context).discardChanges),
        ),
      ],
    ),
  );
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
  Widget build(BuildContext context) => Semantics(
    label: AppLocalizations.of(context).statusLabel(label),
    child: Chip(
      visualDensity: VisualDensity.compact,
      label: Text(label),
      backgroundColor: color?.withValues(alpha: .16),
    ),
  );
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
    label: AppLocalizations.of(context).filterLabel,
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
