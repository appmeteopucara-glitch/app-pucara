import 'package:flutter/material.dart';
import 'package:pronosticosapp/core/theme/pucara_ui.dart';
import 'package:pronosticosapp/features/weather/domain/entities/forecast_day.dart';
import 'package:pronosticosapp/features/weather/presentation/widgets/forecast_detail/utils/forecast_utils.dart';

class DetailItemWidget extends StatelessWidget {
  final String title;
  final String value;
  final String type;
  final ForecastDay forecast;
  final Function(String, ForecastDay) onViewChart;
  final bool hasChart;

  const DetailItemWidget({
    super.key,
    required this.title,
    required this.value,
    required this.type,
    required this.forecast,
    required this.onViewChart,
    this.hasChart = true,
  });

  @override
  Widget build(BuildContext context) {
    final accent = ForecastUtils.getColorByType(type);
    return PucaraPanel(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      borderRadius: 20,
      padding: const EdgeInsets.all(16.0),
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: PucaraColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: ForecastUtils.getWeatherIconByType(type, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: accent,
                height: 1.35,
              ),
            ),
            if (hasChart) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: accent,
                side: BorderSide(color: accent.withValues(alpha: 0.35)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => onViewChart(type, forecast),
              icon: const Icon(Icons.show_chart, size: 16),
              label: const Text('Ver gráfico'),
            ),
            ],
          ],
          ),
        ),
      );
    
  }
}
