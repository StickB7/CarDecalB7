import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/vault_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/pin_input_widget.dart';

/// Login screen: PIN entry with optional biometric shortcut.
/// Handles lockout countdown and failed-attempt feedback.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool     _isLoading  = false;
  Timer?   _lockTimer;
  int      _lockSecsLeft = 0;

  final _pinKey = GlobalKey<PinInputWidgetState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkLockout());
  }

  void _checkLockout() {
    final auth = context.read<AuthProvider>();
    if (auth.status == AuthStatus.lockedOut && auth.lockoutExpiry != null) {
      _startLockTimer(auth.lockoutExpiry!);
    }
  }

  void _startLockTimer(DateTime expiry) {
    _lockTimer?.cancel();
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      final secs = expiry.difference(DateTime.now()).inSeconds;
      if (!mounted) { t.cancel(); return; }
      setState(() { _lockSecsLeft = secs < 0 ? 0 : secs; });
      if (secs <= 0) {
        t.cancel();
        context.read<AuthProvider>().initialize();
      }
    });
  }

  Future<void> _onPinEntered(String pin) async {
    setState(() { _isLoading = true; });
    final auth = context.read<AuthProvider>();
    final ok   = await auth.loginWithPin(pin);
    if (!mounted) return;
    setState(() { _isLoading = false; });

    if (ok) {
      await context.read<VaultProvider>().loadFiles();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppConstants.routeVault);
    } else {
      _pinKey.currentState?.clear();
      if (auth.status == AuthStatus.lockedOut && auth.lockoutExpiry != null) {
        _startLockTimer(auth.lockoutExpiry!);
      }
    }
  }

  Future<void> _onBiometric() async {
    final auth = context.read<AuthProvider>();
    final ok   = await auth.loginWithBiometric();
    if (!mounted) return;
    if (ok) {
      await context.read<VaultProvider>().loadFiles();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppConstants.routeVault);
    }
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            _buildBody(),
            if (_isLoading) _buildLoadingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final isLocked = auth.status == AuthStatus.lockedOut;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 70),

              // Icon
              Container(
                width:  80,
                height: 80,
                decoration: BoxDecoration(
                  gradient:     AppTheme.goldGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color:      AppTheme.gold.withOpacity(0.3),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.lock_rounded,
                    size: 40, color: Color(0xFF1A1600)),
              ),
              const SizedBox(height: 24),

              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'הכנס קוד PIN כדי לפתוח',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 48),

              // Lockout banner
              if (isLocked)
                _buildLockoutBanner()
              else
                PinInputWidget(
                  key:          _pinKey,
                  onCompleted:  _onPinEntered,
                  errorMessage: auth.errorMessage,
                ),

              // Biometric button
              if (!isLocked &&
                  auth.biometricAvailable &&
                  auth.biometricEnabled) ...[
                const SizedBox(height: 32),
                _buildBiometricButton(),
              ],

              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLockoutBanner() {
    final minutes = (_lockSecsLeft / 60).ceil();
    final secsStr = _lockSecsLeft.toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        AppTheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: AppTheme.error.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          const Icon(Icons.block_rounded, color: AppTheme.error, size: 32),
          const SizedBox(height: 12),
          Text(
            'הגישה נחסמה',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ניסיונות כניסה שגויים רבים מדי.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'נסה שוב בעוד $minutes דקות ($secsStr שניות)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricButton() {
    return OutlinedButton.icon(
      onPressed: _onBiometric,
      icon:  const Icon(Icons.fingerprint_rounded, size: 22),
      label: const Text('כניסה ביומטרית'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: AppTheme.background.withOpacity(0.8),
      child: const Center(
        child: CircularProgressIndicator(color: AppTheme.gold),
      ),
    );
  }
}
