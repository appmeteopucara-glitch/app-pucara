import 'package:pronosticosapp/features/auth/domain/entities/user_company.dart';

class LoginResult {
  final bool success;
  final String message;
  final String token;
  final DateTime? expiresAtUtc;
  final int? statusCode;
  final List<String> roles;
  final List<UserCompany> companies;
  LoginResult({
    required this.success,
    this.message = '',
    this.token = '',
    this.expiresAtUtc,
    this.statusCode,
    this.roles = const [],
    this.companies = const [],
  });
}
