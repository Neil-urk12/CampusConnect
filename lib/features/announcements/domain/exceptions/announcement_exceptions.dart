/// Base exception for announcement-related errors
class AnnouncementException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AnnouncementException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() =>
      'AnnouncementException: $message${code != null ? ' (code: $code)' : ''}';
}

/// Exception thrown when an announcement is not found
class AnnouncementNotFoundException extends AnnouncementException {
  const AnnouncementNotFoundException({
    super.message = 'Announcement not found',
    super.code,
    super.originalError,
  });
}

/// Exception thrown when user lacks permission to access/modify an announcement
class AnnouncementPermissionException extends AnnouncementException {
  const AnnouncementPermissionException({
    super.message = 'Permission denied',
    super.code,
    super.originalError,
  });
}

/// Exception thrown when announcement data is invalid
class AnnouncementValidationException extends AnnouncementException {
  const AnnouncementValidationException({
    super.message = 'Invalid announcement data',
    super.code,
    super.originalError,
  });
}

/// Exception thrown when a network/Firestore operation fails
class AnnouncementNetworkException extends AnnouncementException {
  const AnnouncementNetworkException({
    super.message = 'Network error occurred',
    super.code,
    super.originalError,
  });
}
