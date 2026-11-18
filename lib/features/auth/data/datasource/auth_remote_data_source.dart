import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:pronosticosapp/core/network/api_client.dart';
import 'package:pronosticosapp/features/auth/domain/entities/register_result.dart';
import 'package:pronosticosapp/features/auth/domain/entities/login_result.dart';
import 'package:pronosticosapp/features/auth/domain/entities/user_company.dart';
import 'package:pronosticosapp/features/auth/data/models/register_request.dart';
import 'package:pronosticosapp/features/auth/data/models/login_request.dart';

class AuthRemoteDataSource {
  final ApiClient apiClient;
  final String registerEndpoint;
  final String loginEndpoint;

  AuthRemoteDataSource({
    required this.apiClient,
    required this.registerEndpoint,
    required this.loginEndpoint,
  });

  Future<RegisterResult> register(RegisterRequest request) async {
    final res = await apiClient.post(registerEndpoint, body: request.toJson());
    try {
      debugPrint('[AuthRemoteDataSource] register response: $res');
    } catch (_) {}
    if (res is Map<String, dynamic>) {
      final success = res['success'] == true;
      final message = res['message']?.toString() ?? (success ? 'Registro exitoso' : 'Error en el registro');
      return RegisterResult(success: success, message: message);
    }
    return RegisterResult(success: false, message: 'Respuesta desconocida del servidor');
  }

  Future<LoginResult> login(LoginRequest request) async {
    try {
      final res = await apiClient.post(loginEndpoint, body: request.toJson());
      debugPrint('[AuthRemoteDataSource] login response: $res');
      if (res is Map<String, dynamic>) {
        final success = res['success'] == true || res['Success'] == true;
        final message = (res['message'] ?? res['Message'] ?? '').toString();
        String token = '';
        DateTime? exp;
        List<String> roles = const [];
        List<UserCompany> companies = const [];
        if (res['data'] != null) {
          final data = res['data'] as Map<String, dynamic>;
          token = (data['token'] ?? '').toString();
          final expStr = data['expiresAtUtc']?.toString();
          if (expStr != null && expStr.isNotEmpty) {
            exp = DateTime.tryParse(expStr);
          }
          final user = data['user'];
          if (user is Map<String, dynamic> && user['roles'] is List) {
            roles = (user['roles'] as List).map((e) => e.toString()).toList();
          }
          // `companies[]` reemplaza a `companyId` (deprecado). Para GLOBAL_ADMIN llegan todas las activas.
          if (user is Map<String, dynamic> && user['companies'] is List) {
            companies = (user['companies'] as List)
                .whereType<Map<String, dynamic>>()
                .map(UserCompany.fromJson)
                .where((c) => c.id.isNotEmpty)
                .toList();
          }
        }
        return LoginResult(success: success, message: message, token: token, expiresAtUtc: exp, statusCode: 200, roles: roles, companies: companies);
      }
      return LoginResult(success: false, message: 'Respuesta desconocida del servidor', statusCode: null);
    } on ApiException catch (e) {
      debugPrint('[AuthRemoteDataSource] login ApiException ${e.statusCode} ${e.message}');
      if (e.statusCode == 401) {
        return LoginResult(success: false, message: 'Credenciales inválidas', token: '', statusCode: 401, roles: const []);
      }
      if (e.statusCode == 403) {
        String msg = 'Usuario no activo o no aprobado';
        try {
          final body = e.message;
          if (body.isNotEmpty) {
            final map = body.startsWith('{') ? (json.decode(body) as Map<String, dynamic>) : <String, dynamic>{};
            if (map.isNotEmpty) {
              final m = (map['Message'] ?? map['message'] ?? '').toString();
              if (m.isNotEmpty) msg = m;
            }
          }
        } catch (_) {}
        return LoginResult(success: false, message: msg, token: '', statusCode: 403, roles: const []);
      }
      return LoginResult(success: false, message: 'Error ${e.statusCode}', token: '', statusCode: e.statusCode, roles: const []);
    } catch (e) {
      debugPrint('[AuthRemoteDataSource] login error: $e');
      return LoginResult(success: false, message: 'Error de red', token: '', statusCode: null, roles: const []);
    }
  }
}
