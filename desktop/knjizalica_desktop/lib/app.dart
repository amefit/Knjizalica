import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/books_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/loans_provider.dart';
import 'providers/members_provider.dart';
import 'providers/reference_data_provider.dart';
import 'screens/activity_logs_screen.dart';
import 'screens/administration_screen.dart';
import 'screens/book_form_screen.dart';
import 'screens/books_list_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/loans_screen.dart';
import 'screens/login_screen.dart';
import 'screens/members_screen.dart';
import 'widgets/app_shell.dart';

T? _keepProvider<T>(AuthProvider auth, T? previous) {
  if (auth.status != AuthStatus.authenticated) return null;
  return previous;
}

class KnjizalicaApp extends StatelessWidget {
  const KnjizalicaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ProxyProvider<AuthProvider, AuthApiHolder>(
          update: (_, auth, __) => AuthApiHolder(auth.authService.api),
        ),
        ChangeNotifierProxyProvider<AuthProvider, DashboardProvider>(
          create: (ctx) => DashboardProvider(ctx.read<AuthProvider>().authService.api),
          update: (_, auth, previous) =>
              _keepProvider(auth, previous) ?? DashboardProvider(auth.authService.api),
        ),
        ChangeNotifierProxyProvider<AuthProvider, BooksProvider>(
          create: (ctx) => BooksProvider(ctx.read<AuthProvider>().authService.api),
          update: (_, auth, previous) =>
              _keepProvider(auth, previous) ?? BooksProvider(auth.authService.api),
        ),
        ChangeNotifierProxyProvider<AuthProvider, AuthorsProvider>(
          create: (ctx) => AuthorsProvider(ctx.read<AuthProvider>().authService.api),
          update: (_, auth, previous) =>
              _keepProvider(auth, previous) ?? AuthorsProvider(auth.authService.api),
        ),
        ChangeNotifierProxyProvider<AuthProvider, LoansProvider>(
          create: (ctx) => LoansProvider(ctx.read<AuthProvider>().authService.api),
          update: (_, auth, previous) =>
              _keepProvider(auth, previous) ?? LoansProvider(auth.authService.api),
        ),
        ChangeNotifierProxyProvider<AuthProvider, MembersProvider>(
          create: (ctx) => MembersProvider(ctx.read<AuthProvider>().authService.api),
          update: (_, auth, previous) =>
              _keepProvider(auth, previous) ?? MembersProvider(auth.authService.api),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ActivityLogsProvider>(
          create: (ctx) => ActivityLogsProvider(ctx.read<AuthProvider>().authService.api),
          update: (_, auth, previous) =>
              _keepProvider(auth, previous) ??
              ActivityLogsProvider(auth.authService.api),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ReferenceDataProvider>(
          create: (ctx) => ReferenceDataProvider(ctx.read<AuthProvider>().authService.api),
          update: (_, auth, previous) =>
              _keepProvider(auth, previous) ?? ReferenceDataProvider(auth.authService.api),
        ),
      ],
      child: MaterialApp(
        title: 'Knjizalica Admin',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const _RootNavigator(),
      ),
    );
  }
}

class _RootNavigator extends StatefulWidget {
  const _RootNavigator();

  @override
  State<_RootNavigator> createState() => _RootNavigatorState();
}

class _RootNavigatorState extends State<_RootNavigator> {
  int _selectedIndex = 1;
  int _bookFormKey = 0;

  static const _titles = [
    'Search',
    'Home',
    'Add Book',
    'Resources',
    'Loans',
    'Members',
    'Activity History',
    'Administration',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().initialize();
    });
  }

  Widget _screenForIndex(int index) {
    return switch (index) {
      0 => const BooksListScreen(searchFocus: true),
      1 => const DashboardScreen(),
      2 => BookFormScreen(
          key: ValueKey(_bookFormKey),
          embedded: true,
          onCancel: () => setState(() => _selectedIndex = 3),
          onSaved: () => setState(() {
            _bookFormKey++;
            _selectedIndex = 3;
          }),
        ),
      3 => const BooksListScreen(),
      4 => const LoansScreen(),
      5 => const MembersScreen(),
      6 => const ActivityLogsScreen(),
      7 => const AdministrationScreen(),
      _ => const DashboardScreen(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.status == AuthStatus.unknown || auth.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (auth.status == AuthStatus.unauthenticated) {
      return const LoginScreen();
    }

    return AppShell(
      selectedIndex: _selectedIndex,
      onNavigate: (index) {
        if (_selectedIndex == index) return;
        setState(() => _selectedIndex = index);
        // Refresh data on view change
        switch (index) {
          case 0:
          case 3:
            context.read<BooksProvider>().loadBooks();
            break;
          case 1:
            context.read<DashboardProvider>().load();
            break;
          case 4:
            context.read<LoansProvider>().loadLoans();
            break;
          case 5:
            context.read<MembersProvider>().loadMembers();
            break;
          case 6:
            context.read<ActivityLogsProvider>().loadLogs();
            break;
        }
      },
      title: _titles[_selectedIndex],
      child: IndexedStack(
        index: _selectedIndex,
        children: List.generate(_titles.length, _screenForIndex),
      ),
    );
  }
}
