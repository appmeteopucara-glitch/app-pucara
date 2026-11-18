import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pronosticosapp/features/weather/presentation/widgets/forecast_detail/charts/base_chart_widget.dart';

class TemperatureChart extends BaseChartWidget {
  const TemperatureChart({
    super.key,
    required super.forecast,
    super.isHorizontalView,
  });

  @override
  List<String> get labels => [
    if (forecast.min != null) 'Mín.',
    if (forecast.max != null) 'Máx.',
  ];

  @override
  Widget buildChart(BuildContext context) {
    final values = [
      if (forecast.min != null) forecast.min!,
      if (forecast.max != null) forecast.max!,
    ];
    if (values.isEmpty) return const SizedBox.shrink();
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final minY = _roundDownToStep((minValue < 0 ? minValue : 0) - 2);
    final maxY = _roundUpToStep((maxValue > 0 ? maxValue : 0) + 2);
    final interval = _axisInterval(minY, maxY);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(show: true),
        minY: minY,
        maxY: maxY,
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: 0,
              color: Colors.white24,
              strokeWidth: 1.2,
              dashArray: const [6, 4],
            ),
          ],
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: buildBottomTitle,
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: interval,
              reservedSize: 34,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}°',
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
              '${labels[group.x.toInt()]}: ${rod.toY.toStringAsFixed(1)}°',
              const TextStyle(color: Colors.white),
            ),
          ),
        ),
        barGroups: List.generate(values.length, (index) {
          final color = labels[index] == 'Mín.' ? Colors.blue : Colors.red;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: values[index],
                color: color,
                width: 28,
                borderRadius: values[index] >= 0
                    ? const BorderRadius.vertical(top: Radius.circular(8))
                    : const BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
            ],
          );
        }),
      ),
    );
  }

  double _roundDownToStep(double value, {double step = 5}) {
    return (value / step).floor() * step;
  }

  double _roundUpToStep(double value, {double step = 5}) {
    return (value / step).ceil() * step;
  }

  double _axisInterval(double minY, double maxY) {
    final range = (maxY - minY).abs();
    if (range <= 20) return 5;
    if (range <= 50) return 10;
    return 20;
  }
}
