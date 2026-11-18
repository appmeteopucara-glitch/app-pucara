/// Pronóstico de un día listo para mostrar. Los valores `null` significan
/// "no informado" y la UI debe mostrar un placeholder, nunca 0.
class ForecastDay {
  final int id;
  final String siteId;
  final String day;
  final String icon;
  final DateTime date;

  final double? min;
  final double? max;
  /// Isoterma 0 °C en msnm.
  final int? isoMin;
  final int? isoMax;
  final int? isoHeight;
  final int? electricProb;
  final int? precipProb;
  final double? waterMm;
  final double? snowCm;
  final double? windIntensity;
  final double? gust;
  final int? humidity;
  final String? windDirectionAM;
  final String? windDirectionPM;
  final String? summary;

  ForecastDay({
    required this.id,
    this.siteId = '',
    required this.day,
    required this.icon,
    required this.date,
    this.min,
    this.max,
    this.isoMin,
    this.isoMax,
    this.isoHeight,
    this.electricProb,
    this.precipProb,
    this.waterMm,
    this.snowCm,
    this.windIntensity,
    this.gust,
    this.humidity,
    this.windDirectionAM,
    this.windDirectionPM,
    this.summary,
  });
}
