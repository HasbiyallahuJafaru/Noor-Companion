/// Dio HTTP client for all Noor Companion backend API calls.
/// The AuthInterceptor automatically injects the current Supabase access token.
/// A 401 response from the backend triggers sign-out (account suspended case).
library;

import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

/// Injects the Supabase access token into every outgoing request.
/// supabase_flutter handles token refresh automatically before this runs.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._supabase);

  final SupabaseClient _supabase;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      options.headers['Authorization'] = 'Bearer ${session.accessToken}';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // 401 means account suspended or token unrecoverable — sign out.
      _supabase.auth.signOut();
    }
    handler.next(err);
  }
}

/// Creates the configured Dio instance.
/// Inject via [apiClientProvider] — do not construct directly.
Dio buildApiClient(SupabaseClient supabase) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(AuthInterceptor(supabase));

  return dio;
}
