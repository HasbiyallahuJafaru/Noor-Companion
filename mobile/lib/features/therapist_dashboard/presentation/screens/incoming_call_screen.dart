/// Incoming call screen shown to a therapist when an FCM push arrives.
/// Displayed as a full-screen overlay over the existing UI.
/// The therapist can accept (joins Agora) or decline (ends session on backend).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

class IncomingCallScreen extends ConsumerStatefulWidget {
  const IncomingCallScreen({
    super.key,
    required this.sessionId,
    required this.channelName,
    required this.agoraToken,
    required this.callerName,
  });

  final String sessionId;
  final String channelName;
  final String agoraToken;
  final String callerName;

  @override
  ConsumerState<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends ConsumerState<IncomingCallScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  bool _isActing = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 0.95, end: 1.05).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _accept() async {
    if (_isActing) return;
    setState(() => _isActing = true);
    _pulseController.stop();

    // Navigate to the active call screen — CallingNotifier handles Agora init.
    if (mounted) {
      context.pushReplacement(
        '/call/${widget.sessionId}',
        extra: {
          'channelName': widget.channelName,
          'agoraToken': widget.agoraToken,
          'therapistName': widget.callerName,
        },
      );
    }
  }

  Future<void> _decline() async {
    if (_isActing) return;
    setState(() => _isActing = true);

    try {
      final dio = ref.read(apiClientProvider);
      await dio.post('/calls/${widget.sessionId}/end');
    } catch (e, stack) {
      Sentry.captureException(e, stackTrace: stack);
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A2A26),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            _CallerInfo(
              callerName: widget.callerName,
              pulseAnimation: _pulseAnimation,
            ),
            const SizedBox(height: 16),
            Text(
              'Incoming Call',
              style: AppTextStyles.body.copyWith(
                color: Colors.white60,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(flex: 3),
            _CallActions(
              isActing: _isActing,
              onAccept: _accept,
              onDecline: _decline,
            ),
            const SizedBox(height: 56),
          ],
        ),
      ),
    );
  }
}

// ── Caller info ───────────────────────────────────────────────────────────────

class _CallerInfo extends StatelessWidget {
  const _CallerInfo({
    required this.callerName,
    required this.pulseAnimation,
  });

  final String callerName;
  final Animation<double> pulseAnimation;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: pulseAnimation,
          builder: (_, child) => Transform.scale(
            scale: pulseAnimation.value,
            child: child,
          ),
          child: Container(
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.brandTeal.withValues(alpha: 0.2),
              border: Border.all(
                color: AppColors.brandTeal.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandTeal.withValues(alpha: 0.3),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.brandTeal,
              size: 52,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          callerName,
          style: AppTextStyles.headingLarge.copyWith(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── Call actions ──────────────────────────────────────────────────────────────

class _CallActions extends StatelessWidget {
  const _CallActions({
    required this.isActing,
    required this.onAccept,
    required this.onDecline,
  });

  final bool isActing;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ActionButton(
          icon: Icons.call_end_rounded,
          label: 'Decline',
          color: const Color(0xFFE53935),
          onTap: isActing ? null : onDecline,
        ),
        _ActionButton(
          icon: Icons.call_rounded,
          label: 'Accept',
          color: AppColors.success,
          onTap: isActing ? null : onAccept,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: AppTextStyles.body.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
