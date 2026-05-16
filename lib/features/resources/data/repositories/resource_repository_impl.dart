import 'dart:io';
import 'package:appwrite/appwrite.dart';
import '../../../../appwrite_config.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../services/appwrite_storage_service.dart';
import '../../domain/entities/resource_entity.dart';
import '../../domain/exceptions/resource_exceptions.dart';
import '../../domain/repositories/resource_repository.dart';
import '../datasources/resource_firestore_datasource.dart';

/// Implementation of [ResourceRepository] using Firestore + Appwrite Storage
class ResourceRepositoryImpl implements ResourceRepository {
  final ResourceFirestoreDataSource _datasource;
  final AppwriteStorageService _storageService;

  ResourceRepositoryImpl({
    required ResourceFirestoreDataSource datasource,
    required AppwriteStorageService storageService,
  })  : _datasource = datasource,
        _storageService = storageService;

  @override
  Future<List<ResourceEntity>> getResources({
    ResourceCategory? category,
    String? sortBy,
    int limit = 50,
  }) async {
    try {
      final models = await _datasource.getResources(
        category: category,
        sortBy: sortBy,
        limit: limit,
      );
      return models.map((m) => m.toEntity()).toList();
    } on ResourceException {
      rethrow;
    } catch (e) {
      AppLogger.error('Failed to get resources', error: e);
      throw ResourceNetworkException(message: 'Failed to load resources: $e');
    }
  }

  @override
  Future<ResourceEntity?> getResourceById(String id) async {
    try {
      final model = await _datasource.getResourceById(id);
      return model?.toEntity();
    } on ResourceException {
      rethrow;
    } catch (e) {
      AppLogger.error('Failed to get resource $id', error: e);
      throw ResourceNetworkException(message: 'Failed to load resource: $e');
    }
  }

  @override
  Future<void> createResource(ResourceEntity resource) async {
    try {
      await _datasource.createResource(resource);
    } on ResourceException {
      rethrow;
    } catch (e) {
      AppLogger.error('Failed to create resource', error: e);
      throw ResourceNetworkException(message: 'Failed to create resource: $e');
    }
  }

  @override
  Future<void> deleteResource(String id) async {
    try {
      // Delete Firestore document first
      await _datasource.deleteResource(id);

      // Then delete the Appwrite file
      try {
        await _storageService.deleteFile(
          bucketId: AppwriteConfig.resourceAttachmentsBucketId,
          fileId: id,
        );
      } catch (e) {
        // Log but don't throw — Firestore doc is already deleted,
        // orphaned Appwrite file is acceptable for MVP
        AppLogger.warning(
          'Failed to delete Appwrite file for resource $id (Firestore doc deleted)',
          error: e,
        );
      }
    } on ResourceException {
      rethrow;
    } catch (e) {
      AppLogger.error('Failed to delete resource $id', error: e);
      throw ResourceNetworkException(message: 'Failed to delete resource: $e');
    }
  }

  @override
  Future<void> incrementDownloadCount(String id) async {
    try {
      await _datasource.incrementDownloadCount(id);
    } on ResourceException {
      rethrow;
    } catch (e) {
      AppLogger.error('Failed to increment download count for $id', error: e);
      throw ResourceNetworkException(
        message: 'Failed to update download count: $e',
      );
    }
  }

  @override
  Future<String> uploadFile(File file, String fileId) async {
    try {
      final fileName = file.path.split('/').last;
      final inputFile = InputFile.fromPath(path: file.path, filename: fileName);

      final fileUrl = await _storageService.uploadFile(
        bucketId: AppwriteConfig.resourceAttachmentsBucketId,
        fileId: fileId,
        file: inputFile,
        permissions: ['read("any")'],
      );

      return _storageService.getFileView(
        bucketId: AppwriteConfig.resourceAttachmentsBucketId,
        fileId: fileUrl.$id,
      );
    } catch (e) {
      AppLogger.error('Failed to upload resource file', error: e);
      throw ResourceStorageException(message: 'Failed to upload file: $e');
    }
  }
}
