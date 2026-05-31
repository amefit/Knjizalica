import 'package:flutter/material.dart';

import '../config/app_theme.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  Color _backgroundColor() {
    switch (status.toLowerCase()) {
      case 'available':
        return AppTheme.availableBg;
      case 'borrowed':
        return AppTheme.borrowedBg;
      case 'active':
      case 'confirmed':
        return AppTheme.activeBg;
      case 'pending':
        return AppTheme.borrowedBg;
      case 'returned':
      case 'completed':
        return AppTheme.returnedBg;
      case 'overdue':
        return AppTheme.overdueBg;
      case 'cancelled':
        return Colors.grey.withValues(alpha: 0.2);
      default:
        return Colors.blueGrey.withValues(alpha: 0.15);
    }
  }

  Color _foregroundColor() {
    switch (status.toLowerCase()) {
      case 'available':
        return AppTheme.available;
      case 'borrowed':
        return AppTheme.borrowed;
      case 'active':
      case 'confirmed':
      case 'pending':
        return AppTheme.active;
      case 'returned':
      case 'completed':
        return AppTheme.returned;
      case 'overdue':
        return AppTheme.overdue;
      case 'cancelled':
        return Colors.grey.shade700;
      default:
        return Colors.blueGrey;
    }
  }

  String _label() {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Active';
      case 'completed':
        return 'Returned';
      case 'pending':
        return 'Pending';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _backgroundColor(),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label(),
        style: TextStyle(
          color: _foregroundColor(),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
