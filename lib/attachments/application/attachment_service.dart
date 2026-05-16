import 'package:uuid/uuid.dart';

import '../data/attachment_storage_adapter.dart';
import '../domain/attachment_exception.dart';
import '../domain/attachment_types.dart';
import 'attachment_validator.dart';

abstract interface class AttachmentService {
  Future<AttachmentDraft> prepareImage({
    required AttachmentOwnerRef owner,
    required AttachmentInput image,
  });

  Future<AttachmentDraft> prepareReplacementImage({
    required AttachmentOwnerRef owner,
    required AttachmentInput image,
    AttachmentMetadata? existing,
  });

  Future<void> deleteBestEffort(AttachmentMetadata? attachment);

  AttachmentView read({AttachmentMetadata? metadata, String? legacyUrl});
}

class AttachmentServiceImpl implements AttachmentService {
  AttachmentServiceImpl({
    required AttachmentStorageAdapter storage,
    AttachmentValidator validator = const AttachmentValidator(),
    Uuid? uuid,
    DateTime Function()? now,
  }) : _storage = storage,
       _validator = validator,
       _uuid = uuid ?? const Uuid(),
       _now = now ?? DateTime.now;

  final AttachmentStorageAdapter _storage;
  final AttachmentValidator _validator;
  final Uuid _uuid;
  final DateTime Function() _now;

  @override
  Future<AttachmentDraft> prepareImage({
    required AttachmentOwnerRef owner,
    required AttachmentInput image,
  }) async {
    _validator.validateImage(owner: owner, image: image);
    final attachmentId = _uuid.v4();

    try {
      final stored = await _storage.uploadImage(
        owner: owner,
        attachmentId: attachmentId,
        image: image,
      );

      final metadata = AttachmentMetadata(
        id: attachmentId,
        kind: AttachmentKind.image,
        url: stored.url,
        bucketId: stored.bucketId,
        fileId: stored.fileId,
        mimeType: image.mimeType,
        sizeBytes: image.sizeBytes,
        ownerType: owner.type,
        ownerId: owner.ownerId,
        createdAt: _now().toUtc(),
      );

      return AttachmentDraft(
        metadata: metadata,
        rollback: () => deleteBestEffort(metadata),
      );
    } catch (error) {
      if (error is AttachmentException) rethrow;
      throw AttachmentException(
        code: AttachmentErrorCode.uploadFailed,
        message: 'Failed to upload image.',
        cause: error,
      );
    }
  }

  @override
  Future<AttachmentDraft> prepareReplacementImage({
    required AttachmentOwnerRef owner,
    required AttachmentInput image,
    AttachmentMetadata? existing,
  }) async {
    final draft = await prepareImage(owner: owner, image: image);
    return AttachmentDraft(metadata: draft.metadata, rollback: draft.rollback);
  }

  @override
  Future<void> deleteBestEffort(AttachmentMetadata? attachment) async {
    if (attachment == null) return;
    await _storage.deleteBestEffort(
      bucketId: attachment.bucketId,
      fileId: attachment.fileId,
    );
  }

  @override
  AttachmentView read({AttachmentMetadata? metadata, String? legacyUrl}) {
    if (metadata != null) return AttachmentView.metadata(metadata);
    if (legacyUrl != null && legacyUrl.isNotEmpty) {
      return AttachmentView.legacyUrl(legacyUrl);
    }
    return const AttachmentView.none();
  }
}
