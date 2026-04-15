/// Metadata for a single file stored inside the vault.
/// The actual encrypted bytes live on disk; this object is stored in SQLite.
class VaultFile {
  const VaultFile({
    required this.id,
    required this.originalName,
    required this.encryptedFilename,
    required this.category,
    required this.fileSize,
    required this.mimeType,
    required this.createdAt,
    required this.modifiedAt,
  });

  /// UUID v4 – primary key
  final String id;

  /// Original filename as chosen by the user
  final String originalName;

  /// Name of the encrypted file on disk (inside vault dir)
  final String encryptedFilename;

  /// 'images' | 'videos' | 'documents' | 'others'
  final String category;

  /// Size of the *original* (unencrypted) file in bytes
  final int fileSize;

  final String mimeType;
  final DateTime createdAt;
  final DateTime modifiedAt;

  // ── SQLite serialisation ─────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'id': id,
        'original_name': originalName,
        'encrypted_filename': encryptedFilename,
        'category': category,
        'file_size': fileSize,
        'mime_type': mimeType,
        'created_at': createdAt.millisecondsSinceEpoch,
        'modified_at': modifiedAt.millisecondsSinceEpoch,
      };

  factory VaultFile.fromMap(Map<String, dynamic> map) => VaultFile(
        id: map['id'] as String,
        originalName: map['original_name'] as String,
        encryptedFilename: map['encrypted_filename'] as String,
        category: map['category'] as String,
        fileSize: map['file_size'] as int,
        mimeType: map['mime_type'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        modifiedAt: DateTime.fromMillisecondsSinceEpoch(map['modified_at'] as int),
      );

  VaultFile copyWith({
    String? id,
    String? originalName,
    String? encryptedFilename,
    String? category,
    int? fileSize,
    String? mimeType,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) =>
      VaultFile(
        id: id ?? this.id,
        originalName: originalName ?? this.originalName,
        encryptedFilename: encryptedFilename ?? this.encryptedFilename,
        category: category ?? this.category,
        fileSize: fileSize ?? this.fileSize,
        mimeType: mimeType ?? this.mimeType,
        createdAt: createdAt ?? this.createdAt,
        modifiedAt: modifiedAt ?? this.modifiedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VaultFile && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'VaultFile(id: $id, name: $originalName)';
}
