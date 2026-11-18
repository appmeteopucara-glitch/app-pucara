import 'package:pronosticosapp/features/auth/domain/entities/register_result.dart';
import 'package:pronosticosapp/features/auth/domain/repositories/auth_repository.dart';

class RegisterParams {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String confirmPassword;
  final String phoneNumber;
  RegisterParams({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.confirmPassword,
    this.phoneNumber = '',
  });
}

class RegisterUser {
  final AuthRepository repository;
  RegisterUser(this.repository);
  Future<RegisterResult> call(RegisterParams params) {
    return repository.register(
      firstName: params.firstName,
      lastName: params.lastName,
      email: params.email,
      password: params.password,
      confirmPassword: params.confirmPassword,
      phoneNumber: params.phoneNumber,
    );
  }
}
