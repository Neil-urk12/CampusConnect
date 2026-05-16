import 'package:equatable/equatable.dart';

enum AttachmentOwnerType { message, announcement, group }

enum AttachmentKind { image }

class AttachmentOwnerRef extends Equatable {
  const AttachmentOwnerRef({required this.type, required this.ownerId});

  final AttachmentOwnerType type;
  final String ownerId;

  @override
  List<Object?> get props => [type, ownerId];
}

class AttachmentInput extends Equatable {
  const AttachmentInput.image({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
  }) : kind = AttachmentKind.image;

  final AttachmentKind kind;
  final List<int> bytes;
  final String fileName;
  final String mimeType;
  final int sizeBytes;

  @override
  List<Object?> get props => [kind, bytes, fileName, mimeType, sizeBytes];
}

class AttachmentMetadata extends Equatable {
  const AttachmentMetadata({
    required this.id,
    required this.kind,
    required this.url,
    required this.bucketId,
    required this.fileId,
    required this.mimeType,
    required this.sizeBytes,
    required this.ownerType,
    required this.ownerId,
    required this.createdAt,
  });

  final String id;
  final AttachmentKind kind;
  final String url;
  final String bucketId;
  final String fileId;
  final String mimeType;
  final int sizeBytes;
  final AttachmentOwnerType ownerType;
  final String ownerId;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
    'id': id,
    'kind': kind.name,
    'url': url,
    'bucketId': bucketId,
    'fileId': fileId,
    'mimeType': mimeType,
    'sizeBytes': sizeBytes,
    'ownerType': ownerType.name,
    'ownerId': ownerId,
    'createdAt': createdAt.toIso8601String(),
  };

  factory AttachmentMetadata.fromMap(Map<String, dynamic> map) {
    return AttachmentMetadata(
      id: map['id'] as String,
      kind: AttachmentKind.values.byName(map['kind'] as String),
      url: map['url'] as String,
      bucketId: map['bucketId'] as String,
      fileId: map['fileId'] as String,
      mimeType: map['mimeType'] as String,
      sizeBytes: map['sizeBytes'] as int,
      ownerType: AttachmentOwnerType.values.byName(map['ownerType'] as String),
      ownerId: map['ownerId'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  @override
  List<Object?> get props => [
    id,
    kind,
    url,
    bucketId,
    fileId,
    mimeType,
    sizeBytes,
    ownerType,
    ownerId,
    createdAt,
  ];
}

class AttachmentDraft {
  const AttachmentDraft({required this.metadata, required this.rollback});

  final AttachmentMetadata metadata;
  final Future<void> Function() rollback;
}

class AttachmentView extends Equatable {
  const AttachmentView.none()
    : url = null,
      metadata = null,
      isLegacyUrlOnly = false;

  AttachmentView.metadata(AttachmentMetadata value)
    : url = value.url,
      metadata = value,
      isLegacyUrlOnly = false;

  const AttachmentView.legacyUrl(this.url)
    : metadata = null,
      isLegacyUrlOnly = true;

  final String? url;
  final AttachmentMetadata? metadata;
  final bool isLegacyUrlOnly;

  bool get hasImage => url != null && url!.isNotEmpty;

  @override
  List<Object?> get props => [url, metadata, isLegacyUrlOnly];
}
