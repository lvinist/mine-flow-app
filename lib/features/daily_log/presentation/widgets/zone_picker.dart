import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:mine_flow/core/domain/entities/zone_entity.dart';
import 'package:mine_flow/core/presentation/widgets/creatable_combobox.dart';
import 'package:mine_flow/features/zone/presentation/bloc/zone_cubit.dart';

/// Combobox picker for selecting or creating operational mine zones.
///
/// Uses [CreatableCombobox] for the UI and [ZoneCubit] for state management.
/// Existing zones are loaded from the local repository on init, and newly
/// created zones are persisted offline-first via [ZoneCubit.createZone].
class ZonePicker extends StatelessWidget {
  final String? selectedZoneId;
  final ValueChanged<String?> onZoneSelected;
  final String siteId;

  const ZonePicker({
    super.key,
    required this.selectedZoneId,
    required this.onZoneSelected,
    this.siteId = '',
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    // Guard against missing ZoneCubit in the widget tree — e.g. when
    // zoneRepository resolves to null and BlocProvider is skipped.
    try {
      context.read<ZoneCubit>();
    } on ProviderNotFoundException {
      return _buildMissingCubitFallback(theme);
    }

    return BlocBuilder<ZoneCubit, ZoneState>(
      builder: (context, state) {
        if (state is ZoneLoading) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Zona Operasional',
                style: theme.typography.body.sm.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colors.foreground,
                ),
              ),
              const SizedBox(height: 8),
              const SizedBox(
                height: 40,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ],
          );
        }

        if (state is ZoneError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Zona Operasional',
                style: theme.typography.body.sm.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colors.destructive,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colors.destructive.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 16,
                      color: theme.colors.destructive,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.message,
                        style: theme.typography.body.sm.copyWith(
                          color: theme.colors.destructive,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        final zones = state is ZoneLoaded ? state.zones : <ZoneEntity>[];
        final selectedZone = zones
            .where((z) => z.id == selectedZoneId)
            .firstOrNull;

        return CreatableCombobox<ZoneEntity>(
          items: zones,
          labelBuilder: (zone) => zone.name,
          label: 'Zona Operasional',
          hint: 'Pilih Zona Operasional...',
          prefix: const Icon(Icons.location_on_outlined, size: 20),
          selectedItem: selectedZone,
          initialValue: selectedZone != null ? selectedZone.name : '',
          onChanged: (zone) => onZoneSelected(zone.id),
          onCreateNew: (name) => _handleCreateZone(context, name),
        );
      },
    );
  }

  /// Renders a disabled fallback when no [ZoneCubit] is available in the
  /// widget tree, preventing a [ProviderNotFoundException] crash.
  Widget _buildMissingCubitFallback(FThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Zona Operasional',
          style: theme.typography.body.sm.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colors.mutedForeground,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colors.mutedForeground.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 16,
                color: theme.colors.mutedForeground,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Zona tidak tersedia',
                  style: theme.typography.body.sm.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Creates a new zone via [ZoneCubit] and selects it.
  void _handleCreateZone(BuildContext context, String name) {
    final cubit = context.read<ZoneCubit>();
    cubit.createZone(name: name).then((newZone) {
      if (newZone != null && context.mounted) {
        onZoneSelected(newZone.id);
      }
    });
  }
}
