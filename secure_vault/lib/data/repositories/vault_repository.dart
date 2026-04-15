import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/utils/file_utils.dart';
import '../models/vault_file.dart';
import '../services/database_service.dart';
import '../services/encryption_service.dart';

/// High-level vault operations: import, export, delete, list.
class VaultRepository {
  VaultRepository({
    required this.databaseService,
    required this.encryptionService,
  });

  final DatabaseService  databaseService;
  final EncryptionService encryptionService;

  final _uuid = const Uuid();

  // ── Vault Directory ────────────────────────────────────────────────────────

  Future<Directory> _vaultDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir  = Directory(p.join(base.path, AppConstants.vaultDirName));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  // ── File Import ────────────────────────────────────────────────────────────

  /// Opens the OS file picker, encrypts the chosen file(s), and stores them.
  /// [masterKey] must be the authenticated 64-byte master key.
  Future<List<VaultFile>> pickAndImportFiles(Uint8List masterKey) async {
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        withData: true,       // Read bytes into memory (safe for most files)
      );
    } catch (e) {
      throw FileImportException(e.toString());
    }

    if (result == null || result.files.isEmpty) return [];

    final imported = <VaultFile>[];
    for (final pf in result.files) {
      if (pf.bytes == null) continue;
      final vf = await _importBytes(
        bytes: pf.bytes!,
        originalName: pf.name,
        masterKey: masterKey,
      );
      imported.add(vf);
    }
    return imported;
  }

  /// Encrypts raw [bytes] and stores a [VaultFile] record.
  Future<VaultFile> _importBytes({
    required Uint8List bytes,
    required String originalName,
    required Uint8List masterKey,
  }) async {
    final id   = _uuid.v4();
    final mime = lookupMimeType(originalName) ?? 'application/octet-stream';
    final cat  = FileUtils.categoryFromMime(mime);

    // Encrypt
    final encrypted = await encryptionService.encryptBytes(bytes, masterKey);

    // Write to vault dir
    final dir      = await _vaultDir();
    final filename = '$id${AppConstants.encryptedFileExt}';
    final file     = File(p.join(dir.path, filename));
    await file.writeAsBytes(encrypted, flush: true);

    final now = DateTime.now();
    final vf  = VaultFile(
      id:                id,
      originalName:      originalName,
      encryptedFilename: filename,
      category:          cat,
      fileSize:          bytes.length,
      mimeType:          mime,
      createdAt:         now,
      modifiedAt:        now,
    );
    await databaseService.insertFile(vf);
    return vf;
  }

  // ── File Export (Decryption) ───────────────────────────────────────────────

  /// Decrypts a vault file and returns the original bytes.
  Future<Uint8List> decryptFile(VaultFile vf, Uint8List masterKey) async {
    final dir  = await _vaultDir();
    final file = File(p.join(dir.path, vf.encryptedFilename));

    if (!file.existsSync()) throw FileNotFoundException(vf.originalName);

    final encrypted = await file.readAsBytes();
    return encryptionService.decryptBytes(encrypted, masterKey);
  }

  // ── Metadata Queries ───────────────────────────────────────────────────────

  Future<List<VaultFile>> getFiles({String category = 'all'}) =>
      databaseService.getAllFiles(category: category);

  Future<VaultFile?> getFileById(String id) =>
      databaseService.getFileById(id);

  Future<int> countFiles({String? category}) =>
      databaseService.countFiles(category: category);

  // ── Mutation ───────────────────────────────────────────────────────────────

  Future<void> renameFile(String id, String newName) =>
      databaseService.renameFile(id, newName);

  /// Deletes the encrypted file on disk AND its metadata record.
  Future<void> deleteFile(VaultFile vf) async {
    final dir  = await _vaultDir();
    final file = File(p.join(dir.path, vf.encryptedFilename));
    if (file.existsSync()) await file.delete();
    await databaseService.deleteFile(vf.id);
  }

  /// Wipes the entire vault directory and all DB records.
  Future<void> deleteAllFiles() async {
    final dir = await _vaultDir();
    if (dir.existsSync()) await dir.delete(recursive: true);
  }
}
