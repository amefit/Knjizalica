import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_theme.dart';
import '../providers/auth_provider.dart';

class MobileHeader extends StatelessWidget {
  const MobileHeader({super.key, this.showSearch = false, this.onSearchTap});

  final bool showSearch;
  final VoidCallback? onSearchTap;

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().profile;
    final initials = profile == null
        ? '?'
        : '${profile.firstName.isNotEmpty ? profile.firstName[0] : ''}${profile.lastName.isNotEmpty ? profile.lastName[0] : ''}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                'Knjizalica',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
              const Spacer(),
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.navActiveBg,
                child: Text(
                  initials.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.navActive,
                  ),
                ),
              ),
            ],
          ),
          if (showSearch) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onSearchTap,
              child: AbsorbPointer(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search catalog...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
