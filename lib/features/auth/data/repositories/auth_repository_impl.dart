import 'package:pronosticosapp/features/auth/domain/entities/register_result.dart';
import 'package:pronosticosapp/features/auth/domain/repositories/auth_repository.dart';
import 'package:pronosticosapp/features/auth/data/datasource/auth_remote_data_source.dart';
import 'package:pronosticosapp/features/auth/data/models/register_request.dart';
import 'package:pronosticosapp/features/auth/domain/entities/login_result.dart';
import 'package:pronosticosapp/features/auth/domain/entities/delete_account_result.dart';
import 'package:pronosticosapp/features/auth/data/models/login_request.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remote;
  AuthRepositoryImpl(this.remote);

  @override
  Future<RegisterResult> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String confirmPassword,
    String phoneNumber = '',
  }) {
    final req = RegisterRequest(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
      phoneNumber: phoneNumber,
    );
    return remote.register(req);
  }

  @override
  Future<LoginResult> login({required String email, required String password}) {
    final req = LoginRequest(email: email, password: password);
    return remote.login(req);
  }

  @override
  Future<DeleteAccountResult> deleteAccount({required String password}) {
    return remote.deleteAccount(password);
  }
}
