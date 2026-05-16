import 'dart:io';

import '../domain/entities/resource_entity.dart';
import '../domain/exceptions/resource_exceptions.dart';
import '../domain/repositories/resource_repository.dart';

/// Application service for resource library workflows.
class ResourceService {
  static const int maxFileSizeBytes = 50 * 1024 * 1024;

  final ResourceRepository repository;

  const ResourceService({required this.repository});

  Future<List<ResourceEntity>> getResources({
    ResourceCategory? category,
    String? sortBy,
  }) async {
    try {
      return repository.getResources(category: category, sortBy: sortBy);
    } on ResourceException {
      rethrow;
    } catch (e) {
      throw ResourceException(message: 'Failed to get resources: $e');
    }
  }

  Future<ResourceEntity?> getResourceById(String id) async {
    try {
      _validateId(id);
      return repository.getResourceById(id);
    } on ResourceException {
      rethrow;
    } catch (e) {
      throw ResourceException(message: 'Failed to get resource: $e');
    }
  }

  Future<void> uploadResource(ResourceEntity resource, File file) async {
    try {
      validateFileSize(file);
      validateMimeType(resource.mimeType);
      validateMetadata(resource.title, resource.category);

      final fileUrl = await repository.uploadFile(file, resource.id);
      final resourceToCreate = resource.copyWith(
        fileUrl: fileUrl,
        fileSize: file.lengthSync(),
      );

      await repository.createResource(resourceToCreate);
    } on ResourceException {
      rethrow;
    } catch (e) {
      throw ResourceException(message: 'Failed to upload resource: $e');
    }
  }

  Future<void> deleteResource(String id, String currentUserId) async {
    try {
      _validateId(id);
      if (currentUserId.trim().isEmpty) {
        throw const ResourceValidationException(
          field: 'currentUserId',
          message: 'Current user ID is required',
        );
      }

      final resource = await repository.getResourceById(id);
      if (resource == null) {
        throw const ResourceNotFoundException(message: 'Resource not found');
      }

      if (resource.uploadedBy != currentUserId) {
        throw const ResourcePermissionException(
          message: 'Only resource owner can delete this resource',
        );
      }

      await repository.deleteResource(id);
    } on ResourceException {
      rethrow;
    } catch (e) {
      throw ResourceException(message: 'Failed to delete resource: $e');
    }
  }

  Future<void> incrementDownloadCount(String id) async {
    try {
      _validateId(id);
      await repository.incrementDownloadCount(id);
    } on ResourceException {
      rethrow;
    } catch (e) {
      throw ResourceException(
        message: 'Failed to increment download count: $e',
      );
    }
  }

  void validateFileSize(File file) {
    if (file.lengthSync() > maxFileSizeBytes) {
      throw const ResourceValidationException(
        field: 'file',
        message: 'File size must be 50MB or less',
      );
    }
  }

  void validateMimeType(String mimeType) {
    final normalized = mimeType.trim().toLowerCase();
    final isAllowed =
        normalized.startsWith('image/') ||
        normalized == 'application/pdf' ||
        normalized == 'application/msword' ||
        normalized.startsWith('application/vnd.') ||
        normalized == 'video/mp4' ||
        normalized == 'video/quicktime';

    if (!isAllowed) {
      throw ResourceValidationException(
        field: 'mimeType',
        message: 'Unsupported file type: $mimeType',
      );
    }
  }

  void validateMetadata(String title, ResourceCategory category) {
    if (title.trim().isEmpty) {
      throw const ResourceValidationException(
        field: 'title',
        message: 'Title is required',
      );
    }

    if (!ResourceCategory.values.contains(category)) {
      throw const ResourceValidationException(
        field: 'category',
        message: 'Invalid resource category',
      );
    }
  }

  void _validateId(String id) {
    if (id.trim().isEmpty) {
      throw const ResourceValidationException(
        field: 'id',
        message: 'Resource ID is required',
      );
    }
  }
}
