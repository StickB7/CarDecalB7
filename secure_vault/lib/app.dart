import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'presentation/screens/auth/auth_screen.dart';
import 'presentation/screens/auth/setup_pin_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/vault/vault_home_screen.dart';
import 'presentation/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/vault_provider.dart';

/// Root application widget.
/// Rebuilds the navigator when [AuthProvider] changes to handle lock/unlock.
class SecureVaultApp extends StatelessWidget {
  const SecureVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:            AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme:            AppTheme.dark,

      // RTL support for Hebrew
      locale:           const Locale('he', 'IL'),
      supportedLocales: const [Locale('he', 'IL'), Locale('en', 'US')],
      localizationsDelegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],

      // Global scroll physics – natural feel on both platforms
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: _SecurityOverlay(child: child ?? const SizedBox.shrink()),
        );
      },

      initialRoute: AppConstants.routeSplash,
      routes: {
        AppConstants.routeSplash:   (_) => const SplashScreen(),
        AppConstants.routeSetupPin: (_) => const SetupPinScreen(),
        AppConstants.routeAuth:     (_) => const AuthScreen(),
        AppConstants.routeVault:    (_) => const VaultHomeScreen(),
        AppConstants.routeSettings: (_) => const SettingsScreen(),
      },
    );
  }
}

// ── Security overlay ───────────────────────────────────────────────────────────
// Shows an opaque splash when the app becomes inactive/paused,
// hiding vault content from the iOS/Android task switcher.

class _SecurityOverlay extends StatefulWidget {
  const _SecurityOverlay({required this.child});
  final Widget child;

  @override
  State<_SecurityOverlay> createState() => _SecurityOverlayState();
}

class _SecurityOverlayState extends State<_SecurityOverlay>
    with WidgetsBindingObserver {
  bool _showOverlay = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Show overlay as soon as the app is leaving the foreground
    final shouldShow = state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused;
    if (_showOverlay != shouldShow) {
      setState(() => _showOverlay = shouldShow);
    }
  }

  // WidgetsBindingObserver stubs
  @override void didChangeAccessibilityFeatures()          {}
  @override void didChangeLocales(List<Locale>? l)         {}
  @override void didChangeMetrics()                        {}
  @override void didChangePlatformBrightness()             {}
  @override void didChangeTextScaleFactor()                {}
  @override void didHaveMemoryPressure()                   {}
  @override void didPopRoute()                             {}
  @override Future<bool> didPushRoute(String r) async      => false;
  @override Future<bool> didPushRouteInformation(RouteInformation r) async => false;
  @override void didRequestAppExit()                       {}
  @override void handleCancelBackGesture()                 {}
  @override void handleCommitBackGesture()                 {}
  @override bool handleStartBackGesture(PredictiveBackEvent e) => false;
  @override void handleUpdateBackGestureProgress(PredictiveBackEvent e) {}

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showOverlay) _buildSecurityOverlay(),
      ],
    );
  }

  Widget _buildSecurityOverlay() {
    return Positioned.fill(
      child: Material(
        color: AppTheme.background,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width:  72,
                height: 72,
                decoration: BoxDecoration(
                  gradient:     AppTheme.goldGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.lock_rounded,
                    size: 36, color: Color(0xFF1A1600)),
              ),
              const SizedBox(height: 20),
              Text(
                AppConstants.appName,
                style: const TextStyle(
                  color:      AppTheme.textPrimary,
                  fontSize:   22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'מוגן',
                style: TextStyle(
                  color:    AppTheme.gold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
