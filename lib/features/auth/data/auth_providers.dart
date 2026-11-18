import 'package:pronosticosapp/core/config/env.dart';
import 'package:pronosticosapp/core/network/api_client.dart';
import 'package:pronosticosapp/features/auth/data/datasource/auth_remote_data_source.dart';
import 'package:pronosticosapp/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:pronosticosapp/features/auth/domain/repositories/auth_repository.dart';

AuthRepository buildAuthRepository() {
  final api = ApiClient(baseUrl: Env.baseUrl);
  final ds = AuthRemoteDataSource(
    apiClient: api,
    registerEndpoint: '/api/auth/register-meteorologist',
    loginEndpoint: '/api/auth/login',
  );
  return AuthRepositoryImpl(ds);
}
