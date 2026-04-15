import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart'; // compute()

import '../../core/constants/security_constants.dart';
import '../../core/errors/app_exceptions.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Top-level functions (required for Flutter compute() isolate)
// ═══════════════════════════════════════════════════════════════════════════════

/// PBKDF2-HMAC-SHA256 implementation using the `crypto` package.
/// Runs in a separate isolate to avoid blocking the UI thread.
Uint8List _pbkdf2Worker(Map<String, dynamic> params) {
  final password   = params['password'] as String;
  final salt       = params['salt']     as Uint8List;
  final iterations = params['iterations'] as int;
  final keyLength  = params['keyLength']  as int;

  final passwordBytes = utf8.encode(password);
  final blocks        = (keyLength / 32).ceil();
  final result        = <int>[];

  for (var i = 1; i <= blocks; i++) {
    // Build U₁ = HMAC-SHA256(password, salt || INT(i))
    final saltWithCounter = Uint8List(salt.length + 4);
    saltWithCounter.setAll(0, salt);
    saltWithCounter[salt.length]     = (i >> 24) & 0xFF;
    saltWithCounter[salt.length + 1] = (i >> 16) & 0xFF;
    saltWithCounter[salt.length + 2] = (i >>  8) & 0xFF;
    saltWithCounter[salt.length + 3] =  i        & 0xFF;

    var u = Hmac(sha256, passwordBytes).convert(saltWithCounter).bytes;
    final t = List<int>.from(u);

    // Iterations U₂ … Uₙ
    for (var j = 1; j < iterations; j++) {
      u = Hmac(sha256, passwordBytes).convert(u).bytes;
      for (var k = 0; k < t.length; k++) {
        t[k] ^= u[k];
      }
    }
    result.addAll(t);
  }

  return Uint8List.fromList(result.sublist(0, keyLength));
}

/// Encrypts [plaintext] synchronously; called inside an isolate via [_encryptWorker].
Map<String, dynamic> _encryptWorker(Map<String, dynamic> params) {
  final plaintext   = params['plaintext']   as Uint8List;
  final aesKeyBytes = params['aesKey']      as Uint8List;
  final hmacKeyBytes = params['hmacKey']    as Uint8List;

  // Generate random 16-byte IV
  final ivBytes = Uint8List(SecurityConstants.aesIvLength);
  final rng     = Random.secure();
  for (var i = 0; i < ivBytes.length; i++) ivBytes[i] = rng.nextInt(256);

  // AES-256-CBC encrypt
  final key       = enc.Key(aesKeyBytes);
  final iv        = enc.IV(ivBytes);
  final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
  final encrypted = encrypter.encryptBytes(plaintext, iv: iv);

  // HMAC-SHA256 over (IV || ciphertext)  – Encrypt-then-MAC
  final mac = Hmac(sha256, hmacKeyBytes)
      .convert([...ivBytes, ...encrypted.bytes])
      .bytes;

  // Output: IV (16) || HMAC (32) || ciphertext (N)
  final output = Uint8List(
    SecurityConstants.aesIvLength +
    SecurityConstants.hmacLength  +
    encrypted.bytes.length,
  );
  output.setAll(0, ivBytes);
  output.setAll(SecurityConstants.aesIvLength, mac);
  output.setAll(SecurityConstants.aesIvLength + SecurityConstants.hmacLength,
      encrypted.bytes);

  return {'result': output};
}

/// Decrypts [ciphertext] synchronously; called inside an isolate via [_decryptWorker].
Map<String, dynamic> _decryptWorker(Map<String, dynamic> params) {
  final ciphertext   = params['ciphertext']  as Uint8List;
  final aesKeyBytes  = params['aesKey']      as Uint8List;
  final hmacKeyBytes = params['hmacKey']     as Uint8List;

  if (ciphertext.length <
      SecurityConstants.aesIvLength + SecurityConstants.hmacLength + 16) {
    return {'error': 'malformed'};
  }

  final ivBytes  = ciphertext.sublist(0, SecurityConstants.aesIvLength);
  final storedMac = ciphertext.sublist(
      SecurityConstants.aesIvLength,
      SecurityConstants.aesIvLength + SecurityConstants.hmacLength);
  final actualCt = ciphertext.sublist(
      SecurityConstants.aesIvLength + SecurityConstants.hmacLength);

  // Verify HMAC before decrypting (prevents padding-oracle attacks)
  final computedMac = Hmac(sha256, hmacKeyBytes)
      .convert([...ivBytes, ...actualCt])
      .bytes;

  // Constant-time comparison
  var macOk = 0;
  for (var i = 0; i < storedMac.length; i++) macOk |= storedMac[i] ^ computedMac[i];
  if (macOk != 0) return {'error': 'integrity'};

  final key       = enc.Key(aesKeyBytes);
  final iv        = enc.IV(ivBytes);
  final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
  final plain     = encrypter.decryptBytes(enc.Encrypted(actualCt), iv: iv);

  return {'result': Uint8List.fromList(plain)};
}

// ═══════════════════════════════════════════════════════════════════════════════
// EncryptionService
// ═══════════════════════════════════════════════════════════════════════════════

/// Handles all cryptographic operations for the vault.
///
/// Security design:
/// - Key derivation : PBKDF2-HMAC-SHA256, 100 000 iterations
/// - File encryption: AES-256-CBC (authenticated with HMAC-SHA256 = Encrypt-then-MAC)
/// - Keys split     : first 32 bytes = AES key, last 32 bytes = HMAC key
///
/// Heavy operations run in a background isolate via [compute()].
class EncryptionService {
  // ── Key Derivation ─────────────────────────────────────────────────────────

  /// Generates a cryptographically random salt.
  Uint8List generateSalt() {
    final rng  = Random.secure();
    final salt = Uint8List(SecurityConstants.saltLength);
    for (var i = 0; i < salt.length; i++) salt[i] = rng.nextInt(256);
    return salt;
  }

  /// Derives a 64-byte master key from [pin] and [salt].
  /// Runs in a background isolate (blocks UI until done but doesn't freeze it).
  Future<Uint8List> deriveKey(String pin, Uint8List salt) async {
    return compute(_pbkdf2Worker, {
      'password':   pin,
      'salt':       salt,
      'iterations': SecurityConstants.pbkdf2Iterations,
      'keyLength':  SecurityConstants.derivedKeyLength,
    });
  }

  /// Extracts the 32-byte AES subkey from a 64-byte master key.
  Uint8List aesKeyFrom(Uint8List masterKey) =>
      masterKey.sublist(0, SecurityConstants.aesKeyLength);

  /// Extracts the 32-byte HMAC subkey from a 64-byte master key.
  Uint8List hmacKeyFrom(Uint8List masterKey) =>
      masterKey.sublist(SecurityConstants.aesKeyLength);

  // ── PIN Hashing ────────────────────────────────────────────────────────────

  /// Returns a base64-encoded hash of the master key for PIN verification.
  /// We hash the master key itself (not the PIN) so the PIN is never stored.
  String hashMasterKey(Uint8List masterKey) =>
      base64.encode(sha256.convert(masterKey).bytes);

  /// Verifies a candidate PIN against a stored master-key hash.
  Future<bool> verifyPin(
      String pin, Uint8List salt, String storedHash) async {
    final derived = await deriveKey(pin, salt);
    final candidate = hashMasterKey(derived);
    // Constant-time string comparison
    if (candidate.length != storedHash.length) return false;
    var diff = 0;
    for (var i = 0; i < candidate.length; i++) {
      diff |= candidate.codeUnitAt(i) ^ storedHash.codeUnitAt(i);
    }
    return diff == 0;
  }

  // ── File Encryption ────────────────────────────────────────────────────────

  /// Encrypts [plaintext] with the given [masterKey] (64 bytes).
  /// Returns the encrypted blob: `[16-byte IV][32-byte HMAC][ciphertext]`.
  Future<Uint8List> encryptBytes(Uint8List plaintext, Uint8List masterKey) async {
    final result = await compute(_encryptWorker, {
      'plaintext': plaintext,
      'aesKey':    aesKeyFrom(masterKey),
      'hmacKey':   hmacKeyFrom(masterKey),
    });
    if (result.containsKey('error')) {
      throw const EncryptionException();
    }
    return result['result'] as Uint8List;
  }

  /// Decrypts an encrypted blob produced by [encryptBytes].
  /// Verifies HMAC integrity before decrypting (Encrypt-then-MAC).
  Future<Uint8List> decryptBytes(Uint8List ciphertext, Uint8List masterKey) async {
    final result = await compute(_decryptWorker, {
      'ciphertext': ciphertext,
      'aesKey':     aesKeyFrom(masterKey),
      'hmacKey':    hmacKeyFrom(masterKey),
    });
    if (result.containsKey('error')) {
      if (result['error'] == 'integrity') throw const IntegrityViolationException();
      throw const DecryptionException();
    }
    return result['result'] as Uint8List;
  }
}
