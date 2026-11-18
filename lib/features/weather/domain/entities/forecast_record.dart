/// Pronóstico tal como lo devuelve la API v1. Toda variable es opcional:
/// `null` significa "no informado" (no es lo mismo que 0).
class ForecastRecord {
  final String id;
  final String siteId;
  final DateTime forecastDate;

  final double? temperatureMinC;
  final double? temperatureMaxC;
  final String? windDirectionAm;
  final String? windDirectionPm;
  /// Isoterma 0 °C en msnm (enteros, 1000 a 6000).
  final int? isothermMinMsnm;
  final int? isothermMaxMsnm;
  final int? isothermHeightMeters;
  final int? electricActivityProbabilityPercent;
  final int? precipitationProbabilityPercent;
  final double? waterAccumulationMm;
  final double? snowAccumulationCm;
  final double? windIntensityKmH;
  final double? maxWindGustKmH;
  final int? relativeHumidityPercent;
  final String? summary;

  /// Campos del modelo anterior (solo lectura).
  final int? minIsothermLevelMeters;
  final int? rainProbabilityPercent;
  final int? stormProbabilityPercent;
  final int? humidityMinPercent;
  final int? humidityMaxPercent;

  /// Ícono calculado por el backend (`storm`, `snow`, `rain`, `partly_cloudy`, `sunny`).
  final String? weatherIcon;

  ForecastRecord({
    required this.id,
    required this.siteId,
    required this.forecastDate,
    this.temperatureMinC,
    this.temperatureMaxC,
    this.windDirectionAm,
    this.windDirectionPm,
    this.isothermMinMsnm,
    this.isothermMaxMsnm,
    this.isothermHeightMeters,
    this.electricActivityProbabilityPercent,
    this.precipitationProbabilityPercent,
    this.waterAccumulationMm,
    this.snowAccumulationCm,
    this.windIntensityKmH,
    this.maxWindGustKmH,
    this.relativeHumidityPercent,
    this.summary,
    this.minIsothermLevelMeters,
    this.rainProbabilityPercent,
    this.stormProbabilityPercent,
    this.humidityMinPercent,
    this.humidityMaxPercent,
    this.weatherIcon,
  });
}
