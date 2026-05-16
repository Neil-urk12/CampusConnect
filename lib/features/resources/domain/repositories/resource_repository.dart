import 'dart:io';
import '../entities/resource_entity.dart';

/// Abstract repository for resource data operations
abstract class ResourceRepository {
  /// Get resources with optional category filter and sort parameter
  Future<List<ResourceEntity>> getResources({
    ResourceCategory? category,
    String? sortBy,
    int limit = 50,
  });

  /// Get a single resource by ID
  Future<ResourceEntity?> getResourceById(String id);

  /// Create a new resource document in Firestore
  Future<void> createResource(ResourceEntity resource);

  /// Delete a resource (Firestore doc + Appwrite file)
  Future<void> deleteResource(String id);

  /// Increment the download count for a resource
  Future<void> incrementDownloadCount(String id);

  /// Upload a file to Appwrite storage and return the public view URL
  Future<String> uploadFile(File file, String fileId);
}
