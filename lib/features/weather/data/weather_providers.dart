import 'package:pronosticosapp/core/config/env.dart';
import 'package:pronosticosapp/core/network/api_client.dart';
import 'package:pronosticosapp/features/weather/data/datasource/weather_remote_data_source.dart';
import 'package:pronosticosapp/features/weather/data/repositories/weather_repository_impl.dart';
import 'package:pronosticosapp/features/weather/domain/repositories/weather_repository.dart';

WeatherRepository buildWeatherRepository() {
  final api = ApiClient(baseUrl: Env.baseUrl);
  final ds = WeatherRemoteDataSource(
    apiClient: api,
    sitesEndpoint: '/api/v1/forecasts/sites',
    forecastsEndpoint: '/api/v1/forecasts',
  );
  return WeatherRepositoryImpl(ds);
}
