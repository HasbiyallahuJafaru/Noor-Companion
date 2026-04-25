/// Compile-time application configuration.
/// All values injected via --dart-define at build time.
/// Never hardcode secrets or production URLs in this file.
library;

abstract final class AppConfig {
  /// Base URL for the Noor Companion backend API.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api/v1',
  );

  /// Supabase project URL.
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// Supabase anon/public key — safe to embed in the client.
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Agora App ID for RTC audio calling.
  static const String agoraAppId = String.fromEnvironment('AGORA_APP_ID');

  /// Sentry DSN for error reporting.
  static const String sentryDsn = String.fromEnvironment('SENTRY_DSN');

  /// Deployment environment: development | staging | production.
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  /// Netlify website URL — used for iOS payment redirect.
  static const String websiteUrl = String.fromEnvironment(
    'WEBSITE_URL',
    defaultValue: 'https://noorcompanion.netlify.app',
  );

  /// Returns true when running in development mode.
  static bool get isDevelopment => environment == 'development';
}
