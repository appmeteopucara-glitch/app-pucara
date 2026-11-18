import 'package:flutter_test/flutter_test.dart';
import 'package:pronosticosapp/core/theme/weather_icon_catalog.dart';
import 'package:pronosticosapp/core/utils/forecast_format.dart';
import 'package:pronosticosapp/features/weather/data/models/forecast_models.dart';
import 'package:pronosticosapp/features/weather/domain/entities/forecast_input.dart';

void main() {
  group('ForecastModel (API v1)', () {
    test('null se conserva como null y no se convierte en 0', () {
      final r = ForecastModel.fromJson({
        'id': 'a',
        'siteId': 's',
        'forecastDate': '2026-10-12T00:00:00',
        'temperatureMinC': null,
        'precipitationProbabilityPercent': null,
        'snowAccumulationCm': null,
        'windDirectionAm': null,
      }).toEntity();
      expect(r.temperatureMinC, isNull);
      expect(r.precipitationProbabilityPercent, isNull);
      expect(r.snowAccumulationCm, isNull);
      expect(r.windDirectionAm, isNull);
    });

    test('lee decimales, enteros y las variables nuevas', () {
      final r = ForecastModel.fromJson({
        'id': 'a',
        'siteId': 's',
        'forecastDate': '2026-10-12T00:00:00',
        'temperatureMinC': 3.0,
        'isothermMinMsnm': 2800,
        'isothermHeightMeters': 3450,
        'waterAccumulationMm': 20.5,
        'relativeHumidityPercent': 88,
        'weatherIcon': 'rain',
      }).toEntity();
      expect(r.temperatureMinC, 3.0);
      expect(r.isothermMinMsnm, 2800);
      expect(r.isothermHeightMeters, 3450);
      expect(r.waterAccumulationMm, 20.5);
      expect(r.relativeHumidityPercent, 88);
      expect(r.weatherIcon, 'rain');
      expect(r.forecastDate, DateTime(2026, 10, 12));
    });

    test('acepta claves en PascalCase', () {
      final r = ForecastModel.fromJson({
        'Id': 'a',
        'SiteId': 's',
        'ForecastDate': '2026-10-12T00:00:00',
        'TemperatureMaxC': 15,
      }).toEntity();
      expect(r.siteId, 's');
      expect(r.temperatureMaxC, 15);
    });

    test('pronóstico antiguo: campos de solo lectura', () {
      final r = ForecastModel.fromJson({
        'id': 'a',
        'siteId': 's',
        'forecastDate': '2026-10-12T00:00:00',
        'rainProbabilityPercent': 60,
        'stormProbabilityPercent': 20,
        'minIsothermLevelMeters': 2800,
      }).toEntity();
      expect(r.precipitationProbabilityPercent, isNull);
      expect(r.rainProbabilityPercent, 60);
      expect(r.stormProbabilityPercent, 20);
      expect(r.minIsothermLevelMeters, 2800);
    });
  });

  group('ForecastInput', () {
    final input = ForecastInput(
      siteId: 'site-1',
      forecastDate: DateTime(2026, 10, 7, 15, 30),
      temperatureMinC: 2.5,
    );

    test('la fecha viaja como día local sin zona', () {
      expect(input.toJson()['forecastDate'], '2026-10-07T00:00:00');
    });

    test('el POST lleva siteId y las variables vacías van en null', () {
      final json = input.toJson();
      expect(json['siteId'], 'site-1');
      expect(json['temperatureMinC'], 2.5);
      expect(json['temperatureMaxC'], isNull);
      expect(json.containsKey('temperatureMaxC'), isTrue);
    });

    test('la isoterma viaja como entero en msnm, sin decimales ni nombres viejos', () {
      final json = ForecastInput(
        siteId: 's',
        forecastDate: DateTime(2026, 11, 10),
        isothermMinMsnm: 2800,
        isothermMaxMsnm: 3400,
        isothermHeightMeters: 3200,
      ).toJson();
      expect(json['isothermMinMsnm'], 2800);
      expect(json['isothermMaxMsnm'], 3400);
      expect(json['isothermMinMsnm'], isA<int>());
      expect(json['isothermHeightMeters'], 3200);
      expect(json.containsKey('isothermMinC'), isFalse);
      expect(json.containsKey('isothermMaxC'), isFalse);
    });

    test('un pronóstico antiguo sin isoterma en msnm se lee como null', () {
      final r = ForecastModel.fromJson({
        'id': 'a',
        'siteId': 's',
        'forecastDate': '2026-10-12T00:00:00',
        'isothermMinMsnm': null,
        'isothermMaxMsnm': null,
      }).toEntity();
      expect(r.isothermMinMsnm, isNull);
      expect(r.isothermMaxMsnm, isNull);
    });

    test('el PUT no lleva siteId', () {
      expect(input.toJson(includeSiteId: false).containsKey('siteId'), isFalse);
    });
  });

  group('WeatherIconCatalog', () {
    test('hay 52 íconos y cada clave es única', () {
      expect(WeatherIconCatalog.options.length, 52);
      expect(WeatherIconCatalog.options.map((o) => o.key).toSet().length, 52);
    });

    test('claves antiguas y valores de weatherIcon del backend', () {
      expect(WeatherIconCatalog.resolve('sunny'), 'DESPEJADO_DIA');
      expect(WeatherIconCatalog.resolve('rainy'), 'LLUVIA_DEBIL');
      expect(WeatherIconCatalog.resolve('storm'), 'ELECTRICA_DIA_2');
      expect(WeatherIconCatalog.resolve('partly_cloudy'), 'PARCIAL_DIA');
      expect(WeatherIconCatalog.resolve('desconocido'), isNull);
      expect(WeatherIconCatalog.resolve(null), isNull);
    });

    test('fromSummary lee la clave al inicio del resumen', () {
      expect(WeatherIconCatalog.fromSummary('NUBLADO_DIA'), 'NUBLADO_DIA');
      expect(WeatherIconCatalog.fromSummary('nublado_dia, viento fuerte'), 'NUBLADO_DIA');
      expect(WeatherIconCatalog.fromSummary('Lluvia sin nieve.'), isNull);
    });
  });

  group('formato de variables opcionales', () {
    test('null muestra placeholder, no 0', () {
      expect(fmtNum(null, '%'), kNoData);
      expect(fmtRange(null, null, '°C'), kNoData);
      expect(fmtText(null), kNoData);
    });

    test('enteros sin decimales y decimales con uno', () {
      expect(fmtNum(15.0, '°C'), '15 °C');
      expect(fmtNum(2.5, 'mm'), '2.5 mm');
      expect(fmtRange(-2, 5, '°C'), '-2 / 5 °C');
      expect(fmtRange(-2, null, '°C'), '-2 / — °C');
    });
  });
}
