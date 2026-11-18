import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pronosticosapp/core/theme/pucara_ui.dart';
import 'package:pronosticosapp/core/theme/weather_icon_catalog.dart';

class ForecastUtils {
  static Widget getWeatherIconByType(String type, {double size = 24}) {
    final option = WeatherIconCatalog.optionFor(type);
    if (option != null && !const {'rain', 'snow', 'storm'}.contains(type)) {
      return Image.asset(option.asset, width: size, height: size, fit: BoxFit.contain);
    }
    switch (type) {
      case 'sunny':
        return Icon(Icons.wb_sunny_outlined, color: const Color(0xFFFFD45D), size: size);
      case 'cloudy':
        return Icon(Icons.cloud_outlined, color: const Color(0xFFEAEAEA), size: size);
      case 'rainy':
        return Icon(Icons.grain, color: PucaraColors.accentBright, size: size);
      case 'stormy':
        return Icon(Icons.flash_on, color: const Color(0xFFFFC95B), size: size);
      case 'snowy':
        return Icon(Icons.ac_unit, color: const Color(0xFF7CC5FF), size: size);
      case 'temperature':
        return Icon(Icons.thermostat, color: const Color(0xFFFF745E), size: size);
      case 'isotherm':
        return Icon(Icons.waves, color: PucaraColors.accentBright, size: size);
      case 'rain':
        return Icon(Icons.grain, color: PucaraColors.accentBright, size: size);
      case 'water':
        return Icon(Icons.opacity, color: const Color(0xFF59D1B7), size: size);
      case 'isothermHeight':
        return Icon(Icons.height, color: PucaraColors.accentBright, size: size);
      case 'snow':
        return Icon(Icons.ac_unit, color: const Color(0xFF7CC5FF), size: size);
      case 'humidity':
        return Icon(Icons.water_drop, color: const Color(0xFF59D1B7), size: size);
      case 'wind':
        return Icon(Icons.air, color: const Color(0xFFEAEAEA), size: size);
      case 'storm':
        return Icon(Icons.flash_on, color: const Color(0xFFFFC95B), size: size);
      default:
        return Icon(Icons.help_outline, color: PucaraColors.textSecondary, size: size);
    }
  }

  static String formatDate(DateTime date) {
    return DateFormat('d MMM yyyy').format(date);
  }

  static Color getColorByType(String type) {
    switch (type) {
      case 'temperature':
        return const Color(0xFFFF745E);
      case 'isotherm':
        return PucaraColors.accentBright;
      case 'rain':
        return PucaraColors.accentBright;
      case 'water':
        return const Color(0xFF59D1B7);
      case 'snow':
        return const Color(0xFF7CC5FF);
      case 'humidity':
        return const Color(0xFF59D1B7);
      case 'wind':
        return const Color(0xFFEAEAEA);
      case 'storm':
        return const Color(0xFFFFC95B);
      default:
        return PucaraColors.accentBright;
    }
  }
}
