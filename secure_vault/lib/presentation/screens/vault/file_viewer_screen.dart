import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/file_utils.dart';
import '../../../data/models/vault_file.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/vault_provider.dart';
import '../../theme/app_theme.dart';

/// Decrypts and previews a vault file in memory.
/// Image, text, and PDF previews are supported; others show a placeholder.
class FileViewerScreen extends StatefulWidget {
  const FileViewerScreen({super.key, required this.file});
  final VaultFile file;

  @override
  State<FileViewerScreen> createState() => _FileViewerScreenState();
}

class _FileViewerScreenState extends State<FileViewerScreen> {
  Uint8List? _decrypted;
  bool       _loading = true;
  String?    _error;

  @override
  void initState() {
    super.initState();
    _decryptFile();
  }

  Future<void> _decryptFile() async {
    final auth  = context.read<AuthProvider>();
    final vault = context.read<VaultProvider>();

    if (auth.masterKey == null) {
      setState(() { _loading = false; _error = 'לא מאומת'; });
      return;
    }

    final bytes = await vault.decryptFileForViewing(
        widget.file, auth.masterKey!);
    if (!mounted) return;

    // Reset auto-lock after decryption
    auth.resetActivity();

    setState(() {
      _decrypted = bytes;
      _loading   = false;
      _error     = bytes == null ? (vault.errorMessage ?? 'שגיאת פענוח') : null;
    });
  }

  @override
  void dispose() {
    // Zero out decrypted bytes on dispose to limit in-memory exposure
    if (_decrypted != null) {
      for (var i = 0; i < _decrypted!.length; i++) _decrypted![i] = 0;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          widget.file.originalName,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(FileUtils.formatSize(widget.file.fileSize),
                    style: Theme.of(context).textTheme.bodySmall),
                Text(FileUtils.formatDate(widget.file.createdAt),
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.gold),
            SizedBox(height: 16),
            Text('מפענח קובץ…',
                style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppTheme.error, size: 48),
              const SizedBox(height: 16),
              Text(_error!,
                  style: const TextStyle(color: AppTheme.error),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return _buildPreview();
  }

  Widget _buildPreview() {
    final mime = widget.file.mimeType.toLowerCase();

    // ── Image ────────────────────────────────────────────────────────────────
    if (mime.startsWith('image/')) {
      return InteractiveViewer(
        child: Center(
          child: Image.memory(
            _decrypted!,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const Center(child: Icon(Icons.broken_image_rounded,
                    size: 64, color: AppTheme.textTertiary)),
          ),
        ),
      );
    }

    // ── Plain text ───────────────────────────────────────────────────────────
    if (mime.startsWith('text/')) {
      final text = String.fromCharCodes(_decrypted!);
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: SelectableText(
          text,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize:   14,
            color:      AppTheme.textPrimary,
          ),
        ),
      );
    }

    // ── Generic file (no preview) ────────────────────────────────────────────
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width:  80,
            height: 80,
            decoration: BoxDecoration(
              color:        AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
              border:       Border.all(color: AppTheme.border),
            ),
            child: const Icon(Icons.insert_drive_file_rounded,
                size: 40, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),
          Text(widget.file.originalName,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(FileUtils.formatSize(widget.file.fileSize),
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(widget.file.mimeType,
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 32),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'תצוגה מקדימה אינה זמינה לסוג קובץ זה.\nהקובץ מאוחסן בצורה מוצפנת ומאובטחת.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textTertiary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
