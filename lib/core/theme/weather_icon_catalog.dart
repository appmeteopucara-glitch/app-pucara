import 'package:flutter/material.dart';

/// Catálogo de íconos meteorológicos (nombres según el documento del cliente).
class WeatherIconOption {
  final String key;
  final String label;
  const WeatherIconOption(this.key, this.label);

  String get asset => 'assets/images/weather_icons/${key.toLowerCase()}.png';
}

class WeatherIconCatalog {
  static const String defaultKey = 'DESPEJADO_DIA';

  static const List<WeatherIconOption> options = [
    WeatherIconOption('DESPEJADO_DIA', 'Despejado día'),
    WeatherIconOption('ESCASA_NUBOSIDAD_DIA', 'Escasa nubosidad día'),
    WeatherIconOption('PARCIAL_DIA', 'Parcial día'),
    WeatherIconOption('PARCIAL_NUBLADO_DIA', 'Parcial nublado día'),
    WeatherIconOption('NUBLADO_DIA', 'Nublado día'),
    WeatherIconOption('NEBLINA_DIA', 'Neblina día'),
    WeatherIconOption('NIEBLA_DIA', 'Niebla día'),
    WeatherIconOption('NIEVE_DIA_1', 'Nieve día 1'),
    WeatherIconOption('NIEVE_DIA_2', 'Nieve día 2'),
    WeatherIconOption('NEVADAS_DIA_3', 'Nevadas día 3'),
    WeatherIconOption('CHUBASCOS_AGUA_DIA', 'Chubascos agua día'),
    WeatherIconOption('CHUBASCOS_DIA_2', 'Chubascos día 2'),
    WeatherIconOption('ELECTRICAD_DIA_1', 'Electricad día 1'),
    WeatherIconOption('ELECTRICA_DIA_2', 'Electrica día 2'),
    WeatherIconOption('ELECTRICA_DIA_3', 'Electrica día 3'),
    WeatherIconOption('CUBIERTO', 'Cubierto'),
    WeatherIconOption('NEVADA_MODERADA', 'Nevada moderada'),
    WeatherIconOption('NEVADA_INTENSA', 'Nevada intensa'),
    WeatherIconOption('LLOVIZNA', 'Llovizna'),
    WeatherIconOption('LLUVIA_DEBIL', 'Lluvia debil'),
    WeatherIconOption('LLUVIA_INTENSA', 'Lluvia intensa'),
    WeatherIconOption('GRANIZO', 'Granizo'),
    WeatherIconOption('ELECTRICA_INTENSA', 'Electrica intensa'),
    WeatherIconOption('AGUA_NIEVE', 'Agua nieve'),
    WeatherIconOption('NIEBLA_NUBLADO_NOCHE', 'Niebla nublado noche'),
    WeatherIconOption('NIEBLA_NUBLADO_DIA', 'Niebla nublado día'),
    WeatherIconOption('NIEBLA_CUBIERTO', 'Niebla cubierto'),
    WeatherIconOption('ELECTRICA_INTENSA_NIEVE', 'Electrica intensa nieve'),
    WeatherIconOption('TORMENTA_POLVO', 'Tormenta polvo'),
    WeatherIconOption('VENTISCA', 'Ventisca'),
    WeatherIconOption('AGUA_NIEVE_NUBLADO_DIA', 'Agua nieve nublado día'),
    WeatherIconOption('AGUA_NIEVE_NUBLADO_NOCHE', 'Agua nieve nublado noche'),
    WeatherIconOption('NEVADAS_DIA_4', 'Nevadas día 4'),
    WeatherIconOption('NEVADAS_NOCHE_4', 'Nevadas noche 4'),
    WeatherIconOption('NIEVE_VIENTO', 'Nieve viento'),
    WeatherIconOption('LLUVIA_VIENTO', 'Lluvia viento'),
    WeatherIconOption('CUBIERTO_CHUBASCOS', 'Cubierto chubascos'),
    WeatherIconOption('ELECTRICA_NOCHE_3', 'Electrica noche 3'),
    WeatherIconOption('DESPEJADO_NOCHE', 'Despejado noche'),
    WeatherIconOption('ESCASA_NUBOSIDAD_NOCHE', 'Escasa nubosidad noche'),
    WeatherIconOption('PARCIAL_NOCHE', 'Parcial noche'),
    WeatherIconOption('PARCIAL_NUBLADO_NOCHE', 'Parcial nublado noche'),
    WeatherIconOption('NUBLADO_NOCHE', 'Nublado noche'),
    WeatherIconOption('NEBLINA_NOCHE', 'Neblina noche'),
    WeatherIconOption('NIEBLA_NOCHE', 'Niebla noche'),
    WeatherIconOption('NIEVE_NOCHE_1', 'Nieve noche 1'),
    WeatherIconOption('NIEVE_NOCHE_2', 'Nieve noche 2'),
    WeatherIconOption('NEVADAS_NOCHE_3', 'Nevadas noche 3'),
    WeatherIconOption('CHUBASCOS_AGUA_NOCHE', 'Chubascos agua noche'),
    WeatherIconOption('CHUBASCOS_NOCHE_2', 'Chubascos noche 2'),
    WeatherIconOption('ELECTRICA_NOCHE_1', 'Electrica noche 1'),
    WeatherIconOption('ELECTRICA_NOCHE_2', 'Electrica noche 2'),
  ];

  static final Map<String, WeatherIconOption> _byKey = {
    for (final o in options) o.key: o,
  };

  /// Claves antiguas de la app (4 estados) y su equivalente en el catálogo.
  static const Map<String, String> _legacy = {
    'sunny': 'DESPEJADO_DIA',
    'cloudy': 'NUBLADO_DIA',
    'rainy': 'LLUVIA_DEBIL',
    'stormy': 'ELECTRICA_DIA_2',
    'snowy': 'NIEVE_DIA_1',
    // Valores de `weatherIcon` que calcula el backend.
    'storm': 'ELECTRICA_DIA_2',
    'snow': 'NIEVE_DIA_1',
    'rain': 'LLUVIA_DEBIL',
    'partly_cloudy': 'PARCIAL_DIA',
  };

  /// Devuelve la clave del catálogo para [value] o null si no corresponde.
  static String? resolve(String? value) {
    if (value == null) return null;
    final v = value.trim();
    if (v.isEmpty) return null;
    final upper = v.toUpperCase();
    if (_byKey.containsKey(upper)) return upper;
    return _legacy[v.toLowerCase()];
  }

  static WeatherIconOption? optionFor(String? value) {
    final key = resolve(value);
    return key == null ? null : _byKey[key];
  }

  static String labelFor(String? value) =>
      optionFor(value)?.label ?? optionFor(defaultKey)!.label;

  /// Primer token del resumen ("KEY, visibilidad ...") si es una clave válida.
  static String? fromSummary(String summary) {
    final token = summary.split(',').first.trim().toUpperCase();
    return _byKey.containsKey(token) ? token : null;
  }
}

/// Muestra el ícono del catálogo; si [type] no está en él, usa [fallback].
class WeatherIconView extends StatelessWidget {
  final String type;
  final double size;
  final Widget fallback;
  const WeatherIconView({
    super.key,
    required this.type,
    required this.size,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final option = WeatherIconCatalog.optionFor(type);
    if (option == null) return fallback;
    return Image.asset(option.asset, width: size, height: size, fit: BoxFit.contain);
  }
}
