import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pronosticosapp/core/theme/pucara_ui.dart';
import 'package:pronosticosapp/core/utils/forecast_format.dart';
import 'package:pronosticosapp/features/weather/presentation/widgets/forecast_detail/charts/base_chart_widget.dart';

class WindDirectionChart extends BaseChartWidget {
  const WindDirectionChart({
    super.key,
    required super.forecast,
    super.isHorizontalView,
  });

  static const _angles = {
    'N': -90.0,
    'NE': -45.0,
    'E': 0.0,
    'SE': 45.0,
    'S': 90.0,
    'SO': 135.0,
    'O': 180.0,
    'NO': 225.0,
    'W': 180.0,
    'SW': 135.0,
    'NW': 225.0,
  };

  /// Ángulo de una dirección; con dos puntos (ej. `N/NO`) usa su promedio.
  static double? _angleFor(String? direction) {
    if (direction == null || direction.trim().isEmpty) return null;
    final angles = direction
        .split('/')
        .map((p) => _angles[p.trim().toUpperCase()])
        .whereType<double>()
        .toList();
    if (angles.isEmpty) return null;
    var x = 0.0;
    var y = 0.0;
    for (final a in angles) {
      x += math.cos(a * math.pi / 180);
      y += math.sin(a * math.pi / 180);
    }
    return math.atan2(y, x) * 180 / math.pi;
  }

  @override
  Widget buildChart(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Center(
            child: SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.orange.withValues(alpha: 0.08),
                      border: Border.all(color: Colors.orange, width: 2),
                    ),
                  ),
                  const Positioned(top: 8, child: Text('N', style: TextStyle(color: Colors.white))),
                  const Positioned(bottom: 8, child: Text('S', style: TextStyle(color: Colors.white))),
                  const Positioned(left: 12, child: Text('O', style: TextStyle(color: Colors.white))),
                  const Positioned(right: 12, child: Text('E', style: TextStyle(color: Colors.white))),
                  _directionMarker(label: 'AM', direction: forecast.windDirectionAM, color: PucaraColors.accentBright),
                  _directionMarker(label: 'PM', direction: forecast.windDirectionPM, color: Colors.orange),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            _legendChip('AM', fmtText(forecast.windDirectionAM), PucaraColors.accentBright),
            _legendChip('PM', fmtText(forecast.windDirectionPM), Colors.orange),
            _legendChip('Intensidad', fmtNum(forecast.windIntensity, 'km/h'), const Color(0xFF67D7D0)),
            _legendChip('Ráfaga', fmtNum(forecast.gust, 'km/h'), Colors.white70),
          ],
        ),
      ],
    );
  }

  Widget _directionMarker({
    required String label,
    required String? direction,
    required Color color,
  }) {
    final degrees = _angleFor(direction);
    if (degrees == null) return const SizedBox.shrink();
    final angle = degrees * (math.pi / 180);
    const radius = 66.0;
    final dx = radius * math.cos(angle);
    final dy = radius * math.sin(angle);

    return Transform.translate(
      offset: Offset(dx, dy),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _legendChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.white, fontSize: 13),
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
