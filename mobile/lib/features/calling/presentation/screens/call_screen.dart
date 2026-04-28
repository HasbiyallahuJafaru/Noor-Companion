/// Active call screen — joins the Agora channel on mount and shows
/// call controls (mute, end). Navigates to the rating screen on end.
/// This screen owns the callingProvider lifetime via ProviderScope.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
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

    ref.listen(callingProvider, (prev, next) {
      if (next is CallingEnded && mounted) {
        _goToRating(next.sessionId, next.durationSeconds);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),
            _StatusSection(callState: callState, therapistName: widget.therapistName),
            const Spacer(),
            _Controls(
              isMuted: _isMuted,
              onMuteToggle: _toggleMute,
              onEndCall: () => ref.read(callingProvider.notifier).endCall(widget.sessionId),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    ref.read(callingProvider.notifier).toggleMute(muted: _isMuted);
  }

  void _goToRating(String? sessionId, int? durationSeconds) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CallRatingScreen(
          sessionId: sessionId ?? widget.sessionId,
          therapistName: widget.therapistName,
          durationSeconds: durationSeconds ?? 0,
        ),
      ),
    );
  }
}

// ── Status section ────────────────────────────────────────────────────────────

class _StatusSection extends StatelessWidget {
  const _StatusSection({required this.callState, required this.therapistName});

  final CallingState callState;
  final String therapistName;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.tealLight,
          ),
          child: const Icon(Icons.person_rounded, color: AppColors.brandTeal, size: 48),
        ),
        const SizedBox(height: 20),
        Text(therapistName, style: AppTextStyles.headingMedium),
        const SizedBox(height: 8),
        Text(_statusLabel(callState), style: AppTextStyles.bodySmall),
      ],
    );
  }

  String _statusLabel(CallingState s) {
    if (s is CallingConnecting) return 'Connecting…';
    if (s is CallingActive && s.remoteUid == null) return 'Waiting for therapist…';
    if (s is CallingActive) return 'Connected';
    if (s is CallingError) return 'Connection error';
    return '';
  }
}

// ── Controls ──────────────────────────────────────────────────────────────────

class _Controls extends StatelessWidget {
  const _Controls({
    required this.isMuted,
    required this.onMuteToggle,
    required this.onEndCall,
  });

  final bool isMuted;
  final VoidCallback onMuteToggle;
  final VoidCallback onEndCall;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ControlButton(
            icon: isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
            color: isMuted ? AppColors.textMuted : AppColors.brandTeal,
            label: isMuted ? 'Unmute' : 'Mute',
            onTap: onMuteToggle,
          ),
          _EndCallButton(onTap: onEndCall),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _EndCallButton extends StatelessWidget {
  const _EndCallButton({required this.onTap});

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
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE53935),
            ),
            child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 8),
          Text('End', style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
