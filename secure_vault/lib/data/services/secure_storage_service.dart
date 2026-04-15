import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants/security_constants.dart';

/// Thin wrapper around [FlutterSecureStorage] that provides typed
/// accessors for all security-sensitive values.
///
/// On iOS: values are stored in the Keychain.
/// On Android: values are encrypted with AES-256 using the Android Keystore.
class SecureStorageService {
  static const _options = AndroidOptions(
    encryptedSharedPreferences: true,  // Extra layer on older Android
  );

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: _options,
  );

  // ── Generic helpers ────────────────────────────────────────────────────────

  Future<String?> _read(String key)                   => _storage.read(key: key);
  Future<void>    _write(String key, String value)    => _storage.write(key: key, value: value);
  Future<void>    _delete(String key)                 => _storage.delete(key: key);

  // ── Setup Flag ─────────────────────────────────────────────────────────────

  Future<bool>  isSetupComplete() async =>
      (await _read(SecurityConstants.sskIsSetupComplete)) == 'true';
  Future<void>  setSetupComplete(bool v) =>
      _write(SecurityConstants.sskIsSetupComplete, v.toString());

  // ── PIN Hash & Salt ────────────────────────────────────────────────────────

  Future<String?> getPinHash()             => _read(SecurityConstants.sskPinHash);
  Future<void>    setPinHash(String hash)  => _write(SecurityConstants.sskPinHash, hash);

  Future<Uint8List?> getSalt() async {
    final b64 = await _read(SecurityConstants.sskSalt);
    return b64 == null ? null : base64.decode(b64);
  }

  Future<void> setSalt(Uint8List salt) =>
      _write(SecurityConstants.sskSalt, base64.encode(salt));

  // ── Master Key (for biometric unlock) ─────────────────────────────────────

  /// Stores the 64-byte master key so it can be retrieved after biometric auth.
  Future<void> setMasterKey(Uint8List key) =>
      _write(SecurityConstants.sskMasterKey, base64.encode(key));

  Future<Uint8List?> getMasterKey() async {
    final b64 = await _read(SecurityConstants.sskMasterKey);
    return b64 == null ? null : base64.decode(b64);
  }

  Future<void> deleteMasterKey() => _delete(SecurityConstants.sskMasterKey);

  // ── Biometric Flag ─────────────────────────────────────────────────────────

  Future<bool>  isBiometricEnabled() async =>
      (await _read(SecurityConstants.sskBiometricEnabled)) == 'true';
  Future<void>  setBiometricEnabled(bool v) =>
      _write(SecurityConstants.sskBiometricEnabled, v.toString());

  // ── Failed Attempts & Lockout ──────────────────────────────────────────────

  Future<int> getFailedAttempts() async {
    final raw = await _read(SecurityConstants.sskFailedAttempts);
    return int.tryParse(raw ?? '0') ?? 0;
  }

  Future<void> setFailedAttempts(int count) =>
      _write(SecurityConstants.sskFailedAttempts, count.toString());

  Future<DateTime?> getLockedUntil() async {
    final raw = await _read(SecurityConstants.sskLockedUntil);
    if (raw == null) return null;
    final ms = int.tryParse(raw);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> setLockedUntil(DateTime? dt) async {
    if (dt == null) {
      await _delete(SecurityConstants.sskLockedUntil);
    } else {
      await _write(SecurityConstants.sskLockedUntil,
          dt.millisecondsSinceEpoch.toString());
    }
  }

  // ── Auto-lock Timeout ──────────────────────────────────────────────────────

  Future<int> getAutoLockTimeout() async {
    final raw = await _read(SecurityConstants.sskAutoLockTimeout);
    return int.tryParse(raw ?? '') ?? SecurityConstants.autoLockTimeoutMin;
  }

  Future<void> setAutoLockTimeout(int minutes) =>
      _write(SecurityConstants.sskAutoLockTimeout, minutes.toString());

  // ── Nuclear option: wipe all secure data ──────────────────────────────────

  Future<void> deleteAll() => _storage.deleteAll();
}
