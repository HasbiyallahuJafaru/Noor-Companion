/// subscription_provider.dart — Riverpod state for the upgrade flow.
///
/// [UpgradeNotifier] drives the UpgradeScreen through three states:
///  - idle       → ready to start the flow
///  - loading    → fetching the redirect URL from the backend
///  - redirecting → URL obtained; WebView or Safari is open
///  - polling    → payment done (Android confirmed); polling /me for tier
///  - success    → subscriptionTier updated to 'paid'
///  - error      → something went wrong; message surfaced to the user
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/subscription_repository.dart';

// ── State ─────────────────────────────────────────────────────────────────────

sealed class UpgradeState {
  const UpgradeState();
}

class UpgradeIdle extends UpgradeState {
  const UpgradeIdle();
}

class UpgradeLoading extends UpgradeState {
  const UpgradeLoading();
}

/// Redirect URL is ready — the screen should open Safari or the WebView.
class UpgradeRedirecting extends UpgradeState {
  const UpgradeRedirecting(this.redirectUrl);
  final String redirectUrl;
}

/// iOS flow: Safari has closed and we are polling /me.
class UpgradePolling extends UpgradeState {
  const UpgradePolling();
}

class UpgradeSuccess extends UpgradeState {
  const UpgradeSuccess();
}

class UpgradeError extends UpgradeState {
  const UpgradeError(this.message);
  final String message;
}

// ── Providers ─────────────────────────────────────────────────────────────────

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository(ref.watch(apiClientProvider));
});

final upgradeNotifierProvider =
    NotifierProvider.autoDispose<UpgradeNotifier, UpgradeState>(
  UpgradeNotifier.new,
);

// ── Notifier ──────────────────────────────────────────────────────────────────

/// Drives the subscription upgrade flow for both iOS (Safari) and Android (WebView).
class UpgradeNotifier extends Notifier<UpgradeState> {
  @override
  UpgradeState build() => const UpgradeIdle();

  SubscriptionRepository get _repo => ref.read(subscriptionRepositoryProvider);

  /// Fetches the signed redirect URL from the backend.
  /// On success, transitions to [UpgradeRedirecting] so the screen can launch Safari/WebView.
  Future<void> fetchRedirectUrl() async {
    if (state is UpgradeLoading) return;
    state = const UpgradeLoading();

    try {
      final url = await _repo.fetchSubscribeRedirectUrl();
      state = UpgradeRedirecting(url);
    } on DioException catch (e) {
      final msg = e.response?.data?['error']?['message'] as String? ??
          'Could not start payment. Please try again.';
      state = UpgradeError(msg);
    } catch (_) {
      state = const UpgradeError('Something went wrong. Please try again.');
    }
  }

  /// Called by the iOS flow after Safari returns to the app.
  /// Polls GET /users/me up to 5 times to confirm tier update.
  /// On success, refreshes the global auth state so the paid badge appears.
  Future<void> pollAfterSafariReturn() async {
    state = const UpgradePolling();

    final updated = await _repo.pollForPaidTier();

    if (updated != null && updated.isPaid) {
      ref.read(authProvider.notifier).refresh();
      state = const UpgradeSuccess();
    } else {
      state = const UpgradeError(
        'Payment not confirmed yet. If you completed payment, '
        'please wait a moment and check your profile.',
      );
    }
  }

  /// Called by the Android WebView flow once the success URL is intercepted.
  /// Refreshes auth state and transitions to success immediately.
  Future<void> onAndroidPaymentSuccess() async {
    ref.read(authProvider.notifier).refresh();
    state = const UpgradeSuccess();
  }

  /// Resets the state so the user can retry after an error.
  void reset() => state = const UpgradeIdle();
}
