import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../core/errors/app_exceptions.dart';
import '../data/models/vault_file.dart';
import '../data/repositories/vault_repository.dart';

enum VaultStatus { initial, loading, loaded, error }

/// Manages vault file state and operations.
class VaultProvider extends ChangeNotifier {
  VaultProvider({required this.vaultRepository});

  final VaultRepository vaultRepository;

  // ── State ──────────────────────────────────────────────────────────────────

  VaultStatus       _status          = VaultStatus.initial;
  List<VaultFile>   _files           = [];
  String            _activeCategory  = 'all';
  String?           _errorMessage;
  bool              _isOperating     = false;  // File import/delete in progress

  VaultStatus       get status         => _status;
  List<VaultFile>   get files          => List.unmodifiable(_files);
  String            get activeCategory => _activeCategory;
  String?           get errorMessage   => _errorMessage;
  bool              get isOperating    => _isOperating;
  bool              get isEmpty        => _files.isEmpty;

  List<VaultFile> get filteredFiles {
    if (_activeCategory == 'all') return List.unmodifiable(_files);
    return _files.where((f) => f.category == _activeCategory).toList();
  }

  // ── Loading ────────────────────────────────────────────────────────────────

  Future<void> loadFiles() async {
    _status = VaultStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _files  = await vaultRepository.getFiles();
      _status = VaultStatus.loaded;
    } on AppException catch (e) {
      _status       = VaultStatus.error;
      _errorMessage = e.message;
    } catch (e) {
      _status       = VaultStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  // ── Category Filter ────────────────────────────────────────────────────────

  void setCategory(String category) {
    if (_activeCategory == category) return;
    _activeCategory = category;
    notifyListeners();
  }

  // ── Import ────────────────────────────────────────────────────────────────

  Future<bool> importFiles(Uint8List masterKey) async {
    _isOperating  = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final imported = await vaultRepository.pickAndImportFiles(masterKey);
      if (imported.isEmpty) {
        _isOperating = false;
        notifyListeners();
        return false;
      }
      _files.insertAll(0, imported);
      _isOperating = false;
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      _isOperating  = false;
      notifyListeners();
      return false;
    }
  }

  // ── Decrypt for Viewing ───────────────────────────────────────────────────

  Future<Uint8List?> decryptFileForViewing(
      VaultFile vf, Uint8List masterKey) async {
    try {
      return await vaultRepository.decryptFile(vf, masterKey);
    } on IntegrityViolationException {
      _errorMessage = 'בדיקת שלמות הקובץ נכשלה';
      notifyListeners();
      return null;
    } on AppException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return null;
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<bool> deleteFile(VaultFile vf) async {
    _isOperating = true;
    notifyListeners();

    try {
      await vaultRepository.deleteFile(vf);
      _files.removeWhere((f) => f.id == vf.id);
      _isOperating = false;
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      _isOperating  = false;
      notifyListeners();
      return false;
    }
  }

  // ── Rename ────────────────────────────────────────────────────────────────

  Future<bool> renameFile(VaultFile vf, String newName) async {
    try {
      await vaultRepository.renameFile(vf.id, newName);
      final idx = _files.indexWhere((f) => f.id == vf.id);
      if (idx != -1) {
        _files[idx] = vf.copyWith(
            originalName: newName, modifiedAt: DateTime.now());
        notifyListeners();
      }
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Called when the vault is locked – clears in-memory file list.
  void clearVault() {
    _files          = [];
    _activeCategory = 'all';
    _status         = VaultStatus.initial;
    _errorMessage   = null;
    notifyListeners();
  }
}
