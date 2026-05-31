import 'package:flutter/material.dart';

import '../config/app_theme.dart';

class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.onTap,
  });

  final String title;
  final int value;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppTheme.textPrimary;
    final isDanger = color == AppTheme.danger;

    final card = Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '+ $value',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: isDanger ? AppTheme.danger : AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDanger
                      ? AppTheme.danger.withValues(alpha: 0.08)
                      : AppTheme.sidebarSelected,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDanger ? AppTheme.danger.withValues(alpha: 0.2) : AppTheme.border,
                  ),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
            ],
          ),
        ),
      ),
    );

    return card;
  }
}
