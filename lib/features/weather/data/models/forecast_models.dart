import 'package:pronosticosapp/features/weather/domain/entities/forecast_record.dart';

class ForecastModel {
  final Map<String, dynamic> json;
  ForecastModel(this.json);

  factory ForecastModel.fromJson(Map<String, dynamic> json) =>
      ForecastModel(json);

  /// Lee una clave sin distinguir mayúsculas de la primera letra (camel/Pascal).
  dynamic _pick(String key) {
    if (json.containsKey(key)) return json[key];
    final pascal = key[0].toUpperCase() + key.substring(1);
    return json[pascal];
  }

  double? _double(String key) {
    final v = _pick(key);
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  int? _int(String key) {
    final v = _pick(key);
    if (v is num) return v.round();
    if (v is String) return int.tryParse(v);
    return null;
  }

  String? _string(String key) {
    final v = _pick(key);
    if (v == null) return null;
    final s = v.toString();
    return s.isEmpty ? null : s;
  }

  ForecastRecord toEntity() {
    return ForecastRecord(
      id: _string('id') ?? '',
      siteId: _string('siteId') ?? '',
      forecastDate:
          DateTime.tryParse(_string('forecastDate') ?? '') ?? DateTime.now(),
      temperatureMinC: _double('temperatureMinC'),
      temperatureMaxC: _double('temperatureMaxC'),
      windDirectionAm: _string('windDirectionAm'),
      windDirectionPm: _string('windDirectionPm'),
      isothermMinMsnm: _int('isothermMinMsnm'),
      isothermMaxMsnm: _int('isothermMaxMsnm'),
      isothermHeightMeters: _int('isothermHeightMeters'),
      electricActivityProbabilityPercent: _int(
        'electricActivityProbabilityPercent',
      ),
      precipitationProbabilityPercent: _int('precipitationProbabilityPercent'),
      waterAccumulationMm: _double('waterAccumulationMm'),
      snowAccumulationCm: _double('snowAccumulationCm'),
      windIntensityKmH: _double('windIntensityKmH'),
      maxWindGustKmH: _double('maxWindGustKmH'),
      relativeHumidityPercent: _int('relativeHumidityPercent'),
      summary: _string('summary'),
      minIsothermLevelMeters: _int('minIsothermLevelMeters'),
      rainProbabilityPercent: _int('rainProbabilityPercent'),
      stormProbabilityPercent: _int('stormProbabilityPercent'),
      humidityMinPercent: _int('humidityMinPercent'),
      humidityMaxPercent: _int('humidityMaxPercent'),
      weatherIcon: _string('weatherIcon'),
    );
  }
}
