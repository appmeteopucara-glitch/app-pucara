import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pronosticosapp/features/weather/domain/entities/forecast_day.dart';
import 'package:pronosticosapp/features/weather/domain/entities/site.dart';
import 'package:pronosticosapp/features/weather/presentation/services/company_logos.dart';
import 'package:pronosticosapp/features/weather/presentation/services/forecast_pdf_service.dart';

Site _site(String id, String name, String company) => Site(
      id: id,
      companyId: 'c',
      companyName: company,
      name: name,
      address: '',
      latitude: 0,
      longitude: 0,
      isActive: true,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('genera un PDF con las faenas y sus pronósticos', () async {
    final today = DateTime.now();
    final base = DateTime(today.year, today.month, today.day);
    final sites = [
      _site('1', 'JOACHIM', 'Teniente'),
      _site('2', 'SEWELL', 'Teniente'),
      _site('3', 'ADIT 42', 'Teniente'),
      _site('4', 'LOS PELAMBRES', 'MLP'),
      _site('5', 'CARRIZALILLO', 'Caserones'),
      _site('6', 'MINA', 'Teck Quebrada Blanca'),
      _site('7', 'OTRA FAENA', 'Empresa sin logo'),
    ];
    final forecasts = <ForecastDay>[
      for (var i = 0; i < 7; i++)
        ForecastDay(
          id: i,
          siteId: '1',
          day: 'x',
          icon: i.isEven ? 'NIEVE_DIA_1' : 'LLUVIA_DEBIL',
          date: base.add(Duration(days: i)),
          min: -2.0 - i,
          max: 5.0 + i,
          isoMin: 2800,
          isoMax: 3600,
          electricProb: i == 0 ? null : 10,
          windIntensity: 25,
          gust: 50,
          windDirectionAM: 'N',
          windDirectionPM: 'NO',
          precipProb: 10 * i,
          snowCm: i == 3 ? 12 : null,
          waterMm: 1.5,
        ),
      for (var i = 1; i < 7; i++)
        ForecastDay(
          id: 100 + i,
          siteId: '2',
          day: 'x',
          icon: 'sunny',
          date: base.add(Duration(days: i)),
          precipProb: 30,
          waterMm: 2,
        ),
    ];

    final bytes = await ForecastPdfService().build(sites: sites, forecasts: forecasts);
    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes), isNot(contains('(1)')));
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    File('/tmp/pronosticos_prueba.pdf').writeAsBytesSync(bytes);
  });

  test('sin sitios genera un PDF válido', () async {
    final bytes = await ForecastPdfService().build(sites: [], forecasts: []);
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('cada empresa se asocia a su logo', () {
    expect(CompanyLogos.assetFor('Teniente'), endsWith('el_teniente.png'));
    expect(CompanyLogos.assetFor('Codelco División El Teniente'), endsWith('el_teniente.png'));
    expect(CompanyLogos.assetFor('MLP'), endsWith('los_pelambres.png'));
    expect(CompanyLogos.assetFor('Caserones'), endsWith('caserones.png'));
    expect(CompanyLogos.assetFor('Teck Quebrada Blanca'), endsWith('quebrada_blanca.png'));
    expect(CompanyLogos.assetFor('Otra'), isNull);
    expect(CompanyLogos.assetFor(null), isNull);
  });
}
