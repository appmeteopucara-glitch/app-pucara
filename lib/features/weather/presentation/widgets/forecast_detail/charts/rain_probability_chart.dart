import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pronosticosapp/features/weather/presentation/widgets/forecast_detail/charts/base_chart_widget.dart';

class RainProbabilityChart extends BaseChartWidget {
  const RainProbabilityChart({
    super.key,
    required super.forecast,
    super.isHorizontalView,
  });

  @override
  Widget buildChart(BuildContext context) {
    final value = (forecast.precipProb ?? 0).toDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.center,
        gridData: FlGridData(show: true),
        minY: 0,
        maxY: 100,
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: value,
              color: Colors.lightBlueAccent.withValues(alpha: 0.55),
              strokeWidth: 1.2,
              dashArray: const [6, 4],
            ),
          ],
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() != 0) return const SizedBox.shrink();
                return const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Configurado',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                );
              },
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
              'Configurado: ${rod.toY.toInt()}%',
              const TextStyle(color: Colors.white),
            ),
          ),
        ),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: value,
                color: Colors.lightBlue,
                width: 38,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
