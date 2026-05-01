/// Auth state management using Riverpod 3.x Notifier pattern.
/// Listens to Supabase's auth state stream for reactive session changes.
/// Login, register, and logout delegate to Supabase Auth directly.
library;

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../../../../core/network/api_client.dart';
import '../../data/auth_repository.dart';
import '../../domain/models/user_model.dart';

// ── Auth state ────────────────────────────────────────────────────────────────

sealed class AppAuthState {
  const AppAuthState();
}

class AuthLoading extends AppAuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AppAuthState {
  const AuthAuthenticated(this.user);
  final UserModel user;
}

class AuthUnauthenticated extends AppAuthState {
  const AuthUnauthenticated();
}

class AuthError extends AppAuthState {
  const AuthError(this.message);
  final String message;
}

/// Emitted after signUp() when Supabase requires email confirmation.
/// The user must verify their email before they can sign in.
class AuthAwaitingConfirmation extends AppAuthState {
  const AuthAwaitingConfirmation(this.email);
  final String email;
}

// ── Providers ─────────────────────────────────────────────────────────────────

final supabaseClientProvider = Provider<SupabaseClient>((_) {
  return Supabase.instance.client;
});

final apiClientProvider = Provider<Dio>((ref) {
  return buildApiClient(ref.watch(supabaseClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});

final authProvider = NotifierProvider<AuthNotifier, AppAuthState>(
  AuthNotifier.new,
);

// ── Notifier ──────────────────────────────────────────────────────────────────

class AuthNotifier extends Notifier<AppAuthState> {
  StreamSubscription<AuthState>? _authSub;

  @override
  AppAuthState build() {
    final supabase = ref.read(supabaseClientProvider);

    // Subscribe to Supabase auth state changes for the full app lifecycle.
    _authSub = supabase.auth.onAuthStateChange.listen((data) {
      if (data.session != null) {
        _loadUser();
      } else {
        state = const AuthUnauthenticated();
      }
    });

    ref.onDispose(() => _authSub?.cancel());

    // Check for an existing session synchronously on first build.
    final existing = supabase.auth.currentSession;
    if (existing != null) {
      Future.microtask(_loadUser);
      return const AuthLoading();
    }
    return const AuthUnauthenticated();
  }

  /// Loads our app User record from the backend.
  /// Called after every successful Supabase sign-in.
  Future<void> _loadUser() async {
    state = const AuthLoading();
    try {
      final user = await ref.read(authRepositoryProvider).getMe();
      state = AuthAuthenticated(user);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  /// Registers a new account via Supabase Auth.
  /// Metadata (firstName, lastName, role) is stored in user_metadata.
  /// The auth stream fires on success — [_loadUser] is called automatically.
  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String role = 'user',
  }) async {
    state = const AuthLoading();
    try {
      final supabase = ref.read(supabaseClientProvider);
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'role': role,
        },
      );
      // If session is null, Supabase requires email confirmation before login.
      // Emit a specific state so the UI can show a confirmation message instead
      // of leaving the spinner running indefinitely.
      if (response.session == null) {
        state = AuthAwaitingConfirmation(email);
      }
      // If session is not null, the auth stream fires and _loadUser() handles it.
    } on AuthException catch (e) {
      state = AuthError(e.message);
    } catch (e) {
      state = AuthError('Registration failed. Please try again.');
    }
  }

  /// Signs in an existing user via Supabase Auth.
  /// The auth stream fires on success — [_loadUser] is called automatically.
  Future<void> login(String email, String password) async {
    state = const AuthLoading();
    try {
      final supabase = ref.read(supabaseClientProvider);
      await supabase.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      state = AuthError(e.message);
    } catch (e) {
      state = AuthError('Login failed. Please try again.');
    }
  }

  /// Signs out the current user and clears the Supabase session.
  Future<void> logout() async {
    await ref.read(supabaseClientProvider).auth.signOut();
  }

  /// Refreshes the current user record from the backend.
  /// Used after subscription upgrade to reflect the new tier immediately.
  Future<void> refresh() => _loadUser();

  /// Sends a password reset email via Supabase Auth.
  Future<void> resetPassword(String email) async {
    try {
      final supabase = ref.read(supabaseClientProvider);
      await supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      state = AuthError(e.message);
    } catch (e) {
      state = AuthError('Could not send reset email. Please try again.');
    }
  }

  /// Clears an error or confirmation state back to unauthenticated.
  void clearError() {
    if (state is AuthError || state is AuthAwaitingConfirmation) {
      state = const AuthUnauthenticated();
    }
  }
}
