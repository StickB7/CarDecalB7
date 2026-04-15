import 'package:local_auth/local_auth.dart';

import '../../core/errors/app_exceptions.dart';

/// Wraps [LocalAuthentication] with clear error semantics.
class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  // ── Capability Checks ──────────────────────────────────────────────────────

  /// Returns true if the device has biometric hardware AND enrolled credentials.
  Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (_) {
      return false;
    }
  }

  /// Returns available biometric types (fingerprint, face, etc.).
  Future<List<BiometricType>> getAvailableTypes() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  // ── Authentication ─────────────────────────────────────────────────────────

  /// Prompts the user for biometric (or device credentials) authentication.
  ///
  /// Throws [BiometricNotAvailableException] if unavailable.
  /// Throws [BiometricFailedException] if the user cancels or fails.
  Future<void> authenticate() async {
    if (!await isAvailable()) throw const BiometricNotAvailableException();

    bool authenticated;
    try {
      authenticated = await _auth.authenticate(
        localizedReason: 'אמת את זהותך כדי לגשת לתיקייה הנעולה',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,  // Keeps the prompt alive when app goes background
          sensitiveTransaction: true,
        ),
      );
    } catch (_) {
      throw const BiometricFailedException();
    }

    if (!authenticated) throw const BiometricFailedException();
  }
}
