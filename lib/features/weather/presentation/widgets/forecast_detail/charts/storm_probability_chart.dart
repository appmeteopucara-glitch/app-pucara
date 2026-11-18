import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pronosticosapp/features/weather/presentation/widgets/forecast_detail/charts/base_chart_widget.dart';

class StormProbabilityChart extends BaseChartWidget {
  const StormProbabilityChart({
    super.key,
    required super.forecast,
    super.isHorizontalView,
  });

  @override
  List<String> get labels => const ['Eléctrica', 'Ref.'];

  @override
  Widget buildChart(BuildContext context) {
    final value = (forecast.electricProb ?? 0).toDouble();
    final values = [value, 100.0];

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(show: true),
        minY: 0,
        maxY: 100,
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
              reservedSize: 34,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}%',
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
              '${labels[group.x.toInt()]}: ${rod.toY.toInt()}%',
              const TextStyle(color: Colors.white),
            ),
          ),
        ),
        barGroups: List.generate(values.length, (index) {
          final color = index == 0 ? Colors.purple : Colors.white24;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: values[index],
                color: color,
                width: 28,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ],
          );
        }),
      ),
    );
  }
}
