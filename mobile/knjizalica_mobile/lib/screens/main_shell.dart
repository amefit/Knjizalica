import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/books_provider.dart';
import '../providers/loans_provider.dart';
import '../providers/notifications_provider.dart';
import '../widgets/mockup_bottom_nav.dart';
import 'home_screen.dart';
import 'my_loans_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BooksProvider>().loadHome();
      context.read<LoansProvider>().loadMyLoans();
      context.read<NotificationsProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onOpenSearch: () => setState(() => _index = 1)),
      const SearchScreen(),
      const MyLoansScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: MockupBottomNav(
        currentIndex: _index,
        onTap: (value) => setState(() => _index = value),
      ),
    );
  }
}
