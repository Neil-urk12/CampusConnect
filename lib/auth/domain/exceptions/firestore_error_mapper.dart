import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_exception.dart';

/// Maps Firestore [FirebaseException] error codes to domain [AuthException]s.
///
/// Consolidates error translation previously duplicated across
/// [FirestoreUserDataSource] and [UserRepositoryImpl].
class FirestoreMapper {
  /// Translates a Firestore exception into a domain exception.
  ///
  /// [operation] is used only in the default case message (e.g. "Failed to create user").
  static AuthException mapException(
    FirebaseException e,
    String operation,
  ) {
    switch (e.code) {
      case 'permission-denied':
        return const AuthException(
          code: AuthException.permissionDenied,
          message: 'Access denied. Please sign in again.',
        );
      case 'not-found':
        return const AuthException(
          code: AuthException.notFound,
          message: 'User data not found.',
        );
      case 'unavailable':
        return const AuthException(
          code: AuthException.unavailable,
          message: 'Service temporarily unavailable. Please try again.',
        );
      case 'deadline-exceeded':
        return const AuthException(
          code: AuthException.deadlineExceeded,
          message: 'Request timed out. Please check your connection.',
        );
      case 'already-exists':
        return const AuthException(
          code: AuthException.alreadyExists,
          message: 'User already exists.',
        );
      case 'resource-exhausted':
        return const AuthException(
          code: AuthException.resourceExhausted,
          message: 'Too many requests. Please try again later.',
        );
      case 'cancelled':
        return const AuthException(
          code: AuthException.cancelled,
          message: 'Operation was cancelled.',
        );
      case 'data-loss':
      case 'internal':
        return const AuthException(
          code: AuthException.internalError,
          message: 'Internal error occurred. Please try again.',
        );
      case 'invalid-argument':
        return const AuthException(
          code: AuthException.invalidArgument,
          message: 'Invalid data provided.',
        );
      case 'failed-precondition':
        return const AuthException(
          code: AuthException.failedPrecondition,
          message: 'Operation cannot be performed in current state.',
        );
      case 'aborted':
        return const AuthException(
          code: AuthException.aborted,
          message: 'Operation was aborted. Please try again.',
        );
      case 'out-of-range':
        return const AuthException(
          code: AuthException.invalidArgument,
          message: 'Invalid data range.',
        );
      case 'unimplemented':
        return const AuthException(
          code: 'unexpected',
          message: 'This operation is not supported.',
        );
      default:
        return AuthException(
          code: AuthException.userDataError,
          message: 'Failed to $operation: ${e.message ?? "Unknown error"}',
        );
    }
  }
}
