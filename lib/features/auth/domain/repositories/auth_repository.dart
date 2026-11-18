import 'package:pronosticosapp/features/auth/domain/entities/register_result.dart';
import 'package:pronosticosapp/features/auth/domain/entities/login_result.dart';

abstract class AuthRepository {
  Future<RegisterResult> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String confirmPassword,
    String phoneNumber,
  });
  Future<LoginResult> login({
    required String email,
    required String password,
  });
}
