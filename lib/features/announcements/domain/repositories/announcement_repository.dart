import '../entities/announcement_entity.dart';

/// Returns streams for real-time updates from Firestore
abstract class AnnouncementRepository {
  /// Get a stream of announcements filtered by user's role and groups
  /// Returns announcements in reverse chronological order
  Stream<List<AnnouncementEntity>> getAnnouncementsStream({
    required String userId,
    required List<String> userRoles,
    String? category,
    int limit = 50,
  });

  /// Get a single announcement by ID
  Future<AnnouncementEntity> getAnnouncementById(String id);

  /// Create a new announcement (admin only)
  Future<String> createAnnouncement(AnnouncementEntity announcement);

  /// Update an existing announcement (admin only)
  Future<void> updateAnnouncement(AnnouncementEntity announcement);

  /// Delete an announcement (admin only)
  Future<void> deleteAnnouncement(String id);
}
