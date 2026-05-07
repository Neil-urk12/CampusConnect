import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/announcement_model.dart';
import '../../domain/exceptions/announcement_exceptions.dart';
import '../../../../core/utils/app_logger.dart';

class AnnouncementFirestoreDataSource {
  final FirebaseFirestore _firestore;

  AnnouncementFirestoreDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get announcements stream filtered by user roles and optional category
  /// Returns real-time updates via Firestore snapshots
  /// Admins and moderators see all announcements regardless of targetAudience
  Stream<List<AnnouncementModel>> getAnnouncementsStream({
    required List<String> userRoles,
    String? category,
    int limit = 50,
  }) {
    try {
      // Check if user is admin or moderator
      final isAdmin =
          userRoles.contains('admin') || userRoles.contains('moderator');

      Query<Map<String, dynamic>> query = _firestore
          .collection('announcements')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      // Only filter by targetAudience if user is not admin/moderator
      if (!isAdmin && userRoles.isNotEmpty) {
        query = _firestore
            .collection('announcements')
            .where('targetAudience', arrayContainsAny: userRoles)
            .orderBy('createdAt', descending: true)
            .limit(limit);
      }

      if (category != null && category.isNotEmpty && category != 'All') {
        query = query.where('category', isEqualTo: category);
      }

      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          try {
            return AnnouncementModel.fromJson(doc.data(), doc.id);
          } catch (e) {
            AppLogger.error('Error parsing announcement ${doc.id}', error: e);
            rethrow;
          }
        }).toList();
      });
    } catch (e) {
      AppLogger.error('Error creating announcements stream', error: e);
      throw AnnouncementNetworkException(
        message: 'Failed to fetch announcements',
        originalError: e,
      );
    }
  }

  /// Get a single announcement by ID
  Future<AnnouncementModel> getAnnouncementById(String id) async {
    try {
      final doc = await _firestore.collection('announcements').doc(id).get();

      if (!doc.exists) {
        throw const AnnouncementNotFoundException();
      }

      return AnnouncementModel.fromJson(doc.data()!, doc.id);
    } catch (e) {
      if (e is AnnouncementNotFoundException) {
        rethrow;
      }
      AppLogger.error('Error fetching announcement $id', error: e);
      throw AnnouncementNetworkException(
        message: 'Failed to fetch announcement',
        originalError: e,
      );
    }
  }

  /// Create a new announcement
  Future<String> createAnnouncement(AnnouncementModel announcement) async {
    try {
      // If ID is empty, let Firestore generate one
      if (announcement.id.isEmpty) {
        final docRef = await _firestore
            .collection('announcements')
            .add(announcement.toJson());
        return docRef.id;
      } else {
        // Use provided ID (for cases where ID is pre-generated)
        await _firestore
            .collection('announcements')
            .doc(announcement.id)
            .set(announcement.toJson());
        return announcement.id;
      }
    } catch (e) {
      AppLogger.error('Error creating announcement', error: e);
      throw AnnouncementNetworkException(
        message: 'Failed to create announcement',
        originalError: e,
      );
    }
  }

  /// Update an existing announcement
  Future<void> updateAnnouncement(AnnouncementModel announcement) async {
    try {
      await _firestore
          .collection('announcements')
          .doc(announcement.id)
          .update(announcement.toJson());
    } catch (e) {
      AppLogger.error('Error updating announcement', error: e);
      throw AnnouncementNetworkException(
        message: 'Failed to update announcement',
        originalError: e,
      );
    }
  }

  /// Delete an announcement
  Future<void> deleteAnnouncement(String id) async {
    try {
      await _firestore.collection('announcements').doc(id).delete();
    } catch (e) {
      AppLogger.error('Error deleting announcement', error: e);
      throw AnnouncementNetworkException(
        message: 'Failed to delete announcement',
        originalError: e,
      );
    }
  }
}
