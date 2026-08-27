import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:mine_flow/core/domain/entities/zone_entity.dart';
import 'package:mine_flow/features/zone/presentation/bloc/zone_cubit.dart';

/// A compact zone filter dropdown backed by [ZoneCubit].
///
/// CF-016: replaces the hardcoded 'Zona A' chip with a dropdown of real zones,
/// so the filter always carries an actual zone id (or null for "all zones").
class ZoneFilterDropdown extends StatelessWidget {
  final String? selectedZoneId;
  final ValueChanged<String?> onZoneSelected;

  const ZoneFilterDropdown({
    super.key,
    required this.selectedZoneId,
    required this.onZoneSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    // Guard against a missing ZoneCubit (e.g. zoneRepository resolved null).
    try {
      context.read<ZoneCubit>();
    } on ProviderNotFoundException {
      return const SizedBox.shrink();
    }

    return BlocBuilder<ZoneCubit, ZoneState>(
      builder: (context, state) {
        final zones = state is ZoneLoaded ? state.zones : <ZoneEntity>[];
        final isSelected = zones.any((z) => z.id == selectedZoneId);

        return DropdownButton<String?>(
          value: isSelected ? selectedZoneId : null,
          hint: Text(
            'Zona',
            style: theme.typography.body.sm.copyWith(
              color: theme.colors.foreground,
            ),
          ),
          underline: const SizedBox.shrink(),
          borderRadius: BorderRadius.circular(8),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(
                'Semua Zona',
                style: theme.typography.body.sm,
              ),
            ),
            ...zones.map(
              (z) => DropdownMenuItem<String?>(
                value: z.id,
                child: Text(z.name, style: theme.typography.body.sm),
              ),
            ),
          ],
          onChanged: onZoneSelected,
        );
      },
    );
  }
}
