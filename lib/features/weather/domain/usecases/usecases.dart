import 'package:pronosticosapp/features/weather/domain/entities/site.dart';
import 'package:pronosticosapp/features/weather/domain/entities/forecast_input.dart';
import 'package:pronosticosapp/features/weather/domain/entities/forecast_record.dart';
import 'package:pronosticosapp/features/weather/domain/repositories/weather_repository.dart';

class GetSites {
  final WeatherRepository repo;
  GetSites(this.repo);
  Future<List<Site>> call({int pageNumber = 1, int pageSize = 50, String? companyId}) {
    return repo.getSites(pageNumber: pageNumber, pageSize: pageSize, companyId: companyId);
  }
}

class GetForecastsBySite {
  final WeatherRepository repo;
  GetForecastsBySite(this.repo);
  Future<List<ForecastRecord>> call(String siteId) =>
      repo.getForecastsBySite(siteId);
}

class CreateForecast {
  final WeatherRepository repo;
  CreateForecast(this.repo);
  Future<ForecastRecord?> call(ForecastInput input) =>
      repo.createForecast(input);
}

class UpdateForecast {
  final WeatherRepository repo;
  UpdateForecast(this.repo);
  Future<bool> call(String id, ForecastInput input) =>
      repo.updateForecast(id, input);
}

class DeleteForecast {
  final WeatherRepository repo;
  DeleteForecast(this.repo);
  Future<bool> call(String id) => repo.deleteForecast(id);
}
