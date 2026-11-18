class Site {
  final String id;
  final String companyId;
  final String companyName;
  final String name;
  final String address;
  final double? minTemperatureC;
  final double? maxTemperatureC;
  final double? currentTemperatureC;
  final int? precipitationProbabilityPercent;
  final String? weatherIcon;
  final double latitude;
  final double longitude;
  final bool isActive;
  final DateTime? createdAtUtc;
  final DateTime? updatedAtUtc;
  Site({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.name,
    required this.address,
    this.minTemperatureC,
    this.maxTemperatureC,
    this.currentTemperatureC,
    this.precipitationProbabilityPercent,
    this.weatherIcon,
    required this.latitude,
    required this.longitude,
    required this.isActive,
    this.createdAtUtc,
    this.updatedAtUtc,
  });
}
