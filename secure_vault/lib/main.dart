import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/vault_repository.dart';
import 'data/services/biometric_service.dart';
import 'data/services/database_service.dart';
import 'data/services/encryption_service.dart';
import 'data/services/secure_storage_service.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/vault_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Enforce portrait orientation ─────────────────────────────────────────
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── System UI styling (immersive dark) ───────────────────────────────────
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:         Colors.transparent,
    statusBarBrightness:    Brightness.dark,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor:     Color(0xFF0D0D0F),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // ── Dependency wiring ────────────────────────────────────────────────────
  final encryptionService  = EncryptionService();
  final storageService     = SecureStorageService();
  final biometricService   = BiometricService();
  final databaseService    = DatabaseService();

  final authRepository  = AuthRepository(
    encryptionService: encryptionService,
    storageService:    storageService,
    biometricService:  biometricService,
  );

  final vaultRepository = VaultRepository(
    databaseService:   databaseService,
    encryptionService: encryptionService,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authRepository: authRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => VaultProvider(vaultRepository: vaultRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(storageService: storageService),
        ),
      ],
      child: const SecureVaultApp(),
    ),
  );
}
