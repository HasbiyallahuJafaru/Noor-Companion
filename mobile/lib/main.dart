/// Noor Companion — app entry point.
/// Initialises Sentry, Hive, and Riverpod before running the widget tree.
/// Supabase and Firebase are wired in Phase 1 once credentials exist.
/// Sentry is initialised first so it captures any startup errors.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'core/config/app_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = AppConfig.sentryDsn;
      options.environment = AppConfig.environment;
      options.tracesSampleRate = AppConfig.isDevelopment ? 1.0 : 0.2;
    },
    appRunner: _initAndRun,
  );
}

/// Performs all async initialisation then mounts the widget tree.
Future<void> _initAndRun() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // Supabase and Firebase initialised in Phase 1 once credentials are set.
  // await Supabase.initialize(url: AppConfig.supabaseUrl, anonKey: AppConfig.supabaseAnonKey);
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: NoorApp()));
}

/// Root application widget — wires theme, router, and provider scope.
class NoorApp extends StatelessWidget {
  const NoorApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = buildAppRouter();

    return MaterialApp.router(
      title: 'Noor Companion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
