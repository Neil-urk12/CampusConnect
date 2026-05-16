import '../domain/attachment_types.dart';

class StoredAttachment {
  const StoredAttachment({
    required this.bucketId,
    required this.fileId,
    required this.url,
  });

  final String bucketId;
  final String fileId;
  final String url;
}

abstract interface class AttachmentStorageAdapter {
  Future<StoredAttachment> uploadImage({
    required AttachmentOwnerRef owner,
    required String attachmentId,
    required AttachmentInput image,
  });

  Future<void> deleteBestEffort({
    required String bucketId,
    required String fileId,
  });
}
