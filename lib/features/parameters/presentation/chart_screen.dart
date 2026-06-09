import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../health/data/health_repository.dart';
import '../../health/domain/health_log.dart';
import '../data/parameter_repository.dart';
import '../domain/parameter_reading.dart';
import '../domain/parameter_type.dart';

class ChartScreen extends ConsumerStatefulWidget {
  const ChartScreen({super.key, required this.tankId});
  final String tankId;

  @override
  ConsumerState<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends ConsumerState<ChartScreen> {
  ParameterType? _selected;
  int _days = 90;
  bool _showHealth = true;

  @override
  Widget build(BuildContext context) {
    final typesAsync = ref.watch(tankParameterTypesProvider(widget.tankId));
    return Scaffold(
      appBar: AppBar(title: const Text('Trends')),
      body: typesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (types) {
          _selected ??= types.first;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final t in types)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(t.label),
                            selected: _selected?.key == t.key,
                            onSelected: (_) => setState(() => _selected = t),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              _RangeSelector(
                days: _days,
                onChanged: (d) => setState(() => _days = d),
              ),
              _HealthLegend(
                type: _selected!,
                showHealth: _showHealth,
                onToggle: (v) => setState(() => _showHealth = v),
              ),
              const Divider(height: 1),
              Expanded(
                child: _ChartBody(
                  tankId: widget.tankId,
                  type: _selected!,
                  days: _days,
                  showHealth: _showHealth,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({required this.days, required this.onChanged});
  final int days;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) {
    const options = {'1M': 30, '3M': 90, '6M': 180, '1Y': 365, 'All': 100000};
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final entry in options.entries)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(entry.key),
                selected: days == entry.value,
                onSelected: (_) => onChanged(entry.value),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChartBody extends ConsumerWidget {
  const _ChartBody({
    required this.tankId,
    required this.type,
    required this.days,
    required this.showHealth,
  });
  final String tankId;
  final ParameterType type;
  final int days;
  final bool showHealth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref
        .watch(readingsProvider((tankId: tankId, parameterKey: type.key)));
    final healthAsync = ref.watch(healthLogsProvider(tankId));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (all) {
        final cutoff = DateTime.now().subtract(Duration(days: days));
        final readings = all
            .where((r) => r.measuredAt.isAfter(cutoff))
            .toList()
          ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

        if (readings.length < 2) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                readings.isEmpty
                    ? 'No ${type.label} readings in this range.\nLog at least two to see a trend.'
                    : 'Only one ${type.label} reading so far.\nLog another to draw a line.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final health = <HealthLog>[];
        if (showHealth) {
          health
            ..addAll((healthAsync.asData?.value ?? const <HealthLog>[])
                .where((h) => h.observedAt.isAfter(cutoff)))
            ..sort((a, b) => a.observedAt.compareTo(b.observedAt));
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 24, 8, 12),
          child: _LineChart(type: type, readings: readings, health: health),
        );
      },
    );
  }
}

/// Health ratings run 1–10; we map them onto the parameter's Y range so both
/// series share one plot, with a 0–10 scale drawn on the right axis.
const double _healthScaleMax = 10;

class _LineChart extends StatelessWidget {
  const _LineChart({
    required this.type,
    required this.readings,
    required this.health,
  });
  final ParameterType type;
  final List<ParameterReading> readings;
  final List<HealthLog> health;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final healthColor = scheme.tertiary;
    final spots = readings
        .map((r) => FlSpot(
            r.measuredAt.millisecondsSinceEpoch.toDouble(), r.value))
        .toList();

    final values = readings.map((r) => r.value).toList();
    var minY = values.reduce((a, b) => a < b ? a : b);
    var maxY = values.reduce((a, b) => a > b ? a : b);
    if (type.idealMin != null) minY = minY < type.idealMin! ? minY : type.idealMin!;
    if (type.idealMax != null) maxY = maxY > type.idealMax! ? maxY : type.idealMax!;
    final pad = (maxY - minY).abs() * 0.15 + (maxY == minY ? 1 : 0);
    minY -= pad;
    maxY += pad;

    // Project a 1–10 health rating into the chart's Y space.
    double healthToY(num rating) =>
        minY + (rating / _healthScaleMax) * (maxY - minY);
    // Invert, for reading a plotted Y value back as a rating in tooltips.
    double yToHealth(double y) =>
        (y - minY) / (maxY - minY) * _healthScaleMax;

    final healthSpots = health
        .map((h) => FlSpot(
            h.observedAt.millisecondsSinceEpoch.toDouble(),
            healthToY(h.rating)))
        .toList();

    // X bounds span both series so health points outside the reading window
    // still show.
    var firstMs = readings.first.measuredAt.millisecondsSinceEpoch.toDouble();
    var lastMs = readings.last.measuredAt.millisecondsSinceEpoch.toDouble();
    for (final s in healthSpots) {
      if (s.x < firstMs) firstMs = s.x;
      if (s.x > lastMs) lastMs = s.x;
    }

    return LineChart(
      LineChartData(
        minX: firstMs,
        maxX: lastMs,
        minY: minY,
        maxY: maxY,
        // Shade the ideal reef range.
        rangeAnnotations: RangeAnnotations(
          horizontalRangeAnnotations: [
            if (type.idealMin != null && type.idealMax != null)
              HorizontalRangeAnnotation(
                y1: type.idealMin!,
                y2: type.idealMax!,
                color: scheme.primary.withValues(alpha: 0.10),
              ),
          ],
        ),
        gridData: FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(
            axisNameWidget: healthSpots.isEmpty
                ? null
                : Text('Health',
                    style: TextStyle(fontSize: 10, color: healthColor)),
            axisNameSize: 16,
            sideTitles: SideTitles(
              showTitles: healthSpots.isNotEmpty,
              reservedSize: 28,
              interval: (maxY - minY) / 2,
              getTitlesWidget: (v, meta) => Text(
                yToHealth(v).clamp(0, _healthScaleMax).round().toString(),
                style: TextStyle(fontSize: 10, color: healthColor),
              ),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (v, meta) => Text(
                v.toStringAsFixed(type.decimals == 0 ? 0 : 1),
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: ((lastMs - firstMs) / 4).clamp(1, double.infinity),
              getTitlesWidget: (v, meta) {
                final d = DateTime.fromMillisecondsSinceEpoch(v.toInt());
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(DateFormat('M/d').format(d),
                      style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (items) => items.map((s) {
              final date = DateFormat('MMM d').format(
                  DateTime.fromMillisecondsSinceEpoch(s.x.toInt()));
              // barIndex 1 is the health overlay (added second below).
              final isHealth = s.barIndex == 1;
              final text = isHealth
                  ? 'Health ${yToHealth(s.y).round()}/10\n$date'
                  : '${s.y.toStringAsFixed(type.decimals)} ${type.unit}\n$date';
              return LineTooltipItem(
                text,
                TextStyle(
                  color: isHealth ? healthColor : scheme.onInverseSurface,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.2,
            barWidth: 3,
            color: scheme.primary,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, __, ___) {
                final ok = type.inRange(spot.y);
                return FlDotCirclePainter(
                  radius: 3,
                  color: ok ? scheme.primary : scheme.error,
                  strokeWidth: 0,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: scheme.primary.withValues(alpha: 0.08),
            ),
          ),
          if (healthSpots.isNotEmpty)
            LineChartBarData(
              spots: healthSpots,
              isCurved: true,
              curveSmoothness: 0.2,
              barWidth: 2,
              color: healthColor,
              dashArray: const [6, 4],
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                  radius: 2.5,
                  color: healthColor,
                  strokeWidth: 0,
                ),
              ),
              belowBarData: BarAreaData(show: false),
            ),
        ],
      ),
    );
  }
}

/// Legend above the chart with a switch to overlay the tank's health rating.
class _HealthLegend extends StatelessWidget {
  const _HealthLegend({
    required this.type,
    required this.showHealth,
    required this.onToggle,
  });
  final ParameterType type;
  final bool showHealth;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      child: Row(
        children: [
          _LegendDot(color: scheme.primary),
          const SizedBox(width: 6),
          Text(type.label, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 16),
          _LegendDot(color: scheme.tertiary, dashed: true),
          const SizedBox(width: 6),
          const Text('Health', style: TextStyle(fontSize: 12)),
          const Spacer(),
          Switch(value: showHealth, onChanged: onToggle),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, this.dashed = false});
  final Color color;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 3,
      decoration: BoxDecoration(
        color: dashed ? null : color,
        border: dashed ? Border.all(color: color, width: 1.5) : null,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
