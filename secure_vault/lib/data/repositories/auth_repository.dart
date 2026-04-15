import 'dart:typed_data';

import '../services/biometric_service.dart';
import '../services/encryption_service.dart';
import '../services/secure_storage_service.dart';
import '../../core/constants/security_constants.dart';
import '../../core/errors/app_exceptions.dart';

/// High-level authentication operations.
/// Sits between the low-level services and the AuthProvider.
class AuthRepository {
  AuthRepository({
    required this.encryptionService,
    required this.storageService,
    required this.biometricService,
  });

  final EncryptionService    encryptionService;
  final SecureStorageService storageService;
  final BiometricService     biometricService;

  // ── First-time Setup ───────────────────────────────────────────────────────

  /// Sets up a new vault with [pin].
  /// Derives a master key, hashes it for verification, and stores everything.
  /// Returns the derived master key so the caller can open the vault immediately.
  Future<Uint8List> setupPin(String pin) async {
    final salt      = encryptionService.generateSalt();
    final masterKey = await encryptionService.deriveKey(pin, salt);
    final pinHash   = encryptionService.hashMasterKey(masterKey);

    await storageService.setSalt(salt);
    await storageService.setPinHash(pinHash);
    await storageService.setMasterKey(masterKey); // Used for biometric auth
    await storageService.setSetupComplete(true);
    await storageService.setFailedAttempts(0);
    await storageService.setLockedUntil(null);

    return masterKey;
  }

  // ── PIN Authentication ─────────────────────────────────────────────────────

  /// Verifies [pin] and returns the master key on success.
  ///
  /// Throws [AccountLockedException] if locked out.
  /// Throws [WrongPinException]      if PIN is incorrect.
  Future<Uint8List> authenticateWithPin(String pin) async {
    // 1. Lockout check
    final lockedUntil = await storageService.getLockedUntil();
    if (lockedUntil != null && DateTime.now().isBefore(lockedUntil)) {
      final remaining = lockedUntil.difference(DateTime.now()).inMinutes + 1;
      throw AccountLockedException(remaining);
    }

    // 2. Derive and compare
    final salt    = await storageService.getSalt();
    final stored  = await storageService.getPinHash();
    if (salt == null || stored == null) throw const StorageException('No PIN configured');

    final valid = await encryptionService.verifyPin(pin, salt, stored);

    if (!valid) {
      // Increment failed attempts
      final attempts = await storageService.getFailedAttempts() + 1;
      await storageService.setFailedAttempts(attempts);

      final remaining = SecurityConstants.maxFailedAttempts - attempts;
      if (attempts >= SecurityConstants.maxFailedAttempts) {
        final lockUntil = DateTime.now()
            .add(Duration(minutes: SecurityConstants.lockoutDurationMin));
        await storageService.setLockedUntil(lockUntil);
        await storageService.setFailedAttempts(0);
        throw AccountLockedException(SecurityConstants.lockoutDurationMin);
      }
      throw WrongPinException(remaining);
    }

    // 3. Success – reset counters
    await storageService.setFailedAttempts(0);
    await storageService.setLockedUntil(null);

    // 4. Derive and return master key
    final masterKey = await encryptionService.deriveKey(pin, salt);
    // Update stored master key (for biometric auth)
    await storageService.setMasterKey(masterKey);
    return masterKey;
  }

  // ── Biometric Authentication ───────────────────────────────────────────────

  /// Authenticates via biometrics and returns the stored master key.
  /// The master key is stored in the secure enclave-backed storage and is
  /// only retrievable after biometric verification.
  Future<Uint8List> authenticateWithBiometric() async {
    await biometricService.authenticate(); // Throws on failure

    final masterKey = await storageService.getMasterKey();
    if (masterKey == null) {
      throw const StorageException('Master key not available for biometric auth');
    }
    return masterKey;
  }

  // ── Queries ────────────────────────────────────────────────────────────────

  Future<bool> isSetupComplete()    => storageService.isSetupComplete();
  Future<bool> isBiometricEnabled() => storageService.isBiometricEnabled();
  Future<bool> isBiometricAvailable() => biometricService.isAvailable();

  Future<bool> isLockedOut() async {
    final lockedUntil = await storageService.getLockedUntil();
    return lockedUntil != null && DateTime.now().isBefore(lockedUntil);
  }

  Future<DateTime?> lockoutExpiry() => storageService.getLockedUntil();

  // ── Settings ───────────────────────────────────────────────────────────────

  Future<void> setBiometricEnabled(bool enabled) =>
      storageService.setBiometricEnabled(enabled);

  Future<void> changePin(String oldPin, String newPin) async {
    // Verify old PIN first
    await authenticateWithPin(oldPin);
    await setupPin(newPin);
  }

  /// Wipes all auth data. Use only to reset the vault.
  Future<void> resetAll() => storageService.deleteAll();
}
