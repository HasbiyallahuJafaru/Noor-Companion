/// Active call screen — premium light design with animated energy orb,
/// glassmorphism controls, and smooth state transitions.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/premium_background.dart';
import '../../domain/calling_state.dart';
import '../providers/calling_provider.dart';
import 'call_rating_screen.dart';

class CallScreen extends ConsumerStatefulWidget {
  const CallScreen({
    super.key,
    required this.sessionId,
    required this.channelName,
    required this.agoraToken,
    required this.therapistName,
  });

  final String sessionId;
  final String channelName;
  final String agoraToken;
  final String therapistName;

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> {
  bool _isMuted = false;
  bool _isSpeaker = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(callingProvider.notifier).joinCall(
            token: widget.agoraToken,
            channelName: widget.channelName,
            sessionId: widget.sessionId,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final callState = ref.watch(callingProvider);

    ref.listen(callingProvider, (_, next) {
      if (next is CallingEnded && mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => CallRatingScreen(
            sessionId: next.sessionId ?? widget.sessionId,
            therapistName: widget.therapistName,
            durationSeconds: next.durationSeconds ?? 0,
          ),
        ));
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          const PremiumBackground(),
          SafeArea(
            child: Column(
              children: [
                _TopBar(onEnd: () => ref.read(callingProvider.notifier).endCall(widget.sessionId)),
                const SizedBox(height: 16),
                _CallerInfo(
                  name: widget.therapistName,
                  status: _statusLabel(callState),
                ),
                const Spacer(),
                const _CallOrb(),
                const Spacer(),
                _ControlRow(
                  isMuted: _isMuted,
                  isSpeaker: _isSpeaker,
                  onMute: _toggleMute,
                  onSpeaker: () => setState(() => _isSpeaker = !_isSpeaker),
                  onEnd: () => ref.read(callingProvider.notifier).endCall(widget.sessionId),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    ref.read(callingProvider.notifier).toggleMute(muted: _isMuted);
  }

  String _statusLabel(CallingState s) {
    if (s is CallingConnecting) return 'Connecting…';
    if (s is CallingActive && s.remoteUid == null) return 'Waiting for therapist…';
    if (s is CallingActive) return '00:00';
    if (s is CallingError) return 'Connection error';
    return '';
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onEnd});
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          _CircleNavBtn(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const Spacer(),
          _CircleNavBtn(icon: Icons.more_horiz_rounded, onTap: () {}),
        ],
      ),
    );
  }
}

class _CircleNavBtn extends StatelessWidget {
  const _CircleNavBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(10),
        borderRadius: 999,
        child: Icon(icon, size: 20, color: AppColors.textSecondary),
      ),
    );
  }
}

// ── Caller info ───────────────────────────────────────────────────────────────

class _CallerInfo extends StatelessWidget {
  const _CallerInfo({required this.name, required this.status});
  final String name;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(name, style: AppTextStyles.headingLarge),
        const SizedBox(height: 6),
        Text(status, style: AppTextStyles.bodySmall.copyWith(color: AppColors.brandTeal)),
      ],
    );
  }
}

// ── Animated energy orb ───────────────────────────────────────────────────────

class _CallOrb extends StatefulWidget {
  const _CallOrb();

  @override
  State<_CallOrb> createState() => _CallOrbState();
}

class _CallOrbState extends State<_CallOrb> with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _rotate;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _rotate = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat();
    _pulseAnim = CurvedAnimation(parent: _pulse, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _pulse.dispose();
    _rotate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnim, _rotate]),
      builder: (_, _) {
        final scale = 1.0 + _pulseAnim.value * 0.06;
        final angle = _rotate.value * 2 * math.pi;
        return Transform.scale(
          scale: scale,
          child: SizedBox(
            width: 220,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow ring
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.brandTeal.withValues(alpha: 0.15 + _pulseAnim.value * 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                // Mid ring
                Container(
                  width: 175,
                  height: 175,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.brandTeal.withValues(alpha: 0.20),
                        AppColors.brandTeal.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                ),
                // Core orb with rotating highlight
                Transform.rotate(
                  angle: angle,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          AppColors.brandTeal,
                          AppColors.brandGold.withValues(alpha: 0.7),
                          AppColors.brandTeal,
                          const Color(0xFF0A5F54),
                          AppColors.brandTeal,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brandTeal.withValues(alpha: 0.5),
                          blurRadius: 40,
                          spreadRadius: 4,
                        ),
                        BoxShadow(
                          color: AppColors.brandGold.withValues(alpha: 0.2),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                // Specular highlight
                Positioned(
                  top: 52,
                  left: 60,
                  child: Container(
                    width: 30,
                    height: 18,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Controls ──────────────────────────────────────────────────────────────────

class _ControlRow extends StatelessWidget {
  const _ControlRow({
    required this.isMuted,
    required this.isSpeaker,
    required this.onMute,
    required this.onSpeaker,
    required this.onEnd,
  });

  final bool isMuted;
  final bool isSpeaker;
  final VoidCallback onMute;
  final VoidCallback onSpeaker;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ControlBtn(
            icon: isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
            label: isMuted ? 'Unmute' : 'Mute',
            active: isMuted,
            onTap: onMute,
          ),
          _EndCallBtn(onTap: onEnd),
          _ControlBtn(
            icon: isSpeaker ? Icons.volume_up_rounded : Icons.volume_down_rounded,
            label: 'Speaker',
            active: isSpeaker,
            onTap: onSpeaker,
          ),
        ],
      ),
    );
  }
}

class _ControlBtn extends StatelessWidget {
  const _ControlBtn({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GlassCard(
            padding: const EdgeInsets.all(16),
            borderRadius: 999,
            child: Icon(
              icon,
              size: 24,
              color: active ? AppColors.brandTeal : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _EndCallBtn extends StatelessWidget {
  const _EndCallBtn({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFD63031),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD63031).withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text('End', style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
