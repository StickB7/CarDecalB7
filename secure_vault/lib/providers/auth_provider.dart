import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import '../core/constants/security_constants.dart';
import '../core/errors/app_exceptions.dart';
import '../data/repositories/auth_repository.dart';
import '../data/services/auto_lock_service.dart';

enum AuthStatus {
  initial,
  needsSetup,
  unauthenticated,
  loading,
  authenticated,
  lockedOut,
}

/// Central authentication state for the entire app.
///
/// Also acts as [WidgetsBindingObserver] to lock on app-background.
class AuthProvider extends ChangeNotifier implements WidgetsBindingObserver {
  AuthProvider({required this.authRepository}) {
    _autoLock = AutoLockService(onLock: _triggerLock);
    WidgetsBinding.instance.addObserver(this);
  }

  final AuthRepository authRepository;

  // ── State ──────────────────────────────────────────────────────────────────

  AuthStatus  _status       = AuthStatus.initial;
  Uint8List?  _masterKey;
  String?     _errorMessage;
  bool        _biometricAvailable = false;
  bool        _biometricEnabled   = false;
  DateTime?   _lockoutExpiry;
  late final AutoLockService _autoLock;

  AuthStatus  get status            => _status;
  bool        get isAuthenticated   => _status == AuthStatus.authenticated;
  String?     get errorMessage      => _errorMessage;
  bool        get biometricAvailable => _biometricAvailable;
  bool        get biometricEnabled   => _biometricEnabled;
  DateTime?   get lockoutExpiry      => _lockoutExpiry;

  /// The decrypted master key – only non-null while authenticated.
  Uint8List?  get masterKey         => _masterKey;

  // ── Initialisation ─────────────────────────────────────────────────────────

  Future<void> initialize() async {
    _status = AuthStatus.loading;
    notifyListeners();

    final setup    = await authRepository.isSetupComplete();
    _biometricAvailable = await authRepository.isBiometricAvailable();
    _biometricEnabled   = await authRepository.isBiometricEnabled();

    if (!setup) {
      _status = AuthStatus.needsSetup;
    } else if (await authRepository.isLockedOut()) {
      _status       = AuthStatus.lockedOut;
      _lockoutExpiry = await authRepository.lockoutExpiry();
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  // ── Authentication ─────────────────────────────────────────────────────────

  /// First-time PIN creation.
  Future<bool> setupPin(String pin) async {
    _clearError();
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      _masterKey = await authRepository.setupPin(pin);
      _status    = AuthStatus.authenticated;
      _startAutoLock();
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _setError(e.message);
      return false;
    }
  }

  Future<bool> loginWithPin(String pin) async {
    _clearError();
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      _masterKey = await authRepository.authenticateWithPin(pin);
      _status    = AuthStatus.authenticated;
      _startAutoLock();
      notifyListeners();
      return true;
    } on AccountLockedException catch (e) {
      _lockoutExpiry = await authRepository.lockoutExpiry();
      _setError(e.message, status: AuthStatus.lockedOut);
      return false;
    } on AppException catch (e) {
      _status = AuthStatus.unauthenticated;
      _setError(e.message);
      return false;
    }
  }

  Future<bool> loginWithBiometric() async {
    _clearError();
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      _masterKey = await authRepository.authenticateWithBiometric();
      _status    = AuthStatus.authenticated;
      _startAutoLock();
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _status = AuthStatus.unauthenticated;
      _setError(e.message);
      return false;
    }
  }

  // ── Lock / Logout ──────────────────────────────────────────────────────────

  void lock() {
    _autoLock.stop();
    _securelyClearKey();
    _status = AuthStatus.unauthenticated;
    _clearError();
    notifyListeners();
  }

  void resetActivity() => _autoLock.resetTimer();

  // ── Settings ───────────────────────────────────────────────────────────────

  Future<void> setBiometricEnabled(bool enabled) async {
    await authRepository.setBiometricEnabled(enabled);
    _biometricEnabled = enabled;
    notifyListeners();
  }

  Future<bool> changePin(String oldPin, String newPin) async {
    try {
      await authRepository.changePin(oldPin, newPin);
      return true;
    } on AppException catch (e) {
      _setError(e.message);
      return false;
    }
  }

  // ── App Lifecycle (WidgetsBindingObserver) ─────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // Lock immediately when app goes to background/task-switcher
        if (_status == AuthStatus.authenticated) lock();
        break;
      case AppLifecycleState.resumed:
        // UI will react to _status = unauthenticated and show auth screen
        break;
      default:
        break;
    }
  }

  // Required WidgetsBindingObserver stubs
  @override void didChangeAccessibilityFeatures()             {}
  @override void didChangeLocales(List<Locale>? locales)      {}
  @override void didChangeMetrics()                           {}
  @override void didChangePlatformBrightness()                {}
  @override void didChangeTextScaleFactor()                   {}
  @override void didHaveMemoryPressure()                      {}
  @override void didPopRoute()                                {}
  @override Future<bool> didPushRoute(String route)           async => false;
  @override Future<bool> didPushRouteInformation(RouteInformation ri) async => false;
  @override void didRequestAppExit()                          {}
  @override void handleCancelBackGesture()                    {}
  @override void handleCommitBackGesture()                    {}
  @override bool handleStartBackGesture(PredictiveBackEvent e) => false;
  @override void handleUpdateBackGestureProgress(PredictiveBackEvent e) {}

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _triggerLock() {
    if (_status == AuthStatus.authenticated) lock();
  }

  void _startAutoLock() {
    final timeout = SecurityConstants.autoLockTimeoutMin;
    _autoLock.setTimeout(timeout);
    _autoLock.start();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void _setError(String msg, {AuthStatus? status}) {
    _errorMessage = msg;
    if (status != null) _status = status;
    notifyListeners();
  }

  /// Overwrite the master key bytes before nullifying to reduce in-memory exposure.
  void _securelyClearKey() {
    if (_masterKey != null) {
      for (var i = 0; i < _masterKey!.length; i++) _masterKey![i] = 0;
      _masterKey = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoLock.stop();
    _securelyClearKey();
    super.dispose();
  }
}
