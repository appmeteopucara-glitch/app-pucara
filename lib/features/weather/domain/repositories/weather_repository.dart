import 'package:pronosticosapp/features/weather/domain/entities/forecast_input.dart';
import 'package:pronosticosapp/features/weather/domain/entities/forecast_record.dart';
import 'package:pronosticosapp/features/weather/domain/entities/site.dart';

abstract class WeatherRepository {
  Future<List<Site>> getSites({int pageNumber, int pageSize, String? companyId});
  Future<List<ForecastRecord>> getForecastsBySite(String siteId);
  Future<ForecastRecord?> createForecast(ForecastInput input);
  Future<bool> updateForecast(String id, ForecastInput input);
  Future<bool> deleteForecast(String id);
}
