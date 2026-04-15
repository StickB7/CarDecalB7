import 'package:flutter/material.dart';

import '../../data/models/vault_category.dart';
import '../theme/app_theme.dart';

/// Horizontal scrollable row of category filter chips.
class CategoryChipRow extends StatelessWidget {
  const CategoryChipRow({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final String   selected;
  final void Function(String) onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection:  Axis.horizontal,
        padding:          const EdgeInsets.symmetric(horizontal: 20),
        itemCount:        VaultCategory.all.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat     = VaultCategory.all[i];
          final isActive = cat.key == selected;
          return _CategoryChip(
            category: cat,
            isActive: isActive,
            onTap:    () => onSelected(cat.key),
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.isActive,
    required this.onTap,
  });

  final VaultCategory category;
  final bool          isActive;
  final VoidCallback  onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color:        isActive ? AppTheme.gold : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppTheme.gold : AppTheme.border,
            width: 1.5,
          ),
          boxShadow: isActive
              ? [BoxShadow(
                  color:      AppTheme.gold.withOpacity(0.25),
                  blurRadius: 8,
                  offset:     const Offset(0, 2),
                )]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              category.icon,
              size:  14,
              color: isActive ? const Color(0xFF1A1600) : AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              category.label,
              style: TextStyle(
                fontSize:   13,
                fontWeight: FontWeight.w600,
                color: isActive ? const Color(0xFF1A1600) : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
