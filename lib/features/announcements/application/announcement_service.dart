import '../domain/entities/announcement_entity.dart';
import '../domain/repositories/announcement_repository.dart';
import '../domain/exceptions/announcement_exceptions.dart';

class AnnouncementService {
  final AnnouncementRepository _repository;

  const AnnouncementService({required AnnouncementRepository repository})
    : _repository = repository;

  /// Get announcements stream filtered by user's roles and optional category
  /// Automatically filters based on targetAudience matching user roles
  Stream<List<AnnouncementEntity>> getAnnouncementsStream({
    required String userId,
    required List<String> userRoles,
    String? category,
    int limit = 50,
  }) {
    try {
      if (userRoles.isEmpty) {
        // Return empty stream if user has no roles
        return Stream.value([]);
      }

      return _repository.getAnnouncementsStream(
        userId: userId,
        userRoles: userRoles,
        category: category,
        limit: limit,
      );
    } on AnnouncementException {
      rethrow;
    } catch (e) {
      throw AnnouncementNetworkException(
        message: 'Failed to fetch announcements stream',
        originalError: e,
      );
    }
  }

  /// Get a single announcement by ID
  Future<AnnouncementEntity> getAnnouncementById(String id) async {
    try {
      if (id.isEmpty) {
        throw const AnnouncementValidationException(
          message: 'Announcement ID cannot be empty',
        );
      }

      return await _repository.getAnnouncementById(id);
    } on AnnouncementException {
      rethrow;
    } catch (e) {
      throw AnnouncementNetworkException(
        message: 'Failed to fetch announcement',
        originalError: e,
      );
    }
  }

  /// Create a new announcement (admin/moderator only)
  Future<String> createAnnouncement({
    required AnnouncementEntity announcement,
    required List<String> userRoles,
  }) async {
    try {
      // Check if user has admin or moderator role
      if (!_hasAdminPermission(userRoles)) {
        throw const AnnouncementPermissionException(
          message: 'Only admins and moderators can create announcements',
        );
      }

      // Validate announcement data
      _validateAnnouncement(announcement);

      return await _repository.createAnnouncement(announcement);
    } on AnnouncementException {
      rethrow;
    } catch (e) {
      throw AnnouncementNetworkException(
        message: 'Failed to create announcement',
        originalError: e,
      );
    }
  }

  /// Update an existing announcement (admin/moderator only)
  Future<void> updateAnnouncement({
    required AnnouncementEntity announcement,
    required List<String> userRoles,
  }) async {
    try {
      // Check if user has admin or moderator role
      if (!_hasAdminPermission(userRoles)) {
        throw const AnnouncementPermissionException(
          message: 'Only admins and moderators can update announcements',
        );
      }

      // Validate announcement data
      _validateAnnouncement(announcement);

      await _repository.updateAnnouncement(announcement);
    } on AnnouncementException {
      rethrow;
    } catch (e) {
      throw AnnouncementNetworkException(
        message: 'Failed to update announcement',
        originalError: e,
      );
    }
  }

  /// Delete an announcement (admin/moderator only)
  Future<void> deleteAnnouncement({
    required String id,
    required List<String> userRoles,
  }) async {
    try {
      // Check if user has admin or moderator role
      if (!_hasAdminPermission(userRoles)) {
        throw const AnnouncementPermissionException(
          message: 'Only admins and moderators can delete announcements',
        );
      }

      if (id.isEmpty) {
        throw const AnnouncementValidationException(
          message: 'Announcement ID cannot be empty',
        );
      }

      await _repository.deleteAnnouncement(id);
    } on AnnouncementException {
      rethrow;
    } catch (e) {
      throw AnnouncementNetworkException(
        message: 'Failed to delete announcement',
        originalError: e,
      );
    }
  }

  /// Check if user has admin or moderator permission
  bool _hasAdminPermission(List<String> userRoles) {
    return userRoles.contains('admin') || userRoles.contains('moderator');
  }

  /// Validate announcement data
  void _validateAnnouncement(AnnouncementEntity announcement) {
    if (announcement.title.trim().isEmpty) {
      throw const AnnouncementValidationException(
        message: 'Title cannot be empty',
      );
    }

    if (announcement.body.trim().isEmpty) {
      throw const AnnouncementValidationException(
        message: 'Body cannot be empty',
      );
    }

    if (announcement.category.trim().isEmpty) {
      throw const AnnouncementValidationException(
        message: 'Category cannot be empty',
      );
    }

    if (announcement.targetAudience.isEmpty) {
      throw const AnnouncementValidationException(
        message: 'Target audience cannot be empty',
      );
    }

    if (announcement.authorId.trim().isEmpty) {
      throw const AnnouncementValidationException(
        message: 'Author ID cannot be empty',
      );
    }

    if (announcement.authorName.trim().isEmpty) {
      throw const AnnouncementValidationException(
        message: 'Author name cannot be empty',
      );
    }
  }
}
