/// Application-wide constants.
/// Keep all magic strings/numbers here for easy maintenance.
class AppConstants {
  AppConstants._();

  // ── App Identity ────────────────────────────────────────────────────────────
  static const String appName = 'תיקייה נעולה';
  static const String appNameEn = 'Secure Vault';

  // ── Routes ──────────────────────────────────────────────────────────────────
  static const String routeSplash   = '/';
  static const String routeSetupPin = '/setup-pin';
  static const String routeAuth     = '/auth';
  static const String routeVault    = '/vault';
  static const String routeSettings = '/settings';
  static const String routeViewer   = '/viewer';

  // ── Vault directory (inside app documents dir) ────────────────────────────
  static const String vaultDirName     = 'vault_data';
  static const String encryptedFileExt = '.enc';

  // ── Database ─────────────────────────────────────────────────────────────
  static const String dbName    = 'secure_vault.db';
  static const int    dbVersion = 1;

  // ── Supported MIME categories ─────────────────────────────────────────────
  static const List<String> imageMimes = [
    'image/jpeg', 'image/png', 'image/gif',
    'image/webp', 'image/heic', 'image/heif',
  ];
  static const List<String> videoMimes = [
    'video/mp4', 'video/quicktime', 'video/x-msvideo',
    'video/webm', 'video/mpeg',
  ];
  static const List<String> documentMimes = [
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'text/plain',
  ];
}
