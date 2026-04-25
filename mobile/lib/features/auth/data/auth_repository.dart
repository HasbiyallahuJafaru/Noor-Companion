/// Auth repository — the single data-access layer for auth-related API calls.
/// Uses the Dio client for backend calls. Supabase Auth methods called directly
/// from the auth provider, not here.
library;

import 'package:dio/dio.dart';
import '../domain/models/user_model.dart';

class AuthRepository {
  const AuthRepository(this._dio);

  final Dio _dio;

  /// Fetches the authenticated user's profile from GET /api/v1/users/me.
  /// Called after every successful Supabase sign-in to load app-specific data.
  ///
  /// Returns [UserModel] on success.
  /// Throws [DioException] on network or auth failure.
  Future<UserModel> getMe() async {
    final response = await _dio.get('/users/me');
    final data = (response.data as Map<String, dynamic>)['data'];
    return UserModel.fromJson(data as Map<String, dynamic>);
  }

  /// Registers the device FCM token with the backend.
  /// Call on login and whenever firebase_messaging refreshes the token.
  Future<void> saveFcmToken(String fcmToken) async {
    await _dio.post('/users/me/fcm-token', data: {'fcmToken': fcmToken});
  }
}
