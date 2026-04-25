/// Therapists tab placeholder.
/// Full implementation built in the Therapists List Screen task (TASKS.md).
library;

import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';

class TherapistsScreen extends StatelessWidget {
  const TherapistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Therapists', style: AppTextStyles.headingLarge),
      ),
    );
  }
}
