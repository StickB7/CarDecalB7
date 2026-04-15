import 'package:flutter/material.dart';

import '../../core/utils/file_utils.dart';
import '../../data/models/vault_file.dart';
import '../theme/app_theme.dart';

/// Displays a single vault file in a list.
class FileTileWidget extends StatelessWidget {
  const FileTileWidget({
    super.key,
    required this.file,
    required this.onTap,
    this.onDelete,
    this.onRename,
  });

  final VaultFile    file;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onRename;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap:   onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: AppTheme.cardDecoration,
        padding:    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // File type icon
            Container(
              width:  48,
              height: 48,
              decoration: BoxDecoration(
                color:        AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border:       Border.all(color: AppTheme.border),
              ),
              child: Icon(
                _iconFor(file.mimeType),
                color: _colorFor(file.category),
                size:  24,
              ),
            ),
            const SizedBox(width: 14),

            // Name + metadata
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.originalName,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        FileUtils.formatSize(file.fileSize),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width:  4,
                        height: 4,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.textTertiary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        FileUtils.formatDate(file.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Actions menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert,
                  color: AppTheme.textTertiary, size: 20),
              color:     AppTheme.surfaceVariant,
              shape:     RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppTheme.border),
              ),
              itemBuilder: (_) => [
                if (onRename != null)
                  const PopupMenuItem(
                    value: 'rename',
                    child: Row(children: [
                      Icon(Icons.edit_outlined, color: AppTheme.textSecondary, size: 18),
                      SizedBox(width: 10),
                      Text('שינוי שם', style: TextStyle(color: AppTheme.textPrimary)),
                    ]),
                  ),
                if (onDelete != null)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline, color: AppTheme.error, size: 18),
                      SizedBox(width: 10),
                      Text('מחיקה', style: TextStyle(color: AppTheme.error)),
                    ]),
                  ),
              ],
              onSelected: (v) {
                if (v == 'rename') onRename?.call();
                if (v == 'delete') onDelete?.call();
              },
            ),
          ],
        ),
      ),
    );
  }

  static IconData _iconFor(String mime) {
    final m = mime.toLowerCase();
    if (m.startsWith('image/'))  return Icons.image_rounded;
    if (m.startsWith('video/'))  return Icons.videocam_rounded;
    if (m == 'application/pdf') return Icons.picture_as_pdf_rounded;
    if (m.startsWith('text/'))   return Icons.article_rounded;
    if (m.contains('word') || m.contains('document')) return Icons.description_rounded;
    if (m.contains('sheet') || m.contains('excel'))   return Icons.table_chart_rounded;
    return Icons.insert_drive_file_rounded;
  }

  static Color _colorFor(String category) {
    switch (category) {
      case 'images':    return const Color(0xFF4FC3F7);
      case 'videos':    return const Color(0xFFFF8A65);
      case 'documents': return const Color(0xFF81C784);
      default:          return AppTheme.textSecondary;
    }
  }
}
