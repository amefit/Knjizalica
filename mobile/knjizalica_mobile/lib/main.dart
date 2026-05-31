import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/books_provider.dart';
import 'providers/loans_provider.dart';
import 'providers/notifications_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/notification_hub_service.dart';
import 'services/token_storage.dart';
import 'widgets/loading_widget.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final tokenStorage = TokenStorage();
  late final AuthProvider authProvider;

  final apiService = ApiService(
    tokenStorage: tokenStorage,
    onUnauthorized: () async {
      await authProvider.handleUnauthorized();
      rootNavigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    },
  );

  final authService = AuthService(
    api: apiService,
    tokenStorage: tokenStorage,
  );

  final hubService = NotificationHubService();

  authProvider = AuthProvider(
    authService: authService,
    apiService: apiService,
    hubService: hubService,
    tokenStorage: tokenStorage,
  );

  runApp(
    KnjizalicaApp(
      apiService: apiService,
      authProvider: authProvider,
      hubService: hubService,
    ),
  );
}

class KnjizalicaApp extends StatelessWidget {
  const KnjizalicaApp({
    super.key,
    required this.apiService,
    required this.authProvider,
    required this.hubService,
  });

  final ApiService apiService;
  final AuthProvider authProvider;
  final NotificationHubService hubService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        Provider<NotificationHubService>.value(value: hubService),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider(
          create: (_) => BooksProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => LoansProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationsProvider(
            api: apiService,
            hubService: hubService,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Knjizalica',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        navigatorKey: rootNavigatorKey,
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    switch (auth.status) {
      case AuthStatus.unknown:
        return const Scaffold(
          body: LoadingWidget(message: 'Starting Knjizalica...'),
        );
      case AuthStatus.authenticated:
        return const MainShell();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}
