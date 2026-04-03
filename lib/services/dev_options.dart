import 'package:flutter_dotenv/flutter_dotenv.dart';

class DevOptions {
  const DevOptions._();

  static bool get authBypassEnabled {
    final appEnv = (dotenv.env['APP_ENV'] ?? 'development')
        .trim()
        .toLowerCase();
    final raw = (dotenv.env['DEV_BYPASS_AUTH'] ?? '').trim().toLowerCase();
    return appEnv != 'production' && raw == 'true';
  }
}
