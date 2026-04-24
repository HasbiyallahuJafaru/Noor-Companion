# FLUTTER_GUIDE.md — Noor Companion
# Flutter architecture, Supabase integration, Riverpod patterns, and conventions.
# Read this before writing any Flutter/Dart code.

## Supabase in Flutter

supabase_flutter owns the entire auth lifecycle:
- Login, register, logout, session refresh — all done via Supabase SDK
- The Supabase session is persisted automatically in local secure storage
- No manual token management needed

Flutter never calls the backend for auth. It calls the backend for everything else
(content, therapists, calls, payments, notifications).

### Initialisation (main.dart)

```dart
/// App entry point.
/// Initialises Sentry, Supabase, and Hive before running the app.
/// Order matters — Sentry first so it captures any init errors.
Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = AppConfig.sentryDsn;
      options.environment = AppConfig.environment;
    },
    appRunner: () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Initialise Supabase — handles auth session persistence automatically
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
      );

      // Initialise Hive for offline content cache
      await Hive.initFlutter();
      await _registerHiveAdapters();

      // Initialise Firebase for push notifications
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      runApp(const ProviderScope(child: NoorApp()));
    },
  );
}
```

### Auth Provider

```dart
/// Auth state notifier backed by Supabase.
/// Listens to Supabase's onAuthStateChange stream for reactive updates.
/// No manual token storage or refresh logic needed.
class AuthNotifier extends StateNotifier<AuthState> {
  final SupabaseClient _supabase;
  final UserRepository _userRepository;
  StreamSubscription? _authSubscription;

  AuthNotifier(this._supabase, this._userRepository)
      : super(const AuthState.loading()) {
    _init();
  }

  /// Initialises auth state from the current Supabase session.
  /// Subscribes to auth state changes for the full app lifecycle.
  void _init() {
    // Check for an existing session on app start
    final existingSession = _supabase.auth.currentSession;
    if (existingSession != null) {
      _loadAppUser(existingSession.user.id);
    } else {
      state = const AuthState.unauthenticated();
    }

    // Listen for auth changes (login, logout, token refresh)
    _authSubscription = _supabase.auth.onAuthStateChange.listen((event) {
      if (event.session != null) {
        _loadAppUser(event.session!.user.id);
      } else {
        state = const AuthState.unauthenticated();
      }
    });
  }

  /// Loads our app User record from the backend using the Supabase user ID.
  Future<void> _loadAppUser(String supabaseUserId) async {
    try {
      final user = await _userRepository.getMe();
      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  /// Registers a new user via Supabase Auth.
  /// On success, the auth stream fires and _loadAppUser is called automatically.
  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
  }) async {
    state = const AuthState.loading();
    try {
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'role': role,
        },
      );
      // Auth stream handles the rest
    } on AuthException catch (e) {
      state = AuthState.error(e.message);
    }
  }

  /// Signs in an existing user via Supabase Auth.
  Future<void> login(String email, String password) async {
    state = const AuthState.loading();
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
      // Auth stream fires → _loadAppUser called automatically
    } on AuthException catch (e) {
      state = AuthState.error(e.message);
    }
  }

  /// Signs out the current user and clears the session.
  Future<void> logout() async {
    await _supabase.auth.signOut();
    // Auth stream fires → state set to unauthenticated automatically
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
```

---

## Dio for Backend API Calls

Flutter uses supabase_flutter for auth, but Dio for all backend REST calls.
The auth interceptor injects the current Supabase access token automatically.

```dart
/// Auth interceptor — attaches the current Supabase access token to all
/// backend API requests. If the token has expired, supabase_flutter
/// refreshes it automatically before the interceptor runs.
class AuthInterceptor extends Interceptor {
  final SupabaseClient _supabase;

  AuthInterceptor(this._supabase);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final session = _supabase.auth.currentSession;

    if (session != null) {
      options.headers['Authorization'] = 'Bearer ${session.accessToken}';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 401 from backend means token is invalid or user is suspended
    // supabase_flutter handles token expiry automatically, so this
    // should only happen if the account was suspended
    if (err.response?.statusCode == 401) {
      _supabase.auth.signOut();
    }
    handler.next(err);
  }
}
```

---

## Feature Structure

Each feature is self-contained. Features never import directly from each other.
Shared code lives in lib/shared/.

```
features/auth/
├── data/
│   └── auth_repository.dart      # All API calls for this feature
├── domain/
│   ├── models/
│   │   └── user_model.dart       # Dart class with fromJson/toJson
│   └── auth_exceptions.dart      # Feature-specific typed exceptions
└── presentation/
    ├── screens/
    │   ├── login_screen.dart
    │   └── register_screen.dart
    ├── widgets/
    │   └── auth_text_field.dart
    └── providers/
        └── auth_provider.dart    # StateNotifier + state class + provider defs
```

---

## Riverpod Pattern (StateNotifier)

```dart
// 1. Immutable state class (use freezed or manual)
/// All possible states of the authentication flow.
@freezed
class AuthState with _$AuthState {
  const factory AuthState.loading() = _Loading;
  const factory AuthState.authenticated(UserModel user) = _Authenticated;
  const factory AuthState.unauthenticated() = _Unauthenticated;
  const factory AuthState.error(String message) = _Error;
}

// 2. Providers (bottom of the provider file)
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.read(supabaseClientProvider),
    ref.read(userRepositoryProvider),
  );
});

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
```

---

## GoRouter with Role Guards

```dart
/// Application router.
/// Role-based redirects are enforced here AND at the API level.
/// A user cannot reach a screen their role does not permit.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authState is AuthStateAuthenticated
        ? null
        : null, // GoRouter rebuilds when provider changes
    redirect: (context, state) {
      final location = state.matchedLocation;

      if (authState is AuthStateLoading) return '/splash';

      if (authState is AuthStateUnauthenticated) {
        if (!location.startsWith('/auth')) return '/auth/login';
        return null;
      }

      if (authState is AuthStateAuthenticated) {
        final user = (authState as AuthStateAuthenticated).user;

        // Redirect away from auth screens if already logged in
        if (location.startsWith('/auth')) return '/home';

        // Role-based access enforcement
        if (location.startsWith('/admin') && user.role != 'admin') {
          return '/home';
        }
        if (location.startsWith('/therapist-dashboard') &&
            user.role != 'therapist') {
          return '/home';
        }
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/auth/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/auth/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/dhikr', builder: (_, __) => const DhikrLibraryScreen()),
      GoRoute(
        path: '/dhikr/:id',
        builder: (_, state) => DhikrDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(path: '/duas', builder: (_, __) => const DuaLibraryScreen()),
      GoRoute(path: '/quran', builder: (_, __) => const RecitationBrowserScreen()),
      GoRoute(path: '/therapists', builder: (_, __) => const TherapistListScreen()),
      GoRoute(
        path: '/therapists/:id',
        builder: (_, state) =>
            TherapistProfileScreen(therapistId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/calling/:sessionId', builder: (_, state) =>
          CallScreen(sessionId: state.pathParameters['sessionId']!)),
      GoRoute(path: '/subscription/upgrade', builder: (_, __) => const UpgradeScreen()),
      GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/admin', builder: (_, __) => const AdminDashboardScreen()),
      GoRoute(
        path: '/therapist-dashboard',
        builder: (_, __) => const TherapistDashboardScreen(),
      ),
    ],
  );
});
```

---

## Offline Cache (Hive)

Content is cached in Hive on first load. App shows cached data immediately,
then refreshes in the background.

```dart
/// Fetches dhikr content — returns cache immediately, refreshes in background.
///
/// Emits cached data first (no loading delay), then emits fresh data once
/// the API call completes. If the network fails and cache exists, the user
/// sees content without an error. If both fail, the error is propagated.
Stream<List<DhikrItem>> watchDhikr() async* {
  final cached = await _localCache.getDhikr();

  if (cached.isNotEmpty) yield cached;

  try {
    final fresh = await _apiClient.get('/content/dhikr');
    final items = (fresh.data['data'] as List)
        .map((json) => DhikrItem.fromJson(json))
        .toList();

    await _localCache.saveDhikr(items);
    yield items;
  } catch (e) {
    if (cached.isEmpty) rethrow;
    // If we have cached data, a network error is silent — user saw content
  }
}
```

---

## Design System

Brand palette (app_colors.dart):
```dart
static const Color brandTeal     = Color(0xFF0D7C6E); // Primary actions, headers
static const Color brandGold     = Color(0xFFC9933A); // Streak, premium badges
static const Color tealLight     = Color(0xFFE6F4F2); // Card backgrounds
static const Color goldLight     = Color(0xFFFDF3E3); // Premium callouts
static const Color background    = Color(0xFFF7F8FA); // App background
static const Color surface       = Color(0xFFFFFFFF); // Cards
static const Color textPrimary   = Color(0xFF1A1A2E);
static const Color textSecondary = Color(0xFF666666);
```

Follow hasbiy-flutter skill for all screens:
- 8pt spatial grid for all spacing
- Physical press physics on all interactive elements (scale down on press)
- Coloured shadows — never grey shadows
- Micro-interactions on buttons, cards, and list items
- Typography with personality — not system defaults

---

## Dart Documentation Standard

```dart
/// Represents a dhikr item from the platform content library.
///
/// [audioUrl] may be null if no audio has been uploaded for this item.
/// Always check for null before attempting playback.
class DhikrItem {
  /// Unique database identifier.
  final String id;

  /// Arabic text of the phrase.
  final String arabicText;

  /// Latin phonetic transliteration.
  final String transliteration;

  /// English meaning.
  final String translation;

  /// Supabase Storage CDN URL for the audio file. Null if unavailable.
  final String? audioUrl;

  /// List of category tags — e.g. ["morning", "general"].
  final List<String> tags;

  const DhikrItem({
    required this.id,
    required this.arabicText,
    required this.transliteration,
    required this.translation,
    required this.tags,
    this.audioUrl,
  });

  /// Constructs a [DhikrItem] from the API JSON response.
  factory DhikrItem.fromJson(Map<String, dynamic> json) => DhikrItem(
        id: json['id'] as String,
        arabicText: json['arabicText'] as String,
        transliteration: json['transliteration'] as String,
        translation: json['translation'] as String,
        tags: List<String>.from(json['tags'] as List),
        audioUrl: json['audioUrl'] as String?,
      );
}
```

---

## AppConfig (dart-define)

```dart
/// Compile-time application configuration.
/// Values injected via --dart-define at build time.
/// Never hardcode production values in this file.
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api/v1',
  );

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  static const String agoraAppId = String.fromEnvironment('AGORA_APP_ID');

  static const String sentryDsn = String.fromEnvironment('SENTRY_DSN');

  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  static const String websiteUrl = String.fromEnvironment(
    'WEBSITE_URL',
    defaultValue: 'http://localhost:5000',
  );
}
```
