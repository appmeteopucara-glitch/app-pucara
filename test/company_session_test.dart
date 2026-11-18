import 'package:flutter_test/flutter_test.dart';
import 'package:pronosticosapp/core/routes/app_routes.dart';
import 'package:pronosticosapp/core/storage/company_session.dart';
import 'package:pronosticosapp/core/storage/token_storage.dart';
import 'package:pronosticosapp/features/auth/domain/entities/user_company.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _c(String id, String name) => {'id': id, 'name': name};

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('sin empresas va al home (que explica la falta de asignación)', () async {
    await CompanySession.saveFromLogin([]);
    expect(await CompanySession.nextRoute(), AppRoutes.home);
    expect(await CompanySession.companyCount(), 0);
  });

  test('con una sola empresa se elige sola y salta el selector', () async {
    await CompanySession.saveFromLogin([_c('a', 'MLP')]);
    expect(await TokenStorage.getSelectedCompanyId(), 'a');
    expect(await CompanySession.nextRoute(), AppRoutes.home);
    expect(await CompanySession.selectedCompanyName(), 'MLP');
  });

  test('con varias empresas y ninguna elegida muestra el selector', () async {
    await CompanySession.saveFromLogin([_c('a', 'MLP'), _c('b', 'Teniente')]);
    expect(await TokenStorage.getSelectedCompanyId(), isNull);
    expect(await CompanySession.nextRoute(), AppRoutes.selectCompany);
  });

  test('con varias empresas y una elegida va al home', () async {
    await CompanySession.saveFromLogin([_c('a', 'MLP'), _c('b', 'Teniente')]);
    await TokenStorage.saveSelectedCompanyId('b');
    expect(await CompanySession.nextRoute(), AppRoutes.home);
    expect(await CompanySession.selectedCompanyName(), 'Teniente');
  });

  test('si la empresa elegida ya no está entre las del usuario, se descarta', () async {
    await TokenStorage.saveSelectedCompanyId('vieja');
    await CompanySession.saveFromLogin([_c('a', 'MLP'), _c('b', 'Teniente')]);
    expect(await TokenStorage.getSelectedCompanyId(), isNull);
    expect(await CompanySession.nextRoute(), AppRoutes.selectCompany);
  });

  test('cerrar sesión borra empresas y elección', () async {
    await CompanySession.saveFromLogin([_c('a', 'MLP')]);
    await TokenStorage.clear();
    expect(await TokenStorage.getCompanies(), isEmpty);
    expect(await TokenStorage.getSelectedCompanyId(), isNull);
  });

  test('UserCompany lee id y name del login', () {
    final c = UserCompany.fromJson({'id': 'x', 'name': 'MLP'});
    expect(c.id, 'x');
    expect(c.name, 'MLP');
  });
}
