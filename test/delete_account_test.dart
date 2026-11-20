import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pronosticosapp/core/network/api_client.dart';
import 'package:pronosticosapp/features/auth/data/datasource/auth_remote_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

AuthRemoteDataSource _build(http.Response Function(http.Request) handler) {
  final api = ApiClient(
    baseUrl: 'https://api.test',
    client: MockClient((req) async => handler(req)),
  );
  return AuthRemoteDataSource(
    apiClient: api,
    registerEndpoint: '/api/auth/register-meteorologist',
    loginEndpoint: '/api/auth/login',
    deleteAccountEndpoint: '/api/auth/delete-account',
  );
}

http.Response _json(int status, Map<String, dynamic> body) =>
    http.Response(json.encode(body), status, headers: {'content-type': 'application/json'});

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'auth_token': 'tok123'});
  });

  test('200 elimina la cuenta y envía token y contraseña', () async {
    late http.Request captured;
    final ds = _build((req) {
      captured = req;
      return _json(200, {'success': true, 'message': 'Account deleted'});
    });
    final r = await ds.deleteAccount('secreta');
    expect(r.success, isTrue);
    expect(captured.url.path, '/api/auth/delete-account');
    expect(captured.headers['Authorization'], 'Bearer tok123');
    expect(json.decode(captured.body), {'password': 'secreta'});
  });

  test('400 muestra errors[0] y no marca la sesión como expirada', () async {
    final ds = _build((_) => _json(400, {
          'success': false,
          'message': '...',
          'errors': ['La contraseña es incorrecta'],
        }));
    final r = await ds.deleteAccount('mala');
    expect(r.success, isFalse);
    expect(r.statusCode, 400);
    expect(r.sessionExpired, isFalse);
    expect(r.message, 'La contraseña es incorrecta');
  });

  test('403 muestra el mensaje del servidor', () async {
    final ds = _build((_) => _json(403, {
          'success': false,
          'message': 'No se puede eliminar al último administrador global activo',
        }));
    final r = await ds.deleteAccount('x');
    expect(r.success, isFalse);
    expect(r.sessionExpired, isFalse);
    expect(r.message, 'No se puede eliminar al último administrador global activo');
  });

  test('401 sin body y 404 se tratan como sesión expirada', () async {
    for (final status in [401, 404]) {
      final ds = _build((_) => http.Response('', status));
      final r = await ds.deleteAccount('x');
      expect(r.success, isFalse);
      expect(r.sessionExpired, isTrue);
    }
  });

  test('500 muestra un mensaje genérico', () async {
    final ds = _build((_) => _json(500, {'message': 'detalle interno'}));
    final r = await ds.deleteAccount('x');
    expect(r.success, isFalse);
    expect(r.message, 'No se pudo eliminar la cuenta. Intenta nuevamente');
  });
}
