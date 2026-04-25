/// Tasks tab placeholder.
/// Full implementation built in the Daily Task Card task (TASKS.md).
library;

import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Tasks', style: AppTextStyles.headingLarge),
      ),
    );
  }
}
