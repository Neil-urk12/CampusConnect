import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import '../appwrite_config.dart';
import '../core/utils/app_logger.dart';

/// Service for handling Appwrite Storage operations
class AppwriteStorageService {
  final Storage _storage = AppwriteConfig.storage;

  /// Upload a file to Appwrite Storage
  ///
  /// [bucketId] - The ID of the storage bucket
  /// [fileId] - Unique ID for the file (use ID.unique() for auto-generation)
  /// [file] - The file to upload
  /// [permissions] - Optional permissions for the file
  Future<File> uploadFile({
    required String bucketId,
    required String fileId,
    required InputFile file,
    List<String>? permissions,
  }) async {
    try {
      final result = await _storage.createFile(
        bucketId: bucketId,
        fileId: fileId,
        file: file,
        permissions: permissions,
      );
      
      AppLogger.info('File uploaded successfully: ${result.$id}');
      return result;
    } catch (e) {
      
      AppLogger.error('File upload failed: $e');
      rethrow;
    }
  }

  /// Get file preview URL
  ///
  /// [bucketId] - The ID of the storage bucket
  /// [fileId] - The ID of the file
  String getFilePreview({
    required String bucketId,
    required String fileId,
    int? width,
    int? height,
  }) {
    return '${AppwriteConfig.endpoint}/storage/buckets/$bucketId/files/$fileId/preview?project=${AppwriteConfig.projectId}${width != null ? '&width=$width' : ''}${height != null ? '&height=$height' : ''}';
  }

  /// Get file download URL
  ///
  /// [bucketId] - The ID of the storage bucket
  /// [fileId] - The ID of the file
  String getFileDownload({required String bucketId, required String fileId}) {
    return '${AppwriteConfig.endpoint}/storage/buckets/$bucketId/files/$fileId/download?project=${AppwriteConfig.projectId}';
  }

  /// Get file view URL
  ///
  /// [bucketId] - The ID of the storage bucket
  /// [fileId] - The ID of the file
  String getFileView({required String bucketId, required String fileId}) {
    return '${AppwriteConfig.endpoint}/storage/buckets/$bucketId/files/$fileId/view?project=${AppwriteConfig.projectId}';
  }

  /// Delete a file from Appwrite Storage
  ///
  /// [bucketId] - The ID of the storage bucket
  /// [fileId] - The ID of the file to delete
  Future<void> deleteFile({
    required String bucketId,
    required String fileId,
  }) async {
    try {
      await _storage.deleteFile(bucketId: bucketId, fileId: fileId);
      
      AppLogger.info('File deleted successfully: $fileId');
    } catch (e) {
      
      AppLogger.error('File deletion failed: $e');
      rethrow;
    }
  }

  /// List files in a bucket
  ///
  /// [bucketId] - The ID of the storage bucket
  /// [queries] - Optional queries for filtering
  Future<FileList> listFiles({
    required String bucketId,
    List<String>? queries,
  }) async {
    try {
      final result = await _storage.listFiles(
        bucketId: bucketId,
        queries: queries,
      );
      
      AppLogger.debug('Retrieved ${result.files.length} files');
      return result;
    } catch (e) {
      
      AppLogger.error('Failed to list files: $e');
      rethrow;
    }
  }

  /// Get file details
  ///
  /// [bucketId] - The ID of the storage bucket
  /// [fileId] - The ID of the file
  Future<File> getFile({
    required String bucketId,
    required String fileId,
  }) async {
    try {
      final result = await _storage.getFile(bucketId: bucketId, fileId: fileId);
      return result;
    } catch (e) {
      
      AppLogger.error('Failed to get file: $e');
      rethrow;
    }
  }

  /// Upload an image to the chat_attachments bucket and return the public view URL.
  ///
  /// [file] - The image file to upload
  /// [fileId] - Unique ID for the file (use ID.unique() for auto-generation)
  Future<String> uploadChatImage({
    required InputFile file,
    required String fileId,
  }) async {
    try {
      final bucketId = AppwriteConfig.chatAttachmentsBucketId;

      // Upload the file with public read permissions
      await uploadFile(
        bucketId: bucketId,
        fileId: fileId,
        file: file,
        permissions: [
          'read("any")', // Allow anyone to read the file
        ],
      );

      // Return the public view URL
      return getFileView(bucketId: bucketId, fileId: fileId);
    } catch (e) {
      
      AppLogger.error('Failed to upload chat image: $e');
      rethrow;
    }
  }

  /// Upload an image to the attachments bucket and return the public view URL.
  /// Uses the same bucket as chat attachments (free tier limitation).
  ///
  /// [file] - The image file to upload
  /// [fileId] - Unique ID for the file (use ID.unique() for auto-generation)
  Future<String> uploadAnnouncementImage({
    required InputFile file,
    required String fileId,
  }) async {
    try {
      final bucketId = AppwriteConfig.announcementAttachmentsBucketId;

      // Upload the file with public read permissions
      await uploadFile(
        bucketId: bucketId,
        fileId: fileId,
        file: file,
        permissions: [
          'read("any")', // Allow anyone to read the file
        ],
      );

      // Return the public view URL
      return getFileView(bucketId: bucketId, fileId: fileId);
    } catch (e) {
      
      AppLogger.error('Failed to upload announcement image: $e');
      rethrow;
    }
  }

  /// Upload a resource file to the attachments bucket and return the public view URL.
  Future<String> uploadResourceFile({
    required InputFile file,
    required String fileId,
  }) async {
    try {
      final bucketId = AppwriteConfig.resourceAttachmentsBucketId;
      await uploadFile(
        bucketId: bucketId,
        fileId: fileId,
        file: file,
        permissions: ['read("any")'],
      );
      return getFileView(bucketId: bucketId, fileId: fileId);
    } catch (e) {
      AppLogger.error('Failed to upload resource file: $e');
      rethrow;
    }
  }
}
