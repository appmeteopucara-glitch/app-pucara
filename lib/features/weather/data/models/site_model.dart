import 'package:pronosticosapp/features/weather/domain/entities/site.dart';

class SiteModel {
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
  SiteModel({
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
  factory SiteModel.fromJson(Map<String, dynamic> json) {
    return SiteModel(
      id: json['id']?.toString() ?? '',
      companyId: json['companyId']?.toString() ?? '',
      companyName: json['companyName']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      minTemperatureC: json['minTemperatureC'] is num ? (json['minTemperatureC'] as num).toDouble() : null,
      maxTemperatureC: json['maxTemperatureC'] is num ? (json['maxTemperatureC'] as num).toDouble() : null,
      currentTemperatureC: json['currentTemperatureC'] is num ? (json['currentTemperatureC'] as num).toDouble() : null,
      precipitationProbabilityPercent: json['precipitationProbabilityPercent'] is num
          ? (json['precipitationProbabilityPercent'] as num).toInt()
          : (json['rainProbabilityPercent'] is num ? (json['rainProbabilityPercent'] as num).toInt() : null),
      weatherIcon: json['weatherIcon']?.toString(),
      latitude: (json['latitude'] is num) ? (json['latitude'] as num).toDouble() : 0.0,
      longitude: (json['longitude'] is num) ? (json['longitude'] as num).toDouble() : 0.0,
      isActive: json['isActive'] == true,
      createdAtUtc: json['createdAtUtc'] != null ? DateTime.tryParse(json['createdAtUtc'].toString()) : null,
      updatedAtUtc: json['updatedAtUtc'] != null ? DateTime.tryParse(json['updatedAtUtc'].toString()) : null,
    );
  }
  Site toEntity() {
    return Site(
      id: id,
      companyId: companyId,
      companyName: companyName,
      name: name,
      address: address,
      minTemperatureC: minTemperatureC,
      maxTemperatureC: maxTemperatureC,
      currentTemperatureC: currentTemperatureC,
      precipitationProbabilityPercent: precipitationProbabilityPercent,
      weatherIcon: weatherIcon,
      latitude: latitude,
      longitude: longitude,
      isActive: isActive,
      createdAtUtc: createdAtUtc,
      updatedAtUtc: updatedAtUtc,
    );
  }
}
