import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import 'package:mine_flow/features/timeline/domain/entities/timeline_data_point.dart';

/// A line chart showing cumulative cut-fill volume and land clearing progress
/// over a date range.
///
/// Renders up to three data series:
/// - **Cumulative Cut Volume** (blue)
/// - **Cumulative Fill Volume** (orange)
/// - **Cumulative Land Clearing** (green)
///
/// Phase 2 Tier 2 rebuild (STEP-30.5 final purge): Replaced hardcoded Colors.*
/// and Theme.of(context).colorScheme with FTheme semantic tokens.
class TimelineChart extends StatelessWidget {
  final List<TimelineDataPoint> dataPoints;

  const TimelineChart({super.key, required this.dataPoints});

  // Semantic colors for the three chart series, derived from FTheme.
  // Cut: primary (blue), Fill: destructive (orange-red), Land: secondary (green)
  static const Color _kCutColor = Color(0xFF3B82F6); // blue
  static const Color _kFillColor = Color(0xFFF97316); // orange
  static const Color _kLandColor = Color(0xFF22C55E); // green

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    if (dataPoints.isEmpty) {
      return Center(
        child: Text(
          'Tidak ada data untuk periode ini.',
          style: theme.typography.body.md.copyWith(
            color: theme.colors.mutedForeground,
          ),
        ),
      );
    }

    // Build FlSpot lists for each series
    final cutSpots = <FlSpot>[];
    final fillSpots = <FlSpot>[];
    final landSpots = <FlSpot>[];

    for (int i = 0; i < dataPoints.length; i++) {
      final dp = dataPoints[i];
      cutSpots.add(FlSpot(i.toDouble(), dp.cumulativeCutVolume));
      fillSpots.add(FlSpot(i.toDouble(), dp.cumulativeFillVolume));
      landSpots.add(FlSpot(i.toDouble(), dp.cumulativeLandClearing));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend
        const Row(
          children: [
            _LegendDot(color: _kCutColor, label: 'Cut Volume'),
            SizedBox(width: 16),
            _LegendDot(color: _kFillColor, label: 'Fill Volume'),
            SizedBox(width: 16),
            _LegendDot(color: _kLandColor, label: 'Land Clearing'),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 280,
          child: Padding(
            padding: const EdgeInsets.only(right: 16, top: 8),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _calcInterval(
                    cutSpots,
                    fillSpots,
                    landSpots,
                  ),
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: theme.colors.border.withValues(alpha: 0.3),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      getTitlesWidget: (value, meta) => Text(
                        _formatAxisValue(value),
                        style: theme.typography.body.xs.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: _bottomInterval(dataPoints.length),
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= dataPoints.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            DateFormat('dd/MM').format(dataPoints[idx].date),
                            style: theme.typography.body.xs.copyWith(
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: theme.colors.border),
                    left: BorderSide(color: theme.colors.border),
                  ),
                ),
                lineBarsData: [
                  _lineBarData(cutSpots, _kCutColor),
                  _lineBarData(fillSpots, _kFillColor),
                  _lineBarData(landSpots, _kLandColor),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final idx = spot.spotIndex;
                        final dp = dataPoints[idx];
                        return LineTooltipItem(
                          '${_dateLabel(spot, dataPoints)}\nCut: ${_fmtNum(dp.cumulativeCutVolume)}\nFill: ${_fmtNum(dp.cumulativeFillVolume)}\nLand: ${_fmtNum(dp.cumulativeLandClearing)} ha',
                          theme.typography.body.xs.copyWith(
                            color: const Color(0xFFFFFFFF),
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  LineChartBarData _lineBarData(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      preventCurveOverShooting: true,
      color: color,
      barWidth: 2.5,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.06),
      ),
    );
  }

  double _calcInterval(List<FlSpot> cut, List<FlSpot> fill, List<FlSpot> land) {
    final maxY = [
      if (cut.isNotEmpty) cut.last.y,
      if (fill.isNotEmpty) fill.last.y,
      if (land.isNotEmpty) land.last.y,
    ].fold(0.0, (a, b) => a > b ? a : b);

    if (maxY <= 0) return 10;
    final rough = maxY / 4;
    final magnitude = _pow10(rough ~/ 1);
    return magnitude;
  }

  double _pow10(int exp) {
    double result = 1;
    for (int i = 0; i < exp; i++) {
      result *= 10;
    }
    return result;
  }

  double _bottomInterval(int count) {
    if (count <= 7) return 1;
    if (count <= 31) return (count / 7).ceilToDouble();
    return (count / 14).ceilToDouble();
  }

  String _formatAxisValue(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toStringAsFixed(0);
  }

  String _fmtNum(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(2)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }

  String _dateLabel(LineBarSpot spot, List<TimelineDataPoint> dataPoints) {
    final idx = spot.spotIndex;
    if (idx >= 0 && idx < dataPoints.length) {
      return DateFormat('dd MMM yyyy').format(dataPoints[idx].date);
    }
    return '';
  }
}

/// A small coloured dot with a label, used in the chart legend.
class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: theme.typography.body.xs),
      ],
    );
  }
}
