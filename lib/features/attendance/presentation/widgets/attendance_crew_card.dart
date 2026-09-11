// Material: this file uses a Material primitive with no ForUI equivalent.
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_crew_draft.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_status.dart';
import 'package:mine_flow/features/attendance/presentation/bloc/attendance_form_state.dart';
import 'package:mine_flow/l10n/app_localizations.dart';

/// One crew member's inline attendance card (STEP-55.5, spec §4.4 items
/// 3–6).
///
/// - Real name is the primary label, position/role secondary; UUIDs never
///   appear in normal card copy (item 3).
/// - Four explicit inline choices — `Izin`, `Sakit`, `Alpa`, `Masuk` —
///   mapped to persisted `leave`, `sick`, `absent`, `present` (item 4).
///   These are record-editing controls, so the popover-first filter rule
///   does not apply to them.
/// - A required trimmed reason field appears only for Izin/Sakit (item 5).
/// - A compact sync indicator shows per-record queued/syncing/failed/synced
///   truth, separate from the attendance choice (item 6).
class AttendanceCrewCard extends StatelessWidget {
  final AttendanceCrewDraft draft;

  /// Per-record sync truth for this crew member, if any changed row exists.
  final AttendanceSyncState? syncState;

  /// Explicit per-record sync retry (only meaningful for failed state).
  final VoidCallback? onRetrySync;

  final TextEditingController reasonController;
  final FocusNode reasonFocusNode;

  final ValueChanged<AttendanceStatus> onStatusSelected;
  final void Function(String? remarks, {bool clear}) onRemarksChanged;

  const AttendanceCrewCard({
    super.key,
    required this.draft,
    required this.reasonController,
    required this.reasonFocusNode,
    required this.onStatusSelected,
    required this.onRemarksChanged,
    this.syncState,
    this.onRetrySync,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final showsReason = draft.requiresReason;

    return Semantics(
      container: true,
      label:
          l10n.attendanceCrewStatusLabel(
            draft.userName,
            draft.status == null
                ? l10n.attendanceStatusUnset
                : attendanceStatusLabel(l10n, draft.status!),
          ) +
          (syncState != null
              ? ', ${attendanceSyncLabel(l10n, syncState!)}'
              : ''),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: FCard(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            draft.userName,
                            style: theme.typography.body.sm.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colors.foreground,
                            ),
                          ),
                          if (draft.role != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              draft.role!,
                              style: theme.typography.body.xs.copyWith(
                                color: theme.colors.mutedForeground,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (syncState != null)
                      _AttendanceSyncIndicator(
                        state: syncState!,
                        onRetry: onRetrySync,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _AttendanceStatusChoices(
                  selected: draft.status,
                  enabled: true,
                  onSelected: onStatusSelected,
                ),
                if (showsReason) ...[
                  const SizedBox(height: 12),
                  _ReasonField(
                    controller: reasonController,
                    focusNode: reasonFocusNode,
                    label: draft.status == AttendanceStatus.sick
                        ? l10n.attendanceReasonSickLabel
                        : l10n.attendanceReasonLeaveLabel,
                    onChanged: (value) => onRemarksChanged(value),
                    onCleared: () => onRemarksChanged(null, clear: true),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The four inline attendance choices with icon+text, 48dp targets, and
/// selection conveyed by more than color (spec §4.4 item 4).
///
/// The choice order is fixed — `Izin`, `Sakit`, `Alpa`, `Masuk` — matching
/// the reviewed contract, and each maps to its persisted status.
class _AttendanceStatusChoices extends StatelessWidget {
  final AttendanceStatus? selected;
  final bool enabled;
  final ValueChanged<AttendanceStatus> onSelected;

  const _AttendanceStatusChoices({
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final l10n = AppLocalizations.of(context);

    final specs = <(AttendanceStatus, String, IconData)>[
      (
        AttendanceStatus.leave,
        l10n.attendanceStatusLeave,
        LucideIcons.calendarX,
      ),
      (AttendanceStatus.sick, l10n.attendanceStatusSick, LucideIcons.cross),
      (
        AttendanceStatus.absent,
        l10n.attendanceStatusAbsent,
        LucideIcons.xCircle,
      ),
      (
        AttendanceStatus.present,
        l10n.attendanceStatusPresent,
        LucideIcons.checkCircle,
      ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (status, label, icon) in specs)
          Semantics(
            button: true,
            selected: selected == status,
            label: l10n.attendanceStatusChooseLabel(label),
            child: GestureDetector(
              onTap: enabled ? () => onSelected(status) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutQuart,
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: selected == status
                      ? theme.colors.primary.withValues(alpha: 0.12)
                      : const Color(0x00000000),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected == status
                        ? theme.colors.primary
                        : theme.colors.border,
                    width: selected == status ? 2.0 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: selected == status
                          ? theme.colors.primary
                          : theme.colors.mutedForeground,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: theme.typography.body.sm.copyWith(
                        fontWeight: selected == status
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: selected == status
                            ? theme.colors.primary
                            : theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Required, trimmed reason field for Izin/Sakit rows (spec §4.4 item 5).
///
/// The controller is owned by the sheet state (one per crew member), seeded
/// from the draft's persisted remarks on first build, so a cold-reconstructed
/// sheet shows what was saved. Clearing is an explicit intent dispatched
/// through [onCleared] — never a silent text wipe.
class _ReasonField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final ValueChanged<String> onChanged;
  final VoidCallback onCleared;

  const _ReasonField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.onChanged,
    required this.onCleared,
  });

  @override
  State<_ReasonField> createState() => _ReasonFieldState();
}

class _ReasonFieldState extends State<_ReasonField> {
  @override
  void didUpdateWidget(covariant _ReasonField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Label switches between 'Alasan izin' and 'Alasan sakit' when the user
    // flips Izin↔Sakit; the typed text intentionally survives that flip so
    // the reason does not have to be retyped for the sibling status.
    if (oldWidget.label != widget.label) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasText = widget.controller.text.trim().isNotEmpty;

    return TextField(
      key: const Key('attendance_reason_field'),
      controller: widget.controller,
      focusNode: widget.focusNode,
      minLines: 1,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: l10n.attendanceReasonRequiredLabel(widget.label),
        hintText: l10n.attendanceReasonHint(widget.label.toLowerCase()),
        suffixIcon: hasText
            ? IconButton(
                key: const Key('attendance_reason_clear'),
                icon: const Icon(LucideIcons.x, size: 18),
                tooltip: l10n.attendanceReasonClearTooltip,
                onPressed: () {
                  widget.controller.clear();
                  widget.onCleared();
                },
              )
            : null,
      ),
      onChanged: widget.onChanged,
    );
  }
}

/// Compact queued/syncing/failed/synced indicator, separate from the
/// attendance choice (spec §4.4 item 6 / FC-54.5-007).
class _AttendanceSyncIndicator extends StatelessWidget {
  final AttendanceSyncState state;
  final VoidCallback? onRetry;

  const _AttendanceSyncIndicator({required this.state, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final l10n = AppLocalizations.of(context);

    final (icon, label, color) = switch (state) {
      AttendanceSyncState.queued => (
        LucideIcons.cloudUpload,
        l10n.attendanceSyncQueued,
        theme.colors.mutedForeground,
      ),
      AttendanceSyncState.syncing => (
        LucideIcons.loader,
        l10n.attendanceSyncSyncing,
        theme.colors.primary,
      ),
      AttendanceSyncState.failed => (
        LucideIcons.cloudOff,
        l10n.attendanceSyncFailed,
        theme.colors.destructive,
      ),
      AttendanceSyncState.synced => (
        LucideIcons.cloudCheck,
        l10n.attendanceSyncSynced,
        theme.colors.primary,
      ),
    };

    return Semantics(
      label: l10n.attendanceSyncStatusLabel(label),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: theme.typography.body.xs.copyWith(color: color)),
          if (state == AttendanceSyncState.failed && onRetry != null) ...[
            const SizedBox(width: 4),
            Semantics(
              button: true,
              label: l10n.attendanceSyncRetryLabel,
              child: GestureDetector(
                onTap: onRetry,
                child: Text(
                  l10n.attendanceSyncRetry,
                  style: theme.typography.body.xs.copyWith(
                    color: theme.colors.primary,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Master spec §4.4 item 4 label mapping: present → `Masuk`, absent →
/// `Alpa`, sick → `Sakit`, leave → `Izin`.
String attendanceStatusLabel(AppLocalizations l10n, AttendanceStatus status) {
  switch (status) {
    case AttendanceStatus.present:
      return l10n.attendanceStatusPresent;
    case AttendanceStatus.absent:
      return l10n.attendanceStatusAbsent;
    case AttendanceStatus.sick:
      return l10n.attendanceStatusSick;
    case AttendanceStatus.leave:
      return l10n.attendanceStatusLeave;
  }
}

/// Short, screen-reader sync phrase used inside a card's accessible label.
String attendanceSyncLabel(AppLocalizations l10n, AttendanceSyncState state) {
  switch (state) {
    case AttendanceSyncState.queued:
      return l10n.attendanceSyncQueued;
    case AttendanceSyncState.syncing:
      return l10n.attendanceSyncSyncing;
    case AttendanceSyncState.failed:
      return l10n.attendanceSyncFailed;
    case AttendanceSyncState.synced:
      return l10n.attendanceSyncSynced;
  }
}
