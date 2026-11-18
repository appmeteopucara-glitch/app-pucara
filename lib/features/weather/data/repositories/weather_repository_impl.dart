import 'package:pronosticosapp/features/weather/domain/entities/forecast_input.dart';
import 'package:pronosticosapp/features/weather/domain/entities/forecast_record.dart';
import 'package:pronosticosapp/features/weather/domain/entities/site.dart';
import 'package:pronosticosapp/features/weather/domain/repositories/weather_repository.dart';
import 'package:pronosticosapp/features/weather/data/datasource/weather_remote_data_source.dart';

class WeatherRepositoryImpl implements WeatherRepository {
  final WeatherRemoteDataSource remote;
  WeatherRepositoryImpl(this.remote);

  @override
  Future<List<Site>> getSites({int pageNumber = 1, int pageSize = 50, String? companyId}) {
    return remote.getSites(pageNumber: pageNumber, pageSize: pageSize, companyId: companyId);
  }

  @override
  Future<List<ForecastRecord>> getForecastsBySite(String siteId) {
    return remote.getForecastsBySite(siteId);
  }

  @override
  Future<ForecastRecord?> createForecast(ForecastInput input) {
    return remote.createForecast(input);
  }

  @override
  Future<bool> updateForecast(String id, ForecastInput input) {
    return remote.updateForecast(id, input);
  }

  @override
  Future<bool> deleteForecast(String id) {
    return remote.deleteForecast(id);
  }
}
