import 'package:flutter_test/flutter_test.dart';
import 'package:iassistente/services/app_config_diagnostics.dart';

void main() {
  test('production requires remote LLM config', () {
    final diagnostics = AppConfigDiagnostics.fromEnvironment({
      'APP_ENV': 'production',
      'LLM_PROXY_URL': '',
      'OPENAI_API_KEY': '',
      'ANTHROPIC_API_KEY': '',
      'GEMINI_API_KEY': '',
    });

    expect(diagnostics.hasErrors, isTrue);
    expect(diagnostics.errors.first, contains('Missing LLM configuration'));
  });

  test('development allows local-only setup with warning', () {
    final diagnostics = AppConfigDiagnostics.fromEnvironment({
      'APP_ENV': 'development',
      'LLM_PROXY_URL': '',
      'OPENAI_API_KEY': '',
      'ANTHROPIC_API_KEY': '',
      'GEMINI_API_KEY': '',
    });

    expect(diagnostics.hasErrors, isFalse);
    expect(diagnostics.hasWarnings, isTrue);
    expect(
      diagnostics.warnings.first,
      contains('No remote LLM configuration found'),
    );
  });

  test('production warns for localhost proxy', () {
    final diagnostics = AppConfigDiagnostics.fromEnvironment({
      'APP_ENV': 'production',
      'LLM_PROXY_URL': 'http://localhost:8787/v1/chat',
      'LLM_PROXY_PROVIDER': 'openai',
    });

    expect(diagnostics.hasErrors, isFalse);
    expect(
      diagnostics.warnings.any(
        (w) => w.contains('LLM_PROXY_URL points to localhost'),
      ),
      isTrue,
    );
  });

  test('production warns if direct keys are present but blocked', () {
    final diagnostics = AppConfigDiagnostics.fromEnvironment({
      'APP_ENV': 'production',
      'OPENAI_API_KEY': 'sk-test',
      'ALLOW_CLIENT_SIDE_LLM_IN_PRODUCTION': 'false',
    });

    expect(diagnostics.hasWarnings, isTrue);
    expect(
      diagnostics.warnings.any(
        (w) => w.contains('Direct provider API keys are present'),
      ),
      isTrue,
    );
  });
}
