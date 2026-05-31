import 'package:flutter/material.dart';

import '../config/app_theme.dart';

class SidebarNavigation extends StatefulWidget {
  const SidebarNavigation({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.userName,
    required this.onLogout,
  });

  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final String userName;
  final VoidCallback onLogout;

  @override
  State<SidebarNavigation> createState() => _SidebarNavigationState();
}

class _SidebarNavigationState extends State<SidebarNavigation> {
  bool _resourcesExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: AppTheme.sidebarBg,
        border: Border(right: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Text(
              'Knjizalica',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _tile(0, Icons.search, 'Search'),
                _tile(1, Icons.home_outlined, 'Home', selectedIcon: Icons.home),
                const SizedBox(height: 8),
                _sectionHeader('Resources', _resourcesExpanded, () {
                  setState(() => _resourcesExpanded = !_resourcesExpanded);
                }),
                if (_resourcesExpanded) ...[
                  _tile(2, Icons.add, 'Add Book', indent: 16),
                  _tile(3, Icons.menu_book_outlined, 'All Books', indent: 16),
                ],
                _tile(4, Icons.swap_horiz_outlined, 'Loans'),
                _tile(5, Icons.groups_outlined, 'Members'),
                _tile(6, Icons.history, 'Activity History'),
                _tile(7, Icons.settings_outlined, 'Administration'),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.border),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                TextButton(
                  onPressed: widget.onLogout,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: AppTheme.textSecondary,
                  ),
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, bool expanded, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.folder_outlined, size: 20, color: AppTheme.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            Icon(
              expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
              size: 20,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(
    int index,
    IconData icon,
    String label, {
    IconData? selectedIcon,
    double indent = 0,
  }) {
    final selected = widget.selectedIndex == index;
    return Padding(
      padding: EdgeInsets.only(left: indent, bottom: 4),
      child: Material(
        color: selected ? AppTheme.sidebarSelected : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => widget.onItemSelected(index),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(
                  selected && selectedIcon != null ? selectedIcon : icon,
                  size: 20,
                  color: AppTheme.textPrimary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.info,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
