import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TokenStorage {
  static const _kToken = 'auth_token';
  static const _kExpiry = 'auth_token_expiry';
  static const _kRoles = 'auth_roles';
  static const _kCompanies = 'auth_companies';
  static const _kSelectedCompany = 'selected_company_id';

  static Future<void> saveToken(String token, {DateTime? expiresAtUtc}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, token);
    if (expiresAtUtc != null) {
      await prefs.setString(_kExpiry, expiresAtUtc.toIso8601String());
    }
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kToken);
  }

  static Future<DateTime?> getExpiry() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_kExpiry);
    if (s == null || s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kExpiry);
    await prefs.remove(_kRoles);
    await prefs.remove(_kCompanies);
    await prefs.remove(_kSelectedCompany);
  }

  static Future<void> saveRoles(List<String> roles) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kRoles, json.encode(roles));
  }

  static Future<List<String>> getRoles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kRoles);
    if (raw == null || raw.isEmpty) return <String>[];
    try {
      final list = json.decode(raw);
      if (list is List) {
        return list.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return <String>[];
  }

  static Future<bool> isMeteorologist() async {
    final roles = await getRoles();
    return roles.map((e) => e.toUpperCase()).contains('METEOROLOGIST');
  }
  
  static Future<bool> isUserRead() async {
    final roles = await getRoles();
    return roles.map((e) => e.toUpperCase()).contains('USER_READ');
  }

  static Future<bool> canImportForecasts() async {
    final roles = (await getRoles()).map((e) => e.toUpperCase()).toSet();
    return roles.contains('METEOROLOGIST') || roles.contains('USER_READ');
  }

  /// Empresas del usuario (`companies[]` del login) como lista de {id, name}.
  static Future<void> saveCompanies(List<Map<String, dynamic>> companies) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCompanies, json.encode(companies));
  }

  static Future<List<Map<String, dynamic>>> getCompanies() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kCompanies);
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
    try {
      final list = json.decode(raw);
      if (list is List) {
        return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return <Map<String, dynamic>>[];
  }

  static Future<void> saveSelectedCompanyId(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null || id.isEmpty) {
      await prefs.remove(_kSelectedCompany);
    } else {
      await prefs.setString(_kSelectedCompany, id);
    }
  }

  static Future<String?> getSelectedCompanyId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_kSelectedCompany);
    return (id == null || id.isEmpty) ? null : id;
  }
}
