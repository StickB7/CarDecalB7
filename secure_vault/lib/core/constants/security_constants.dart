/// Security-related constants.
/// Changing these values will invalidate existing encrypted data.
class SecurityConstants {
  SecurityConstants._();

  // ── PIN / Auth ───────────────────────────────────────────────────────────
  static const int pinLength           = 6;
  static const int maxFailedAttempts   = 5;
  /// Lockout duration in minutes after max failed attempts
  static const int lockoutDurationMin  = 5;
  /// Inactivity timeout before auto-lock (minutes)
  static const int autoLockTimeoutMin  = 2;

  // ── PBKDF2 Key Derivation ─────────────────────────────────────────────────
  /// Iterations – high enough to be slow (~200 ms on modern hardware)
  static const int   pbkdf2Iterations = 100000;
  /// Total derived key length in bytes (32 AES key + 32 HMAC key)
  static const int   derivedKeyLength = 64;
  /// Salt length in bytes
  static const int   saltLength       = 32;

  // ── AES-256-CBC ───────────────────────────────────────────────────────────
  static const int aesKeyLength = 32;   // 256 bits
  static const int aesIvLength  = 16;   // 128-bit IV
  static const int hmacLength   = 32;   // HMAC-SHA256 output

  // ── Secure Storage Keys ───────────────────────────────────────────────────
  static const String sskPinHash         = 'pin_hash';
  static const String sskSalt            = 'kdf_salt';
  static const String sskMasterKey       = 'master_key_b64';
  static const String sskBiometricEnabled = 'biometric_enabled';
  static const String sskAutoLockTimeout  = 'auto_lock_timeout';
  static const String sskIsSetupComplete  = 'setup_complete';
  static const String sskFailedAttempts   = 'failed_attempts';
  static const String sskLockedUntil      = 'locked_until';
}
