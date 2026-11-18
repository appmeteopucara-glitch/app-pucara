import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:pronosticosapp/core/network/api_client.dart';
import 'package:pronosticosapp/core/storage/token_storage.dart';
import 'package:pronosticosapp/features/weather/data/models/site_model.dart';
import 'package:pronosticosapp/features/weather/data/models/forecast_models.dart';
import 'package:pronosticosapp/features/weather/domain/entities/forecast_input.dart';
import 'package:pronosticosapp/features/weather/domain/entities/site.dart';
import 'package:pronosticosapp/features/weather/domain/entities/forecast_record.dart';

class ValidationError implements Exception {
  final String message;
  ValidationError(this.message);
  @override
  String toString() => message;
}

/// 403: el usuario no tiene acceso al recurso (por ejemplo, a la empresa elegida).
class AccessDeniedError extends ValidationError {
  AccessDeniedError(super.message);
}

/// La API v1 responde 401 cuando no hay sesión o el token venció.
class SessionExpiredError implements Exception {
  @override
  String toString() => 'Tu sesión expiró. Inicia sesión nuevamente.';
}

class WeatherRemoteDataSource {
  final ApiClient apiClient;
  final String sitesEndpoint;
  final String forecastsEndpoint;
  WeatherRemoteDataSource({
    required this.apiClient,
    required this.sitesEndpoint,
    required this.forecastsEndpoint,
  });

  Future<Map<String, String>> _authHeaders() async {
    final t = await TokenStorage.getToken();
    if (t == null || t.isEmpty) return {};
    return {'Authorization': 'Bearer $t'};
  }

  /// Extrae la lista de `data` (o de la raíz) sin importar el casing del envoltorio.
  List<dynamic> _listFrom(dynamic res) {
    if (res is List) return res;
    if (res is Map<String, dynamic>) {
      final data = res['data'] ?? res['Data'];
      if (data is List) return data;
      if (data is Map<String, dynamic>) {
        final items = data['items'] ?? data['Items'];
        if (items is List) return items;
      }
      final items = res['items'] ?? res['Items'];
      if (items is List) return items;
    }
    return const [];
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ApiException catch (e) {
      debugPrint('[WeatherRemoteDataSource] error ${e.statusCode} ${e.message}');
      if (e.statusCode == 401) throw SessionExpiredError();
      // Un 5xx es un fallo del servidor: no se muestra su texto (puede traer detalles internos).
      if (e.statusCode >= 500) {
        throw ValidationError('El servidor tuvo un problema. Intenta de nuevo en unos minutos.');
      }
      final validationError = _extractValidationError(e.message);
      if (e.statusCode == 403) {
        throw AccessDeniedError(validationError?.message ?? 'No tienes acceso a este recurso.');
      }
      if (validationError != null) throw validationError;
      rethrow;
    }
  }

  /// Sin [companyId] devuelve las faenas de todas las empresas del usuario.
  /// Con un [companyId] sin acceso el backend responde 403.
  Future<List<Site>> getSites({int pageNumber = 1, int pageSize = 50, String? companyId}) {
    return _guard(() async {
      final headers = await _authHeaders();
      final res = await apiClient.get(
        sitesEndpoint,
        headers: headers,
        queryParameters: (companyId == null || companyId.isEmpty) ? null : {'companyId': companyId},
      );
      return _listFrom(res)
          .map((e) => SiteModel.fromJson(e as Map<String, dynamic>).toEntity())
          .toList();
    });
  }

  Future<List<ForecastRecord>> getForecastsBySite(String siteId) {
    return _guard(() async {
      final headers = await _authHeaders();
      final res = await apiClient.get(
        '$forecastsEndpoint/sites/$siteId',
        headers: headers,
      );
      return _listFrom(res)
          .map(
            (e) => ForecastModel.fromJson(e as Map<String, dynamic>).toEntity(),
          )
          .toList();
    });
  }

  /// POST v1: `data` es el id del pronóstico creado.
  Future<ForecastRecord?> createForecast(ForecastInput input) {
    return _guard(() async {
      final headers = await _authHeaders();
      final res = await apiClient.post(
        forecastsEndpoint,
        headers: headers,
        body: input.toJson(),
      );
      if (res is Map<String, dynamic>) {
        final success = (res['success'] == true) || (res['Success'] == true);
        final data = res['data'] ?? res['Data'];
        if (data is Map<String, dynamic>) {
          return ForecastModel.fromJson(data).toEntity();
        }
        if (data is String && data.isNotEmpty && success) {
          return ForecastRecord(
            id: data,
            siteId: input.siteId,
            forecastDate: input.forecastDate,
            temperatureMinC: input.temperatureMinC,
            temperatureMaxC: input.temperatureMaxC,
            windDirectionAm: input.windDirectionAm,
            windDirectionPm: input.windDirectionPm,
            isothermMinMsnm: input.isothermMinMsnm,
            isothermMaxMsnm: input.isothermMaxMsnm,
            isothermHeightMeters: input.isothermHeightMeters,
            electricActivityProbabilityPercent:
                input.electricActivityProbabilityPercent,
            precipitationProbabilityPercent:
                input.precipitationProbabilityPercent,
            waterAccumulationMm: input.waterAccumulationMm,
            snowAccumulationCm: input.snowAccumulationCm,
            windIntensityKmH: input.windIntensityKmH,
            maxWindGustKmH: input.maxWindGustKmH,
            relativeHumidityPercent: input.relativeHumidityPercent,
            summary: input.summary,
          );
        }
      }
      return null;
    });
  }

  /// PUT v1: reemplazo completo, sin `siteId` en el cuerpo.
  Future<bool> updateForecast(String id, ForecastInput input) {
    return _guard(() async {
      final headers = await _authHeaders();
      final res = await apiClient.put(
        '$forecastsEndpoint/$id',
        headers: headers,
        body: input.toJson(includeSiteId: false),
      );
      if (res is Map<String, dynamic>) {
        return res['success'] == true || res['Success'] == true;
      }
      return true;
    });
  }

  Future<bool> deleteForecast(String id) {
    return _guard(() async {
      final headers = await _authHeaders();
      final res = await apiClient.delete(
        forecastsEndpoint,
        id: id,
        headers: headers,
      );
      if (res is Map<String, dynamic>) {
        return res['success'] == true || res['Success'] == true;
      }
      return true;
    });
  }

  /// Los mensajes de v1 ya vienen en español: se muestran tal cual.
  /// Las claves de error llegan en PascalCase (`Errors`, `Message`).
  ValidationError? _extractValidationError(String body) {
    try {
      if (body.isEmpty || !body.trim().startsWith('{')) return null;
      final map = json.decode(body) as Map<String, dynamic>;
      final errs = map['Errors'] ?? map['errors'];
      if (errs is List && errs.isNotEmpty) {
        return ValidationError(errs.map((x) => x.toString()).join('\n'));
      }
      final msg = (map['Message'] ?? map['message'])?.toString() ?? '';
      if (msg.isNotEmpty) return ValidationError(msg);
    } catch (_) {
      return null;
    }
    return null;
  }
}
