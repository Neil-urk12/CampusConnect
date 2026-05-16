import 'package:appwrite/appwrite.dart';

import '../../appwrite_config.dart';
import '../../core/utils/app_logger.dart';
import '../domain/attachment_types.dart';
import 'attachment_storage_adapter.dart';

class AppwriteAttachmentStorageAdapter implements AttachmentStorageAdapter {
  AppwriteAttachmentStorageAdapter({Storage? storage, String? imageBucketId})
    : _storage = storage ?? AppwriteConfig.storage,
      _imageBucketId = imageBucketId ?? AppwriteConfig.chatAttachmentsBucketId;

  final Storage _storage;
  final String _imageBucketId;

  static String storageFileId(String attachmentId) => attachmentId;

  @override
  Future<StoredAttachment> uploadImage({
    required AttachmentOwnerRef owner,
    required String attachmentId,
    required AttachmentInput image,
  }) async {
    final fileId = storageFileId(attachmentId);
    await _storage.createFile(
      bucketId: _imageBucketId,
      fileId: fileId,
      file: InputFile.fromBytes(bytes: image.bytes, filename: image.fileName),
      permissions: const ['read("any")'],
    );

    return StoredAttachment(
      bucketId: _imageBucketId,
      fileId: fileId,
      url: _fileViewUrl(bucketId: _imageBucketId, fileId: fileId),
    );
  }

  @override
  Future<void> deleteBestEffort({
    required String bucketId,
    required String fileId,
  }) async {
    try {
      await _storage.deleteFile(bucketId: bucketId, fileId: fileId);
    } catch (error) {
      AppLogger.warning('Best-effort attachment delete failed', error: error);
    }
  }

  String _fileViewUrl({required String bucketId, required String fileId}) {
    return '${AppwriteConfig.endpoint}/storage/buckets/$bucketId/files/$fileId/view?project=${AppwriteConfig.projectId}';
  }
}
