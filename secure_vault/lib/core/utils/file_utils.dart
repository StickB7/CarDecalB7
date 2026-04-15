import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';

/// Utility helpers for file-related operations.
class FileUtils {
  FileUtils._();

  /// Returns the vault category for a given MIME type.
  static String categoryFromMime(String mime) {
    final m = mime.toLowerCase();
    if (AppConstants.imageMimes.contains(m)) return 'images';
    if (AppConstants.videoMimes.contains(m)) return 'videos';
    if (AppConstants.documentMimes.contains(m)) return 'documents';
    return 'others';
  }

  /// Human-readable file size (bytes → KB / MB / GB).
  static String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Formats a DateTime as a Hebrew-friendly date string.
  static String formatDate(DateTime dt) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  }

  /// Icon name (asset key) based on MIME type.
  static String iconForMime(String mime) {
    final m = mime.toLowerCase();
    if (AppConstants.imageMimes.contains(m)) return 'image';
    if (AppConstants.videoMimes.contains(m)) return 'video';
    if (m == 'application/pdf') return 'pdf';
    if (AppConstants.documentMimes.contains(m)) return 'document';
    return 'file';
  }

  /// Returns a safe file extension from a MIME type.
  static String extensionFromMime(String mime) {
    const map = {
      'image/jpeg': 'jpg',
      'image/png': 'png',
      'image/gif': 'gif',
      'image/webp': 'webp',
      'image/heic': 'heic',
      'video/mp4': 'mp4',
      'video/quicktime': 'mov',
      'video/x-msvideo': 'avi',
      'application/pdf': 'pdf',
      'text/plain': 'txt',
    };
    return map[mime.toLowerCase()] ?? 'bin';
  }
}
