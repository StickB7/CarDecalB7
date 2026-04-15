import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/security_constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/vault_provider.dart';
import '../../theme/app_theme.dart';
import '../auth/setup_pin_screen.dart';

/// Settings screen: biometric, auto-lock timeout, change PIN, and reset.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('הגדרות')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _sectionTitle('אבטחה'),
          _buildBiometricTile(),
          const SizedBox(height: 10),
          _buildAutoLockTile(),
          const SizedBox(height: 10),
          _buildChangePinTile(),
          const SizedBox(height: 28),
          _sectionTitle('אחסון'),
          _buildStorageInfoTile(),
          const SizedBox(height: 28),
          _sectionTitle('סכנה'),
          _buildResetTile(),
        ],
      ),
    );
  }

  // ── Biometric ──────────────────────────────────────────────────────────────

  Widget _buildBiometricTile() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final available = auth.biometricAvailable;
        return _SettingTile(
          icon:    Icons.fingerprint_rounded,
          title:   'כניסה ביומטרית',
          subtitle: available
              ? 'כניסה עם טביעת אצבע / Face ID'
              : 'לא נתמך במכשיר זה',
          trailing: Switch(
            value:      available && auth.biometricEnabled,
            onChanged:  available
                ? (v) => auth.setBiometricEnabled(v)
                : null,
            activeColor: AppTheme.gold,
          ),
        );
      },
    );
  }

  // ── Auto-lock ──────────────────────────────────────────────────────────────

  Widget _buildAutoLockTile() {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final options = [1, 2, 5, 10, 15, 30];
        return _SettingTile(
          icon:    Icons.timer_outlined,
          title:   'נעילה אוטומטית',
          subtitle: 'כיום: ${settings.autoLockTimeout} דקות',
          trailing: PopupMenuButton<int>(
            icon:  const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textSecondary),
            color:  AppTheme.surfaceVariant,
            shape:  RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppTheme.border),
            ),
            initialValue: settings.autoLockTimeout,
            itemBuilder: (_) => options.map((m) {
              return PopupMenuItem(
                value: m,
                child: Text(
                  '$m דקות',
                  style: TextStyle(
                    color: m == settings.autoLockTimeout
                        ? AppTheme.gold
                        : AppTheme.textPrimary,
                  ),
                ),
              );
            }).toList(),
            onSelected: (m) => settings.setAutoLockTimeout(m),
          ),
        );
      },
    );
  }

  // ── Change PIN ─────────────────────────────────────────────────────────────

  Widget _buildChangePinTile() {
    return _SettingTile(
      icon:    Icons.pin_outlined,
      title:   'שינוי קוד PIN',
      subtitle: 'עדכן את קוד ה-PIN שלך',
      trailing: const Icon(Icons.chevron_right_rounded,
          color: AppTheme.textSecondary),
      onTap: _changePinFlow,
    );
  }

  Future<void> _changePinFlow() async {
    // Navigate to setup flow which handles old-PIN verification internally
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.border),
        ),
        title: const Text('שינוי קוד PIN'),
        content: const Text(
            'תועבר לתהליך יצירת קוד PIN חדש.\nהמשך?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ביטול'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('המשך'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SetupPinScreen()),
    );
  }

  // ── Storage info ───────────────────────────────────────────────────────────

  Widget _buildStorageInfoTile() {
    return Consumer<VaultProvider>(
      builder: (context, vault, _) {
        final total = vault.files.fold<int>(0, (sum, f) => sum + f.fileSize);
        final count = vault.files.length;
        return _SettingTile(
          icon:    Icons.storage_outlined,
          title:   'אחסון',
          subtitle: '$count קבצים',
        );
      },
    );
  }

  // ── Reset vault ────────────────────────────────────────────────────────────

  Widget _buildResetTile() {
    return _SettingTile(
      icon:       Icons.delete_forever_rounded,
      iconColor:  AppTheme.error,
      title:      'איפוס מלא',
      titleColor: AppTheme.error,
      subtitle:   'מחיקת כל הקבצים ואיפוס ה-PIN',
      onTap:      _confirmReset,
    );
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppTheme.error.withOpacity(0.4)),
        ),
        title: const Text('איפוס מלא',
            style: TextStyle(color: AppTheme.error)),
        content: const Text(
          'פעולה זו תמחק את כל הקבצים המאוחסנים ואת קוד ה-PIN. '
          'הפעולה אינה ניתנת לביטול.\n\nהאם אתה בטוח?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:     const Text('ביטול'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style:     TextButton.styleFrom(foregroundColor: AppTheme.error),
            child:     const Text('מחק הכל'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await context.read<VaultProvider>().vaultRepository.deleteAllFiles();
    await context.read<AuthProvider>().authRepository.resetAll();
    if (!mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppConstants.routeSetupPin, (_) => false);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge,
      ),
    );
  }
}

// ── Shared tile widget ─────────────────────────────────────────────────────────

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.titleColor,
  });

  final IconData  icon;
  final String    title;
  final String?   subtitle;
  final Widget?   trailing;
  final VoidCallback? onTap;
  final Color?    iconColor;
  final Color?    titleColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap:        onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: AppTheme.cardDecoration,
        child: Row(
          children: [
            Container(
              width:  40,
              height: 40,
              decoration: BoxDecoration(
                color:        AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  color: iconColor ?? AppTheme.textSecondary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: titleColor,
                      )),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
