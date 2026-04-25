/// Intervention screen 1 — dua display.
/// Shows a short protective dua in the ArabicTextBlock. A thin progress line
/// at the bottom counts 10 seconds before the Continue button appears.
/// The line itself signals the wait — no text countdown needed.
/// Back navigation is suppressed: the user must complete or skip the sequence.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/arabic_text_block.dart';

class InterventionDuaScreen extends StatefulWidget {
  const InterventionDuaScreen({super.key});

  @override
  State<InterventionDuaScreen> createState() => _InterventionDuaScreenState();
}

class _InterventionDuaScreenState extends State<InterventionDuaScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _timer;
  bool _canContinue = false;

  @override
  void initState() {
    super.initState();
    _timer = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (mounted) setState(() => _canContinue = true);
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _timer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TopBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Column(
                    children: [
                      Text(
                        'Take a breath.\nAllah is with you.',
                        style: AppTextStyles.headingLarge.copyWith(
                          color: AppColors.brandTeal,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      const ArabicTextBlock(
                        arabic: 'أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ الرَّجِيمِ',
                        transliteration:
                            "A'ūdhu billāhi mina sh-shayṭāni r-rajīm",
                        translation:
                            'I seek refuge in Allah from the accursed devil.',
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Read it aloud. Let it settle.',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              _BottomSection(
                timer: _timer,
                canContinue: _canContinue,
                onContinue: () => context.go(AppRoutes.interventionBreathing),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            color: AppColors.textMuted,
            tooltip: 'Exit crisis support',
            onPressed: () => context.go(AppRoutes.home),
          ),
          const Spacer(),
          Text(
            '1 of 4',
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _BottomSection extends StatelessWidget {
  const _BottomSection({
    required this.timer,
    required this.canContinue,
    required this.onContinue,
  });

  final AnimationController timer;
  final bool canContinue;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress line — fills over 10 seconds
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: AnimatedBuilder(
              animation: timer,
              builder: (_, _) => LinearProgressIndicator(
                value: timer.value,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation(AppColors.brandTeal),
                minHeight: 4,
              ),
            ),
          ),
          const SizedBox(height: 20),
          AnimatedOpacity(
            opacity: canContinue ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 400),
            child: ElevatedButton(
              onPressed: canContinue ? onContinue : null,
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}
