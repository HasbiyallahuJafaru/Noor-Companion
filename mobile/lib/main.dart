/// Noor Companion — app entry point.
/// Init order: Sentry (if DSN valid) → WidgetsBinding → Supabase → Hive → runApp.
library;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/app_config.dart';
import 'features/content/data/content_cache.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  // Only init Sentry when a real DSN is provided — a missing or placeholder
  // DSN causes SentryFlutter.init to throw before appRunner is called,
  // which prevents runApp from ever executing.
  final hasValidDsn = AppConfig.sentryDsn.isNotEmpty &&
      AppConfig.sentryDsn.startsWith('https://');

  if (hasValidDsn) {
    await SentryFlutter.init(
      (options) {
        options.dsn = AppConfig.sentryDsn;
        options.environment = AppConfig.environment;
        options.tracesSampleRate = AppConfig.isDevelopment ? 1.0 : 0.2;
      },
      appRunner: _initAndRun,
    );
  } else {
    await _initAndRun();
  }
}

Future<void> _initAndRun() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  await Hive.initFlutter();
  await openContentBoxes();

  runApp(const ProviderScope(child: NoorApp()));
}

/// Root application widget.
class NoorApp extends ConsumerWidget {
  const NoorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = buildAppRouter(ref);

    return MaterialApp.router(
      title: 'Noor Companion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
