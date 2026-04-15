import 'package:flutter/foundation.dart';
import '../core/constants/security_constants.dart';
import '../data/services/secure_storage_service.dart';

/// Manages user-configurable settings.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider({required this.storageService});

  final SecureStorageService storageService;

  int _autoLockTimeout = SecurityConstants.autoLockTimeoutMin;

  int get autoLockTimeout => _autoLockTimeout;

  Future<void> load() async {
    _autoLockTimeout = await storageService.getAutoLockTimeout();
    notifyListeners();
  }

  Future<void> setAutoLockTimeout(int minutes) async {
    await storageService.setAutoLockTimeout(minutes);
    _autoLockTimeout = minutes;
    notifyListeners();
  }
}
