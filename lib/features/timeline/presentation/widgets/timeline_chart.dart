import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mine_flow/features/timeline/domain/entities/timeline_data_point.dart';

/// A line chart showing cumulative cut-fill volume and land clearing progress
/// over a date range.
///
/// Renders up to three data series:
/// - **Cumulative Cut Volume** (blue)
/// - **Cumulative Fill Volume** (orange)
/// - **Cumulative Land Clearing** (green)
class TimelineChart extends StatelessWidget {
  final List<TimelineDataPoint> dataPoints;

  const TimelineChart({super.key, required this.dataPoints});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (dataPoints.isEmpty) {
      return Center(
        child: Text(
          'Tidak ada data untuk periode ini.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
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
        Row(
          children: [
            const _LegendDot(color: Colors.blue, label: 'Cut Volume'),
            const SizedBox(width: 16),
            const _LegendDot(color: Colors.orange, label: 'Fill Volume'),
            const SizedBox(width: 16),
            _LegendDot(color: Theme.of(context).colorScheme.primary, label: 'Land Clearing'),
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
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
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
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 10,
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
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 9,
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
                    bottom: BorderSide(color: theme.colorScheme.outlineVariant),
                    left: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                ),
                lineBarsData: [
                  _lineBarData(cutSpots, Colors.blue),
                  _lineBarData(fillSpots, Colors.orange),
                  _lineBarData(landSpots, Theme.of(context).colorScheme.primary),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final idx = spot.spotIndex;
                        final dp = dataPoints[idx];
                        return LineTooltipItem(
                          '${_dateLabel(spot, dataPoints)}\nCut: ${_fmtNum(dp.cumulativeCutVolume)}\nFill: ${_fmtNum(dp.cumulativeFillVolume)}\nLand: ${_fmtNum(dp.cumulativeLandClearing)} ha',
                          TextStyle(
                            color: spot.bar.color ?? Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
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
      belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.06)),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
