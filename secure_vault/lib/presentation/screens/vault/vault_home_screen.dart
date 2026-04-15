import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/vault_file.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/vault_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/category_chip_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/file_tile_widget.dart';
import '../vault/file_viewer_screen.dart';

/// Main vault screen: category tabs + file list + FAB to add files.
class VaultHomeScreen extends StatefulWidget {
  const VaultHomeScreen({super.key});

  @override
  State<VaultHomeScreen> createState() => _VaultHomeScreenState();
}

class _VaultHomeScreenState extends State<VaultHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load files after first frame so providers are available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vault = context.read<VaultProvider>();
      if (vault.status == VaultStatus.initial) vault.loadFiles();
    });
  }

  // ── User interactions ──────────────────────────────────────────────────────

  void _resetActivity() => context.read<AuthProvider>().resetActivity();

  Future<void> _addFiles() async {
    _resetActivity();
    final auth  = context.read<AuthProvider>();
    final vault = context.read<VaultProvider>();
    if (auth.masterKey == null) return;
    final ok = await vault.importFiles(auth.masterKey!);
    if (!mounted) return;
    if (!ok && vault.errorMessage != null) {
      _showSnack(vault.errorMessage!, isError: true);
      vault.clearError();
    }
  }

  void _openFile(VaultFile vf) {
    _resetActivity();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FileViewerScreen(file: vf),
      ),
    );
  }

  Future<void> _deleteFile(VaultFile vf) async {
    final confirmed = await _showDeleteDialog(vf.originalName);
    if (!confirmed) return;
    _resetActivity();
    final vault = context.read<VaultProvider>();
    final ok    = await vault.deleteFile(vf);
    if (!mounted) return;
    if (!ok) _showSnack(vault.errorMessage ?? 'שגיאה', isError: true);
  }

  Future<void> _renameFile(VaultFile vf) async {
    final newName = await _showRenameDialog(vf.originalName);
    if (newName == null || newName.trim().isEmpty) return;
    _resetActivity();
    await context.read<VaultProvider>().renameFile(vf, newName.trim());
  }

  void _lock() {
    context.read<VaultProvider>().clearVault();
    context.read<AuthProvider>().lock();
    Navigator.of(context).pushReplacementNamed(AppConstants.routeAuth);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap:    _resetActivity,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: _buildAppBar(),
        body:   _buildBody(),
        floatingActionButton: _buildFab(),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Container(
            width:  32,
            height: 32,
            decoration: BoxDecoration(
              gradient:     AppTheme.goldGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.lock_rounded,
                size: 16, color: Color(0xFF1A1600)),
          ),
          const SizedBox(width: 10),
          const Text('תיקייה נעולה'),
        ],
      ),
      actions: [
        IconButton(
          icon:    const Icon(Icons.settings_outlined),
          onPressed: () {
            _resetActivity();
            Navigator.of(context).pushNamed(AppConstants.routeSettings);
          },
        ),
        IconButton(
          icon:    const Icon(Icons.lock_outline_rounded, color: AppTheme.gold),
          tooltip: 'נעל עכשיו',
          onPressed: _lock,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildBody() {
    return Consumer<VaultProvider>(
      builder: (context, vault, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            // Category chips
            CategoryChipRow(
              selected:   vault.activeCategory,
              onSelected: (cat) {
                _resetActivity();
                vault.setCategory(cat);
              },
            ),
            const SizedBox(height: 16),

            // Status / count bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                vault.status == VaultStatus.loading
                    ? 'טוען…'
                    : '${vault.filteredFiles.length} קבצים',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 8),

            // File list
            Expanded(child: _buildFileList(vault)),
          ],
        );
      },
    );
  }

  Widget _buildFileList(VaultProvider vault) {
    if (vault.status == VaultStatus.loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.gold),
      );
    }

    if (vault.status == VaultStatus.error) {
      return Center(
        child: Text(vault.errorMessage ?? 'שגיאה',
            style: const TextStyle(color: AppTheme.error)),
      );
    }

    final files = vault.filteredFiles;
    if (files.isEmpty) {
      return const EmptyStateWidget();
    }

    return ListView.separated(
      padding:          const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      itemCount:        files.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final vf = files[i];
        return FileTileWidget(
          file:     vf,
          onTap:    () => _openFile(vf),
          onDelete: () => _deleteFile(vf),
          onRename: () => _renameFile(vf),
        );
      },
    );
  }

  Widget _buildFab() {
    return Consumer<VaultProvider>(
      builder: (context, vault, _) => FloatingActionButton.extended(
        onPressed:  vault.isOperating ? null : _addFiles,
        label: vault.isOperating
            ? const SizedBox(
                width:  18,
                height: 18,
                child:  CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFF1A1600)),
              )
            : const Text('הוסף קבצים',
                style: TextStyle(fontWeight: FontWeight.w700)),
        icon: vault.isOperating
            ? null
            : const Icon(Icons.add_rounded, size: 22),
        backgroundColor: AppTheme.gold,
        foregroundColor: const Color(0xFF1A1600),
        elevation:       4,
      ),
    );
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────

  Future<bool> _showDeleteDialog(String name) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppTheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppTheme.border),
            ),
            title: const Text('מחיקת קובץ'),
            content: Text('האם למחוק את "$name"? פעולה זו לא ניתנת לביטול.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child:     const Text('ביטול'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style:     TextButton.styleFrom(foregroundColor: AppTheme.error),
                child:     const Text('מחק'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<String?> _showRenameDialog(String current) async {
    final ctrl = TextEditingController(text: current);
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.border),
        ),
        title: const Text('שינוי שם'),
        content: TextField(
          controller:   ctrl,
          autofocus:    true,
          decoration: const InputDecoration(labelText: 'שם חדש'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:     const Text('ביטול'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            child:     const Text('שמור'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:         Text(msg),
        backgroundColor: isError ? AppTheme.error.withOpacity(0.9) : null,
      ),
    );
  }
}
