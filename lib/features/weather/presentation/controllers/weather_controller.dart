import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:pronosticosapp/features/weather/domain/site_variables.dart';
import 'package:pronosticosapp/core/theme/weather_icon_catalog.dart';
import 'package:pronosticosapp/features/weather/domain/entities/weather.dart';
import 'package:pronosticosapp/features/weather/domain/entities/forecast_day.dart';
import 'package:pronosticosapp/features/weather/data/weather_providers.dart';
import 'package:pronosticosapp/features/weather/domain/usecases/usecases.dart';
import 'package:pronosticosapp/features/weather/domain/entities/site.dart';
import 'package:pronosticosapp/features/weather/data/datasource/weather_remote_data_source.dart'
    show AccessDeniedError, SessionExpiredError, ValidationError;
import 'package:pronosticosapp/features/weather/domain/entities/forecast_input.dart';
import 'package:pronosticosapp/core/routes/app_routes.dart';
import 'package:pronosticosapp/core/storage/token_storage.dart';
import 'package:pronosticosapp/core/storage/company_session.dart';
import 'package:pronosticosapp/features/weather/domain/entities/forecast_record.dart';

class WeatherController extends GetxController {
  final RxList<Weather> weatherList = <Weather>[].obs;
  final RxList<ForecastDay> forecastDays = <ForecastDay>[].obs;
  final RxList<Site> sites = <Site>[].obs;
  final RxMap<int, String> forecastIdMap = <int, String>{}.obs;
  final RxList<String> weatherSiteIds = <String>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxString errorMessage = ''.obs;
  /// Cuántas empresas tiene el usuario (0 = sin asignación) y cuál está elegida.
  final RxInt companyCount = 1.obs;
  final RxString selectedCompanyName = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _startup();
  }

  Future<void> _startup() async {
    await loadSites();
    await fetchForecasts();
  }

  Future<void> loadSites() async {
    try {
      companyCount.value = await CompanySession.companyCount();
      selectedCompanyName.value = await CompanySession.selectedCompanyName() ?? '';
      final companyId = await TokenStorage.getSelectedCompanyId();
      final repo = buildWeatherRepository();
      final usecase = GetSites(repo);
      final list = await usecase(pageNumber: 1, pageSize: 100, companyId: companyId);
      sites.assignAll(list);
      for (final site in list) {
        final vars = SiteVariables.forSiteName(site.name, company: site.companyName);
        debugPrint('[SiteVariables] "${site.name}" (${site.companyName}) -> ${vars == null ? "SIN COINCIDENCIA (todas)" : vars.map((v) => v.name).join(",")}');
      }
      _assignWeatherFromSites(list);
    } on SessionExpiredError {
      await _handleSessionExpired();
    } catch (e) {
      debugPrint('[WeatherController] no se pudieron cargar los sitios: $e');
      // 403: la empresa elegida ya no es accesible. Se descarta y se vuelve a elegir.
      if (e is AccessDeniedError && await TokenStorage.getSelectedCompanyId() != null && companyCount.value > 1) {
        await TokenStorage.saveSelectedCompanyId(null);
        Get.offAllNamed(AppRoutes.selectCompany);
        return;
      }
      errorMessage.value = e is ValidationError ? e.message : 'No se pudieron cargar los sitios';
    }
  }

  /// La API v1 responde 401 con token inválido o vencido: volver al login.
  Future<void> _handleSessionExpired() async {
    await TokenStorage.clear();
    Get.offAllNamed(AppRoutes.auth);
  }

  String? siteIdForIndex(int index) {
    if (index < 0 || index >= weatherSiteIds.length) return null;
    return weatherSiteIds[index];
  }

  ForecastDay? nearestForecastForSite(String? siteId) {
    if (siteId == null || siteId.isEmpty) return null;
    final normalizedSiteId = siteId.toLowerCase();
    final siteForecasts = forecastDays
        .where((f) => f.siteId.toLowerCase() == normalizedSiteId)
        .toList();
    if (siteForecasts.isEmpty) return null;

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    siteForecasts.sort((a, b) => a.date.compareTo(b.date));

    for (final forecast in siteForecasts) {
      final localDate = DateTime(
        forecast.date.year,
        forecast.date.month,
        forecast.date.day,
      );
      if (!localDate.isBefore(startOfToday)) {
        return forecast;
      }
    }
    return siteForecasts.last;
  }

  Future<void> loadForecastsForSite(String siteId) async {
    final repo = buildWeatherRepository();
    final usecase = GetForecastsBySite(repo);
    final data = await usecase(siteId);
    _assignForecastDaysOnly(data);
  }

  /// La API v1 no tiene un listado global de pronósticos: se consulta por sitio.
  Future<void> fetchForecasts() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      if (sites.isEmpty) {
        forecastDays.clear();
        return;
      }
      final data = await _fetchForecastsFromSites();
      if (data.isNotEmpty) {
        _assignFromRecords(data);
      } else {
        forecastDays.clear();
        forecastIdMap.clear();
        _assignFromSites();
      }
    } on SessionExpiredError {
      await _handleSessionExpired();
    } catch (_) {
      errorMessage.value = 'No hay datos disponibles';
    } finally {
      isLoading.value = false;
    }
  }

  void refreshWeatherData() {
    loadSites().then((_) => fetchForecasts());
  }

  // Método para cargar los pronósticos diarios
  void loadForecastDays() {
    forecastDays.clear();
  }

  // Método para agregar un nuevo pronóstico
  void addForecastDay(ForecastDay forecastDay) {
    forecastDays.add(forecastDay);
  }

  // Método para actualizar un pronóstico existente
  void updateForecastDay(ForecastDay updatedForecast) {
    final index = forecastDays.indexWhere(
      (forecast) => forecast.id == updatedForecast.id,
    );
    if (index != -1) {
      forecastDays[index] = updatedForecast;
    }
  }

  // Método para obtener un pronóstico por ID
  ForecastDay? getForecastById(int id) {
    try {
      return forecastDays.firstWhere((forecast) => forecast.id == id);
    } catch (e) {
      return null;
    }
  }

  // Método para obtener los días de la semana a partir de hoy
  List<String> getNextDays(int count) {
    final now = DateTime.now();
    final days = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    final List<String> nextDays = [];

    for (int i = 0; i < count; i++) {
      final nextDate = now.add(Duration(days: i));
      final dayIndex =
          nextDate.weekday - 1; // weekday va de 1 (lunes) a 7 (domingo)
      nextDays.add(days[dayIndex]);
    }

    return nextDays;
  }

  Future<ForecastRecord?> createForecastRemote(ForecastInput input) async {
    try {
      isSaving.value = true;
      final repo = buildWeatherRepository();
      final created = await CreateForecast(repo)(input);
      if (created != null) {
        _upsertForecastRecord(created);
        return created;
      }
      return null;
    } on SessionExpiredError {
      await _handleSessionExpired();
      return null;
    } catch (e) {
      if (e is ValidationError) {
        rethrow;
      }
      return null;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> updateForecastRemote(String id, ForecastInput input) async {
    try {
      isSaving.value = true;
      final repo = buildWeatherRepository();
      final ok = await UpdateForecast(repo)(id, input);
      if (ok) {
        await fetchForecasts();
      }
      return ok;
    } on SessionExpiredError {
      await _handleSessionExpired();
      return false;
    } catch (e) {
      if (e is ValidationError) {
        rethrow;
      }
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> deleteForecastRemote(String id) async {
    try {
      isSaving.value = true;
      final repo = buildWeatherRepository();
      final usecase = DeleteForecast(repo);
      final ok = await usecase(id);
      if (ok) {
        await fetchForecasts();
      }
      return ok;
    } catch (_) {
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  void _assignFromRecords(List<ForecastRecord> records) {
    final siteById = {for (final s in sites) s.id.toLowerCase(): s};
    final List<ForecastDay> mapped = [];
    final Map<int, String> idMap = {};
    for (final r in records) {
      final forecastDay = _forecastDayFromRecord(r);
      mapped.add(forecastDay);
      idMap[forecastDay.id] = r.id;
    }
    forecastDays.assignAll(mapped);
    forecastIdMap.assignAll(idMap);

    final grouped = <String, List<ForecastRecord>>{};
    for (final record in records) {
      grouped
          .putIfAbsent(record.siteId.toLowerCase(), () => <ForecastRecord>[])
          .add(record);
    }

    final wl = <Weather>[];
    final siteIds = <String>[];
    final orderedSiteIds = sites.isNotEmpty
        ? sites.map((site) => site.id).toList()
        : grouped.keys.toList();

    for (var i = 0; i < orderedSiteIds.length; i++) {
      final siteId = orderedSiteIds[i];
      final normalizedSiteId = siteId.toLowerCase();
      final site = siteById[normalizedSiteId];
      final recordsForSite = grouped[normalizedSiteId];
      final selected = recordsForSite != null && recordsForSite.isNotEmpty
          ? _preferredRecordForSite(recordsForSite)
          : null;
      wl.add(
        Weather(
          id: i + 1,
          cityName: site?.name ?? 'Sitio',
          temperature: selected != null
              ? selected.temperatureMaxC
              : site?.currentTemperatureC,
          minTemperature: selected != null
              ? selected.temperatureMinC
              : site?.minTemperatureC,
          maxTemperature: selected != null
              ? selected.temperatureMaxC
              : site?.maxTemperatureC,
          windSpeed: selected?.maxWindGustKmH,
          description: _siteDescription(site),
          iconCode: _iconCodeFromSite(site),
        ),
      );
      siteIds.add(siteId);
    }
    weatherList.assignAll(wl);
    weatherSiteIds.assignAll(siteIds);
  }

  void _assignFromSites() {
    _assignWeatherFromSites(sites);
  }

  void _assignWeatherFromSites(List<Site> sourceSites) {
    final wl = <Weather>[];
    final ids = <String>[];
    for (var i = 0; i < sourceSites.length; i++) {
      final s = sourceSites[i];
      wl.add(
        Weather(
          id: i + 1,
          cityName: s.name,
          temperature: s.currentTemperatureC ?? s.maxTemperatureC,
          minTemperature: s.minTemperatureC,
          maxTemperature: s.maxTemperatureC,
          windSpeed: null,
          description: _siteDescription(s),
          iconCode: _iconCodeFromSite(s),
        ),
      );
      ids.add(s.id);
    }
    weatherList.assignAll(wl);
    weatherSiteIds.assignAll(ids);
  }

  Future<List<ForecastRecord>> _fetchForecastsFromSites() async {
    final repo = buildWeatherRepository();
    final usecase = GetForecastsBySite(repo);
    var sessionExpired = false;

    final results = await Future.wait(
      sites.map((site) async {
        try {
          final list = await usecase(site.id);
          final dates = list.map((r) => '${r.forecastDate.month}/${r.forecastDate.day}').join(', ');
          debugPrint('[Pronósticos] "${site.name}": ${list.length} recibidos${list.isEmpty ? '' : ' ($dates)'}');
          return list;
        } on SessionExpiredError {
          sessionExpired = true;
          return <ForecastRecord>[];
        } catch (e) {
          // Si un sitio falla, seguimos con los demás para no vaciar el home completo.
          debugPrint('[Pronósticos] error en "${site.name}": $e');
          return <ForecastRecord>[];
        }
      }),
    );
    if (sessionExpired) throw SessionExpiredError();

    final byId = <String, ForecastRecord>{};
    for (final record in results.expand((r) => r)) {
      byId[record.id] = record;
    }
    return byId.values.toList();
  }

  void _assignForecastDaysOnly(List<ForecastRecord> records) {
    final List<ForecastDay> mapped = [];
    final Map<int, String> idMap = {};
    for (final r in records) {
      final forecastDay = _forecastDayFromRecord(r);
      mapped.add(forecastDay);
      idMap[forecastDay.id] = r.id;
    }
    forecastDays.assignAll(mapped);
    forecastIdMap.assignAll(idMap);
  }

  int _localIdForRecord(ForecastRecord record, DateTime date) {
    return Object.hash(
      record.id,
      record.siteId,
      date.toUtc().millisecondsSinceEpoch,
    );
  }

  ForecastRecord _preferredRecordForSite(List<ForecastRecord> records) {
    final sorted = [...records]
      ..sort((a, b) => a.forecastDate.compareTo(b.forecastDate));
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    for (final record in sorted) {
      final forecastDay = _forecastCalendarDate(record.forecastDate);
      if (!forecastDay.isBefore(startOfToday)) {
        return record;
      }
    }
    return sorted.last;
  }

  DateTime _forecastCalendarDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  String _siteDescription(Site? site) {
    final icon = site?.weatherIcon?.toLowerCase() ?? '';
    if (icon.contains('cloud')) return 'Nublado';
    if (icon.contains('rain')) return 'Precipitación líquida';
    if (icon.contains('storm')) return 'Tormenta';
    if (icon.contains('snow')) return 'Precipitación sólida';
    return 'Soleado';
  }

  String _iconCodeFromSite(Site? site) {
    final icon = site?.weatherIcon?.toLowerCase() ?? '';
    if (icon.contains('cloud')) return '03d';
    if (icon.contains('rain')) return '10d';
    if (icon.contains('storm')) return '11d';
    if (icon.contains('snow')) return '13d';
    return '01d';
  }

  ForecastDay _forecastDayFromRecord(ForecastRecord record) {
    final date = _forecastCalendarDate(record.forecastDate);
    final days = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    // Se lee primero el campo v1 y se cae al campo del modelo anterior.
    return ForecastDay(
      id: _localIdForRecord(record, date),
      siteId: record.siteId,
      day: days[date.weekday - 1],
      icon: _iconForRecord(record),
      date: date,
      min: record.temperatureMinC,
      max: record.temperatureMaxC,
      isoMin: record.isothermMinMsnm,
      isoMax: record.isothermMaxMsnm,
      isoHeight: record.isothermHeightMeters ?? record.minIsothermLevelMeters,
      electricProb:
          record.electricActivityProbabilityPercent ??
          record.stormProbabilityPercent,
      precipProb:
          record.precipitationProbabilityPercent ??
          record.rainProbabilityPercent,
      waterMm: record.waterAccumulationMm,
      snowCm: record.snowAccumulationCm,
      windIntensity: record.windIntensityKmH,
      gust: record.maxWindGustKmH,
      humidity:
          record.relativeHumidityPercent ??
          record.humidityMaxPercent ??
          record.humidityMinPercent,
      windDirectionAM: record.windDirectionAm,
      windDirectionPM: record.windDirectionPm,
      summary: record.summary,
    );
  }

  /// Ícono elegido en la app (clave del catálogo guardada en el resumen) o,
  /// si no hay, el que calcula el backend.
  String _iconForRecord(ForecastRecord record) {
    return WeatherIconCatalog.fromSummary(record.summary ?? '') ??
        WeatherIconCatalog.resolve(record.weatherIcon) ??
        'sunny';
  }

  void _upsertForecastRecord(ForecastRecord record) {
    final forecastDay = _forecastDayFromRecord(record);
    final date = _forecastCalendarDate(record.forecastDate);
    final index = forecastDays.indexWhere(
      (item) =>
          item.siteId.toLowerCase() == record.siteId.toLowerCase() &&
          item.date.year == date.year &&
          item.date.month == date.month &&
          item.date.day == date.day,
    );

    if (index == -1) {
      forecastDays.add(forecastDay);
    } else {
      forecastDays[index] = forecastDay;
    }
    forecastIdMap[forecastDay.id] = record.id;
  }

  String? getBackendIdForLocal(int localId) {
    return forecastIdMap[localId];
  }
}
