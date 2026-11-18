class Weather {
  final int id;
  final String cityName;
  final double? temperature;
  final double? minTemperature;
  final double? maxTemperature;
  final double? windSpeed;
  final String description;
  final String iconCode;

  Weather({
    required this.id,
    required this.cityName,
    this.temperature,
    this.minTemperature,
    this.maxTemperature,
    this.windSpeed,
    required this.description,
    required this.iconCode,
  });
}
