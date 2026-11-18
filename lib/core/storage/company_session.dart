import 'package:flutter/foundation.dart';
import 'package:pronosticosapp/core/config/env.dart';
import 'package:pronosticosapp/core/network/api_client.dart';
import 'package:pronosticosapp/core/routes/app_routes.dart';
import 'package:pronosticosapp/core/storage/token_storage.dart';

/// Empresa con la que trabaja el usuario cuando tiene acceso a varias.
class CompanySession {
  /// Guarda las empresas del login. Si la empresa elegida antes ya no está
  /// entre ellas, se descarta; con una sola empresa se elige sola.
  static Future<void> saveFromLogin(List<Map<String, dynamic>> companies) async {
    await TokenStorage.saveCompanies(companies);
    final ids = companies.map((c) => c['id'].toString()).toSet();
    final selected = await TokenStorage.getSelectedCompanyId();
    if (companies.length == 1) {
      await TokenStorage.saveSelectedCompanyId(companies.first['id'].toString());
    } else if (selected == null || !ids.contains(selected)) {
      await TokenStorage.saveSelectedCompanyId(null);
    }
  }

  /// Vuelve a pedir las empresas con `GET /api/auth/me`. Sirve para sesiones
  /// iniciadas antes de este cambio (sin empresas guardadas) y para reflejar
  /// asignaciones nuevas sin obligar a cerrar sesión. Si falla, se usan las guardadas.
  static Future<void> refreshFromServer() async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null || token.isEmpty) return;
      final res = await ApiClient(baseUrl: Env.baseUrl).get(
        '/api/auth/me',
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res is! Map<String, dynamic>) return;
      final data = res['data'] ?? res['Data'];
      if (data is! Map<String, dynamic>) return;
      final user = data['user'] is Map<String, dynamic> ? data['user'] as Map<String, dynamic> : data;
      final raw = user['companies'] ?? user['Companies'];
      if (raw is! List) return;
      final companies = raw
          .whereType<Map>()
          .map((c) => {'id': (c['id'] ?? c['Id'] ?? '').toString(), 'name': (c['name'] ?? c['Name'] ?? '').toString()})
          .where((c) => c['id']!.isNotEmpty)
          .toList();
      await saveFromLogin(companies);
      debugPrint('[CompanySession] empresas del usuario: ${companies.map((c) => c['name']).join(', ')}');
    } catch (e) {
      debugPrint('[CompanySession] no se pudieron refrescar las empresas: $e');
    }
  }

  /// Ruta siguiente: el selector si hay varias empresas y ninguna elegida;
  /// si no, el home (con 0 empresas el home explica que falta asignación).
  static Future<String> nextRoute() async {
    final companies = await TokenStorage.getCompanies();
    if (companies.length <= 1) return AppRoutes.home;
    final selected = await TokenStorage.getSelectedCompanyId();
    final ids = companies.map((c) => c['id'].toString()).toSet();
    return (selected != null && ids.contains(selected))
        ? AppRoutes.home
        : AppRoutes.selectCompany;
  }

  static Future<int> companyCount() async => (await TokenStorage.getCompanies()).length;

  static Future<String?> selectedCompanyName() async {
    final id = await TokenStorage.getSelectedCompanyId();
    if (id == null) return null;
    for (final c in await TokenStorage.getCompanies()) {
      if (c['id'].toString() == id) return c['name']?.toString();
    }
    return null;
  }
}
