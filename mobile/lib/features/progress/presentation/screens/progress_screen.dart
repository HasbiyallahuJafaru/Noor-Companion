/// Progress tab placeholder.
/// Full implementation built in the Progress Screen task (TASKS.md).
library;

import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Progress', style: AppTextStyles.headingLarge),
      ),
    );
  }
}
