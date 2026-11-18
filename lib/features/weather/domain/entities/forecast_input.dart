/// Datos que la app envía al crear (POST) o reemplazar (PUT) un pronóstico v1.
/// Solo faena y fecha son obligatorias; el resto va en `null` si no se informa.
class ForecastInput {
  final String siteId;
  final DateTime forecastDate;
  final double? temperatureMinC;
  final double? temperatureMaxC;
  final String? windDirectionAm;
  final String? windDirectionPm;
  /// Isoterma 0 °C en msnm: enteros de 1000 a 6000 (un double viajaría como 3200.0 y la API lo rechaza).
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

  const ForecastInput({
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
  });

  /// La fecha viaja como día local sin zona: `2026-10-12T00:00:00`.
  static String formatDate(DateTime date) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${date.year.toString().padLeft(4, '0')}-${two(date.month)}-${two(date.day)}T00:00:00';
  }

  /// El PUT es un reemplazo completo y no lleva `siteId`.
  Map<String, dynamic> toJson({bool includeSiteId = true}) {
    return {
      if (includeSiteId) 'siteId': siteId,
      'forecastDate': formatDate(forecastDate),
      'temperatureMinC': temperatureMinC,
      'temperatureMaxC': temperatureMaxC,
      'windDirectionAm': windDirectionAm,
      'windDirectionPm': windDirectionPm,
      'isothermMinMsnm': isothermMinMsnm,
      'isothermMaxMsnm': isothermMaxMsnm,
      'isothermHeightMeters': isothermHeightMeters,
      'electricActivityProbabilityPercent': electricActivityProbabilityPercent,
      'precipitationProbabilityPercent': precipitationProbabilityPercent,
      'waterAccumulationMm': waterAccumulationMm,
      'snowAccumulationCm': snowAccumulationCm,
      'windIntensityKmH': windIntensityKmH,
      'maxWindGustKmH': maxWindGustKmH,
      'relativeHumidityPercent': relativeHumidityPercent,
      'summary': summary,
    };
  }
}
