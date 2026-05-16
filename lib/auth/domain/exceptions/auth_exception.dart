/// Consolidated exception for all auth-domain errors.
///
/// Replaces the previous 6-class hierarchy (AuthException, ValidationException,
/// NetworkException, ServiceException, UserException). Callers catch a single
/// [AuthException] and dispatch on [code].
///
/// [message] carries a human-readable detail. [field] identifies which input
/// field failed validation (primarily for validation errors).
class AuthException implements Exception {
  final String code;
  final String message;
  final String? field;

  const AuthException({
    this.code = 'unexpected',
    this.message = '',
    this.field,
  });

  // ── Error codes ──────────────────────────────────────────────────────
  static const String invalidCredentials = 'invalid-credentials';
  static const String emailAlreadyInUse = 'email-already-in-use';
  static const String userDisabled = 'user-disabled';
  static const String sessionExpired = 'session-expired';
  static const String tooManyRequests = 'too-many-requests';
  static const String operationNotAllowed = 'operation-not-allowed';
  static const String networkError = 'network-error';
  static const String serviceError = 'service-error';
  static const String validationError = 'validation-error';
  static const String permissionDenied = 'permission-denied';
  static const String notFound = 'not-found';
  static const String userDataError = 'user-data-error';
  static const String deadlineExceeded = 'deadline-exceeded';
  static const String resourceExhausted = 'resource-exhausted';
  static const String cancelled = 'cancelled';
  static const String alreadyExists = 'already-exists';
  static const String invalidArgument = 'invalid-argument';
  static const String failedPrecondition = 'failed-precondition';
  static const String aborted = 'aborted';
  static const String unavailable = 'unavailable';
  static const String internalError = 'internal-error';

  @override
  String toString() =>
      'AuthException($code)${message.isNotEmpty ? ': $message' : ''}';
}
