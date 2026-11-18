import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pronosticosapp/features/weather/presentation/widgets/forecast_detail/charts/base_chart_widget.dart';

class IsothermChart extends BaseChartWidget {
  const IsothermChart({
    super.key,
    required super.forecast,
    super.isHorizontalView,
  });

  @override
  Widget buildChart(BuildContext context) {
    final isoMin = forecast.isoMin;
    final isoMax = forecast.isoMax;
    if (isoMin == null && isoMax == null) return const SizedBox.shrink();
    final values = <double>[
      if (isoMin != null) isoMin.toDouble(),
      if (isoMax != null) isoMax.toDouble(),
    ];
    final labels = [
      if (isoMin != null) 'Mín.',
      if (isoMax != null) 'Máx.',
    ];
    final lowest = values.reduce((a, b) => a < b ? a : b);
    final highest = values.reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(show: true),
        minY: lowest - 200 < 0 ? 0 : lowest - 200,
        maxY: highest + 200,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= labels.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    labels[index],
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}',
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
              '${labels[group.x.toInt()]}: ${rod.toY.toInt()} msnm',
              const TextStyle(color: Colors.white),
            ),
          ),
        ),
        barGroups: List.generate(values.length, (index) {
          final color = labels[index] == 'Mín.' ? Colors.deepPurpleAccent : Colors.deepPurple;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: values[index],
                color: color,
                width: 30,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ],
          );
        }),
      ),
    );
  }
}
