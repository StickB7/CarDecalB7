/// Base class for all app-level exceptions.
abstract class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

// ── Authentication Exceptions ────────────────────────────────────────────────

class WrongPinException extends AppException {
  const WrongPinException(int remainingAttempts)
      : super('קוד PIN שגוי. נותרו $remainingAttempts ניסיונות.');
}

class AccountLockedException extends AppException {
  const AccountLockedException(int minutes)
      : super('הגישה נחסמה ל-$minutes דקות לאחר ניסיונות כניסה שגויים.');
}

class BiometricNotAvailableException extends AppException {
  const BiometricNotAvailableException()
      : super('אימות ביומטרי אינו זמין במכשיר זה.');
}

class BiometricFailedException extends AppException {
  const BiometricFailedException()
      : super('אימות ביומטרי נכשל. נסה שוב.');
}

// ── Encryption Exceptions ────────────────────────────────────────────────────

class EncryptionException extends AppException {
  const EncryptionException([String detail = ''])
      : super('שגיאת הצפנה${detail.isEmpty ? '' : ': $detail'}');
}

class DecryptionException extends AppException {
  const DecryptionException([String detail = ''])
      : super('שגיאת פענוח${detail.isEmpty ? '' : ': $detail'}');
}

class IntegrityViolationException extends AppException {
  const IntegrityViolationException()
      : super('בדיקת שלמות הקובץ נכשלה – הקובץ עלול להיות פגום.');
}

// ── File / Vault Exceptions ──────────────────────────────────────────────────

class FileImportException extends AppException {
  const FileImportException([String detail = ''])
      : super('שגיאה ביבוא הקובץ${detail.isEmpty ? '' : ': $detail'}');
}

class FileNotFoundException extends AppException {
  const FileNotFoundException(String name)
      : super('הקובץ "$name" לא נמצא.');
}

class StorageException extends AppException {
  const StorageException([String detail = ''])
      : super('שגיאת אחסון${detail.isEmpty ? '' : ': $detail'}');
}
