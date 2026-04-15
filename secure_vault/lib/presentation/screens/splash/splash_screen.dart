import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

/// Initial screen shown for ~1.5 seconds while [AuthProvider] initialises.
/// Navigates to setup, auth, or vault based on app state.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _fadeAnim;
  late Animation<double>   _scaleAnim;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnim  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));

    _ctrl.forward();

    // Initialise auth state, then navigate
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      await auth.initialize();
      if (!mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      _navigateBasedOnState(auth.status);
    });
  }

  void _navigateBasedOnState(AuthStatus status) {
    final route = switch (status) {
      AuthStatus.needsSetup    => AppConstants.routeSetupPin,
      AuthStatus.authenticated => AppConstants.routeVault,
      _                        => AppConstants.routeAuth,
    };
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Lock icon with gold gradient shimmer
                Container(
                  width:  96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient:     AppTheme.goldGradient,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color:      AppTheme.gold.withOpacity(0.35),
                        blurRadius: 30,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    size:  48,
                    color: Color(0xFF1A1600),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  AppConstants.appName,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color:       AppTheme.textPrimary,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'מוגן · פרטי · מאובטח',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 48),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color:       AppTheme.gold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
