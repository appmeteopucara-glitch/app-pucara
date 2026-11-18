import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pronosticosapp/features/weather/domain/entities/forecast_day.dart';

abstract class BaseChartWidget extends StatelessWidget {
  final ForecastDay forecast;
  final bool isHorizontalView;

  const BaseChartWidget({
    super.key,
    required this.forecast,
    this.isHorizontalView = false,
  });

  @override
  Widget build(BuildContext context) {
    return isHorizontalView
        ? RotatedBox(
            quarterTurns: 1,
            child: buildChart(context),
          )
        : buildChart(context);
  }

  Widget buildChart(BuildContext context);

  @protected
  List<String> get labels => const ['Config.', 'Referencia'];

  @protected
  double paddedMin(Iterable<double> values, {double padding = 5}) {
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final candidate = minValue - padding;
    return candidate < 0 ? 0 : candidate;
  }

  @protected
  double paddedMax(Iterable<double> values, {double padding = 5}) {
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    return maxValue + padding;
  }

  @protected
  Widget buildBottomTitle(double value, TitleMeta meta) {
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
  }
}
