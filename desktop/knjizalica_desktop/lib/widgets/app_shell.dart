import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import 'sidebar_navigation.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.selectedIndex,
    required this.onNavigate,
    required this.child,
    required this.title,
  });

  final int selectedIndex;
  final ValueChanged<int> onNavigate;
  final Widget child;
  final String title;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userName = auth.user?.fullName ?? 'Administrator';

    return Scaffold(
      body: Row(
        children: [
          SidebarNavigation(
            selectedIndex: selectedIndex,
            onItemSelected: onNavigate,
            userName: userName,
            onLogout: () => auth.logout(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 28, 32, 8),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 32,
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
