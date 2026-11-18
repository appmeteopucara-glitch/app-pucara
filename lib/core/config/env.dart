import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static Future<void> load() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      try {
        await dotenv.load(fileName: 'assets/.env');
      } catch (_) {
        // Si no existe archivo .env, continuar con valores por defecto
      }
    }
  }

  static String get baseUrl => dotenv.env['BASE_URL'] ?? '';
}
