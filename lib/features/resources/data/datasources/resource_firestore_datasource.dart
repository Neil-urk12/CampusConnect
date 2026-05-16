import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/resource_entity.dart';
import '../../domain/exceptions/resource_exceptions.dart';
import '../models/resource_model.dart';

/// Firestore data source for resource CRUD operations
class ResourceFirestoreDataSource {
  final FirebaseFirestore _firestore;

  ResourceFirestoreDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('resources');

  /// Fetch resources with optional category filter and sort order
  Future<List<ResourceModel>> getResources({
    ResourceCategory? category,
    String? sortBy,
    int limit = 50,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _collection;

      if (category != null) {
        query = query.where('category', isEqualTo: category.value);
      }

      // Apply sort order
      switch (sortBy) {
        case 'popular':
          query = query.orderBy('downloadCount', descending: true);
          break;
        case 'az':
          query = query.orderBy('title', descending: false);
          break;
        case 'recent':
        default:
          query = query.orderBy('uploadedAt', descending: true);
          break;
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => ResourceModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } on FirebaseException catch (e) {
      AppLogger.error('Failed to fetch resources', error: e);
      throw _mapFirebaseException(e);
    }
  }

  /// Get a single resource by ID
  Future<ResourceModel?> getResourceById(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return ResourceModel.fromJson({...doc.data()!, 'id': doc.id});
    } on FirebaseException catch (e) {
      AppLogger.error('Failed to fetch resource $id', error: e);
      throw _mapFirebaseException(e);
    }
  }

  /// Create a new resource document
  Future<void> createResource(ResourceEntity resource) async {
    try {
      final model = ResourceModel.fromEntity(resource);
      await _collection.doc(resource.id).set(model.toJson());
      AppLogger.info('Resource created: ${resource.id}');
    } on FirebaseException catch (e) {
      AppLogger.error('Failed to create resource', error: e);
      throw _mapFirebaseException(e);
    }
  }

  /// Delete a resource document
  Future<void> deleteResource(String id) async {
    try {
      await _collection.doc(id).delete();
      AppLogger.info('Resource deleted: $id');
    } on FirebaseException catch (e) {
      AppLogger.error('Failed to delete resource $id', error: e);
      throw _mapFirebaseException(e);
    }
  }

  /// Increment download count atomically using FieldValue.increment
  Future<void> incrementDownloadCount(String id) async {
    try {
      await _collection.doc(id).update({
        'downloadCount': FieldValue.increment(1),
      });
      AppLogger.debug('Download count incremented for resource $id');
    } on FirebaseException catch (e) {
      AppLogger.error('Failed to increment download count for $id', error: e);
      throw _mapFirebaseException(e);
    }
  }

  /// Map FirebaseException to domain-specific exceptions
  ResourceException _mapFirebaseException(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return ResourcePermissionException(
          message: e.message ?? 'Permission denied',
        );
      case 'not-found':
        return ResourceNotFoundException(
          message: e.message ?? 'Resource not found',
        );
      default:
        return ResourceNetworkException(
          message: e.message ?? 'Network error occurred',
        );
    }
  }
}
