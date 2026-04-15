import 'package:flutter/material.dart';

/// Represents a file category tab shown in the vault home screen.
class VaultCategory {
  const VaultCategory({
    required this.key,
    required this.label,
    required this.icon,
  });

  /// DB category string key (e.g. 'images')
  final String key;
  final String label;
  final IconData icon;

  static const List<VaultCategory> all = [
    VaultCategory(key: 'all',       label: 'הכל',        icon: Icons.grid_view_rounded),
    VaultCategory(key: 'images',    label: 'תמונות',     icon: Icons.image_rounded),
    VaultCategory(key: 'videos',    label: 'סרטונים',    icon: Icons.videocam_rounded),
    VaultCategory(key: 'documents', label: 'מסמכים',     icon: Icons.description_rounded),
    VaultCategory(key: 'others',    label: 'אחרים',      icon: Icons.insert_drive_file_rounded),
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VaultCategory && runtimeType == other.runtimeType && key == other.key;

  @override
  int get hashCode => key.hashCode;
}
