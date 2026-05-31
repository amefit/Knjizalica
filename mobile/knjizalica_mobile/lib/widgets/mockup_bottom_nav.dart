import 'package:flutter/material.dart';

import '../config/app_theme.dart';

class MockupBottomNav extends StatelessWidget {
  const MockupBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (Icons.home_outlined, Icons.home, 'Home'),
    (Icons.search, Icons.search, 'Search'),
    (Icons.library_books_outlined, Icons.library_books, 'My Loans'),
    (Icons.person_outline, Icons.person, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_items.length, (index) {
          final item = _items[index];
          final selected = currentIndex == index;
          return InkWell(
            onTap: () => onTap(index),
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: selected
                        ? BoxDecoration(
                            color: AppTheme.navActiveBg,
                            borderRadius: BorderRadius.circular(20),
                          )
                        : null,
                    child: Icon(
                      selected ? item.$2 : item.$1,
                      color: selected ? AppTheme.navActive : AppTheme.accent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.$3,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      color: selected ? AppTheme.navActive : AppTheme.accent,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
