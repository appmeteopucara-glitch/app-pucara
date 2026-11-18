import 'package:pronosticosapp/features/auth/domain/entities/login_result.dart';
import 'package:pronosticosapp/features/auth/domain/repositories/auth_repository.dart';

class LoginParams {
  final String email;
  final String password;
  LoginParams({required this.email, required this.password});
}

class LoginUser {
  final AuthRepository repository;
  LoginUser(this.repository);
  Future<LoginResult> call(LoginParams params) {
    return repository.login(email: params.email, password: params.password);
    }
}
