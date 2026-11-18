import 'package:flutter_test/flutter_test.dart';
import 'package:pronosticosapp/features/weather/domain/site_variables.dart';

void main() {
  test('normaliza nombres de faenas', () {
    expect(SiteVariables.normalize('Mina - Plantas'), 'mina plantas');
    expect(SiteVariables.normalize(' JOACHIM '), 'joachim');
  });

  test('Joachim: sin altura de isoterma ni humedad (según el Excel)', () {
    final v = SiteVariables.forSiteName('JOACHIM')!;
    expect(v.contains(ForecastVar.isoMinMax), isTrue);
    expect(v.contains(ForecastVar.isoHeight), isFalse);
    expect(v.contains(ForecastVar.humidity), isFalse);
  });

  test('Adit 42 y Sewell solo llevan precipitación, agua y nieve', () {
    const expected = {ForecastVar.precip, ForecastVar.water, ForecastVar.snow};
    expect(SiteVariables.forSiteName('Adit 42'), expected);
    expect(SiteVariables.forSiteName('SEWELL'), expected);
  });

  test('acepta nombres con texto extra', () {
    expect(SiteVariables.forSiteName('ADIT 42 - Teniente'), SiteVariables.forSiteName('Adit 42'));
  });

  test('Mina de Caserones y Mina de Quebrada Blanca se distinguen', () {
    expect(SiteVariables.forSiteName('Mina - Plantas', company: 'Caserones')!.contains(ForecastVar.isoHeight), isFalse);
    expect(SiteVariables.forSiteName('Mina', company: 'Teck Quebrada Blanca')!.contains(ForecastVar.isoHeight), isTrue);
    expect(SiteVariables.forSiteName('Mina', company: 'Otra empresa'), isNull);
  });

  test('faena fuera del listado devuelve null (se muestran todas)', () {
    expect(SiteVariables.forSiteName('Otra faena'), isNull);
    expect(SiteVariables.forSiteName(null), isNull);
  });

  test('tolera errores de tipeo en el nombre', () {
    const expected = {ForecastVar.precip, ForecastVar.water, ForecastVar.snow};
    expect(SiteVariables.forSiteName('Sewel'), expected);
    expect(SiteVariables.forSiteName('SEWE'), expected);
    expect(SiteVariables.forSiteName('Aditt 42'), expected);
    expect(SiteVariables.forSiteName('Pampa norte'), isNotNull);
  });

  test('cada faena del Excel resuelve a su propia configuración', () {
    for (final name in [
      'Joachim', 'Adit 42', 'Sewell', 'Los Pelambres', 'El Chacay', 'El Mauro',
      'Punta Chungo', 'Mina - Plantas', 'Planta Piloto - Muro', 'Carrizalillo',
      'Variante A97B', 'Pampa', 'Puerto',
    ]) {
      expect(SiteVariables.forSiteName(name), isNotNull, reason: name);
    }
  });
}
