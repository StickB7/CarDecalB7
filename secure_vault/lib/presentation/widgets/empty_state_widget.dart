import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shown when a category (or the whole vault) is empty.
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    this.icon    = Icons.lock_outlined,
    this.title   = 'התיקייה ריקה',
    this.subtitle = 'לחץ על כפתור + כדי להוסיף קבצים',
  });

  final IconData icon;
  final String   title;
  final String   subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width:  80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.surfaceVariant,
              border: Border.all(color: AppTheme.border),
            ),
            child: Icon(icon, size: 36, color: AppTheme.textTertiary),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
