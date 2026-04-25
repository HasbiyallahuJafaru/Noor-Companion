/// Splash screen shown while auth state is resolving on app start.
/// Displays the Noor Companion logo and tagline.
/// GoRouter redirects away from this screen once auth state is known.
library;

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandTeal,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'نور',
              style: AppTextStyles.arabicLarge.copyWith(
                color: Colors.white,
                fontSize: 64,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Noor Companion',
              style: AppTextStyles.headingLarge.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Light your way back',
              style: AppTextStyles.body.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
