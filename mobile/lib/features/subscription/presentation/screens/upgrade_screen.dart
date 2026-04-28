/// upgrade_screen.dart — Noor Companion Premium subscription upgrade screen.
///
/// Handles two platform-specific payment flows:
///  - iOS:     url_launcher opens the Netlify subscribe page in Safari.
///             App polls GET /users/me after Safari returns to the foreground.
///  - Android: flutter_inappwebview opens an in-app WebView.
///             App intercepts the noorcompanion://payment-success URL to detect completion.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/subscription_provider.dart';

class UpgradeScreen extends ConsumerStatefulWidget {
  const UpgradeScreen({super.key});

  @override
  ConsumerState<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends ConsumerState<UpgradeScreen>
    with WidgetsBindingObserver {
  bool _didLaunchSafari = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Fetch the redirect URL as soon as the screen opens.
    Future.microtask(() => ref.read(upgradeNotifierProvider.notifier).fetchRedirectUrl());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// On iOS: app resumes from background after Safari — start polling.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _didLaunchSafari &&
        Platform.isIOS) {
      _didLaunchSafari = false;
      ref.read(upgradeNotifierProvider.notifier).pollAfterSafariReturn();
    }
  }

  @override
  Widget build(BuildContext context) {
    final upgradeState = ref.watch(upgradeNotifierProvider);

    ref.listen<UpgradeState>(upgradeNotifierProvider, (_, next) {
      if (next is UpgradeRedirecting) {
        _handleRedirect(next.redirectUrl);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: _buildBody(upgradeState),
      ),
    );
  }

  Widget _buildBody(UpgradeState upgradeState) {
    return switch (upgradeState) {
      UpgradeSuccess() => _SuccessView(onDone: () => context.pop()),
      UpgradeError(:final message) => _ErrorView(
          message: message,
          onRetry: () => ref.read(upgradeNotifierProvider.notifier).reset(),
        ),
      UpgradePolling() => const _PollingView(),
      _ => _UpgradePlanView(isLoading: upgradeState is UpgradeLoading),
    };
  }

  /// Opens the Netlify subscribe page via the appropriate platform mechanism.
  Future<void> _handleRedirect(String url) async {
    if (Platform.isIOS) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        _didLaunchSafari = true;
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ref.read(upgradeNotifierProvider.notifier).reset();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open payment page.')),
          );
        }
      }
    } else {
      // Android — open WebView in a separate route that intercepts success URL
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => _PaymentWebViewScreen(redirectUrl: url),
          fullscreenDialog: true,
        ),
      );
      // WebView closed — check if payment succeeded
      if (mounted) {
        final state = ref.read(upgradeNotifierProvider);
        if (state is! UpgradeSuccess) {
          // WebView was closed without a success signal — reset to idle
          ref.read(upgradeNotifierProvider.notifier).reset();
        }
      }
    }
  }
}

// ── Plan view (main CTA) ──────────────────────────────────────────────────────

class _UpgradePlanView extends StatelessWidget {
  const _UpgradePlanView({required this.isLoading});

  final bool isLoading;

  static const _features = [
    (Icons.call_rounded, 'Live video and audio calls with therapists'),
    (Icons.verified_rounded, 'Verified, licensed wellness professionals'),
    (Icons.star_rounded, 'Rate and bookmark your favourite therapists'),
    (Icons.lock_open_rounded, 'All premium content unlocked'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          _PremiumBadge(),
          const SizedBox(height: 20),
          Text(
            'Unlock Noor Companion Premium',
            style: AppTextStyles.headingLarge.copyWith(
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Connect directly with verified Islamic wellness therapists '
            'whenever you need support.',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _PriceCard(),
          const SizedBox(height: 24),
          ...(_features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _FeatureRow(icon: f.$1, label: f.$2),
            ),
          )),
          const SizedBox(height: 32),
          Consumer(
            builder: (ctx, ref, child) => ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () => ref.read(upgradeNotifierProvider.notifier).fetchRedirectUrl(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandGold,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      'Upgrade Now — ₦5,000/month',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Cancel any time. Billed monthly.',
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _PremiumBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.goldLight,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: AppColors.brandGold.withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandGold.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome_rounded,
                color: AppColors.brandGold, size: 18),
            const SizedBox(width: 8),
            Text(
              'PREMIUM',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.brandGoldDark,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D7C6E), Color(0xFF0A6358)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandTeal.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '₦5,000',
            style: AppTextStyles.headingLarge.copyWith(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Text(
              '/ month',
              style: AppTextStyles.body.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.tealLight,
          ),
          child: Icon(icon, color: AppColors.brandTeal, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(label, style: AppTextStyles.body),
        ),
      ],
    );
  }
}

// ── Polling view (iOS waiting) ────────────────────────────────────────────────

class _PollingView extends StatelessWidget {
  const _PollingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.brandTeal),
          SizedBox(height: 24),
          Text('Confirming your payment…'),
        ],
      ),
    );
  }
}

// ── Success view ──────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandTeal.withValues(alpha: 0.12),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.brandTeal,
                size: 44,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome to Premium!',
              style: AppTextStyles.headingLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'You can now book calls with therapists. '
              'May Allah bless your journey.',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: onDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandTeal,
                minimumSize: const Size(double.infinity, 52),
              ),
              child: const Text('Start Exploring'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.brandGold,
              size: 48,
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandTeal,
                minimumSize: const Size(double.infinity, 52),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Android WebView ───────────────────────────────────────────────────────────

/// Full-screen WebView for Android — loads the Netlify subscribe page.
/// Intercepts noorcompanion://payment-success to detect completed payment.
class _PaymentWebViewScreen extends ConsumerWidget {
  const _PaymentWebViewScreen({required this.redirectUrl});

  final String redirectUrl;

  static const _successScheme = 'noorcompanion';
  static const _successHost = 'payment-success';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Noor Companion Premium'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(redirectUrl)),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          mediaPlaybackRequiresUserGesture: false,
          allowsInlineMediaPlayback: true,
        ),
        shouldOverrideUrlLoading: (controller, action) async {
          final uri = action.request.url;

          if (uri != null &&
              uri.scheme == _successScheme &&
              uri.host == _successHost) {
            await ref
                .read(upgradeNotifierProvider.notifier)
                .onAndroidPaymentSuccess();
            if (context.mounted) {
              Navigator.of(context).pop();
            }
            return NavigationActionPolicy.CANCEL;
          }

          return NavigationActionPolicy.ALLOW;
        },
      ),
    );
  }
}
