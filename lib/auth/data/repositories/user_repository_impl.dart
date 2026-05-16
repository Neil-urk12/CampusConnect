import '../../../core/utils/app_logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/exceptions/auth_exception.dart';
import '../../domain/repositories/user_repository.dart';
import '../data_sources/firestore_user_data_source.dart';
import '../models/user_model.dart';

/// Implementation of [UserRepository] using Cloud Firestore.
///
/// This repository manages user metadata stored in Firestore, providing
/// operations for creating, reading, and updating user documents. It handles:
/// - User metadata creation during registration
/// - User metadata retrieval for authenticated users
/// - User metadata updates (profile changes, group memberships)
///
/// All Firestore exceptions are mapped to domain-specific AuthExceptions
/// with user-friendly error messages.
///
/// Requirements: 1.5, 2.5, 7.1, 7.2, 7.3, 7.4, 7.5, 10.3
class UserRepositoryImpl implements UserRepository {
  final FirestoreUserDataSource _dataSource;

  const UserRepositoryImpl({required FirestoreUserDataSource dataSource})
    : _dataSource = dataSource;

  /// Creates user metadata in Firestore during registration.
  ///
  /// This method is called after Firebase Authentication account creation
  /// to store additional user information in Firestore. The document is
  /// created at users/{userId} with the following fields:
  /// - fullName: User's full name
  /// - email: User's email address
  /// - studentId: Student identification number
  /// - role: User role (defaults to 'student')
  /// - groupMemberships: List of group IDs (defaults to empty list)
  /// - createdAt: Document creation timestamp
  /// - updatedAt: Document last update timestamp
  ///
  /// Throws:
  /// - [AuthException] if document creation fails
  /// - [AuthException] if user already exists
  /// - [AuthException] if permission is denied
  ///
  /// Requirements: 1.5, 7.1, 7.2, 7.4
  @override
  Future<void> createUserMetadata({
    required String userId,
    required String fullName,
    required String email,
    required String studentId,
  }) async {
    try {
      AppLogger.debug(
        'UserRepository: Creating metadata for userId: $userId',
      );

      await _dataSource.createUser(
        userId: userId,
        fullName: fullName,
        email: email,
        studentId: studentId,
      );

      AppLogger.debug(
        'UserRepository: Metadata created successfully for userId: $userId',
      );
    } on AuthException {
      rethrow;
    } on FirebaseException catch (e) {
      AppLogger.debug(
        'UserRepository: Firestore error creating metadata: ${e.code}',
        error: e,
      );
      throw _mapFirestoreException(e, 'create user metadata');
    } catch (e) {
      AppLogger.debug(
        'UserRepository: Unexpected error creating metadata',
        error: e,
      );
      throw AuthException(message: 'Failed to create user metadata: ${e.toString()}');
    }
  }

  /// Retrieves user metadata from Firestore.
  ///
  /// This method is called during sign-in and session restoration to load
  /// complete user information. It converts the Firestore document to a
  /// domain UserEntity.
  ///
  /// Returns null if the user document doesn't exist. This is not considered
  /// an error condition - the caller should handle missing metadata appropriately
  /// (e.g., by prompting profile completion or re-authentication).
  ///
  /// Throws:
  /// - [AuthException] if Firestore read fails
  /// - [AuthException] if permission is denied
  /// - [AuthException] if document data is malformed
  ///
  /// Requirements: 2.5, 7.3, 7.5
  @override
  Future<UserEntity?> getUserMetadata({required String userId}) async {
    try {
      AppLogger.debug(
        'UserRepository: Fetching metadata for userId: $userId',
      );

      final docSnapshot = await _dataSource.getUser(userId: userId);

      if (docSnapshot == null) {
        AppLogger.debug(
          'UserRepository: No metadata found for userId: $userId',
        );
        return null;
      }

      final userModel = UserModel.fromFirestore(docSnapshot);
      final userEntity = userModel.toEntity();

      AppLogger.debug(
        'UserRepository: Metadata retrieved successfully for userId: $userId',
      );

      return userEntity;
    } on AuthException {
      rethrow;
    } on FirebaseException catch (e) {
      AppLogger.debug(
        'UserRepository: Firestore error fetching metadata: ${e.code}',
        error: e,
      );
      throw _mapFirestoreException(e, 'fetch user metadata');
    } on FormatException catch (e) {
      AppLogger.debug(
        'UserRepository: Document format error for userId: $userId',
        error: e,
      );
      throw AuthException(code: AuthException.userDataError, message: 'User data is malformed. Please contact support.');
    } catch (e) {
      AppLogger.debug(
        'UserRepository: Unexpected error fetching metadata',
        error: e,
      );
      throw AuthException(message: 'Failed to fetch user metadata: ${e.toString()}');
    }
  }

  /// Updates user metadata in Firestore.
  ///
  /// This method allows updating specific fields in the user document without
  /// replacing the entire document. Common use cases include:
  /// - Updating profile information (fullName, studentId)
  /// - Managing group memberships
  /// - Updating role assignments
  ///
  /// The updatedAt timestamp is automatically set by the data source.
  ///
  /// Example:
  /// ```dart
  /// await updateUserMetadata(
  ///   userId: 'user123',
  ///   updates: {
  ///     'fullName': 'New Name',
  ///     'groupMemberships': ['group1', 'group2'],
  ///   },
  /// );
  /// ```
  ///
  /// Throws:
  /// - [AuthException] if the document doesn't exist
  /// - [AuthException] if Firestore update fails
  /// - [AuthException] if permission is denied
  ///
  /// Requirements: 7.3, 7.5, 10.3
  @override
  Future<void> updateUserMetadata({
    required String userId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      AppLogger.debug(
        'UserRepository: Updating metadata for userId: $userId with fields: ${updates.keys.join(", ")}',
      );

      _validateUpdates(updates);

      await _dataSource.updateUser(userId: userId, updates: updates);

      AppLogger.debug(
        'UserRepository: Metadata updated successfully for userId: $userId',
      );
    } on AuthException {
      rethrow;
    } on FirebaseException catch (e) {
      AppLogger.debug(
        'UserRepository: Firestore error updating metadata: ${e.code}',
        error: e,
      );
      throw _mapFirestoreException(e, 'update user metadata');
    } catch (e) {
      AppLogger.debug(
        'UserRepository: Unexpected error updating metadata',
        error: e,
      );
      throw AuthException(message: 'Failed to update user metadata: ${e.toString()}');
    }
  }

  /// Validates update fields to prevent modification of protected fields.
  ///
  /// Protected fields that should not be updated directly:
  /// - userId: Immutable identifier
  /// - createdAt: Should never change after creation
  ///
  /// Throws [AuthException] if protected fields are present in updates.
  void _validateUpdates(Map<String, dynamic> updates) {
    const protectedFields = ['userId', 'createdAt'];

    for (final field in protectedFields) {
      if (updates.containsKey(field)) {
        throw AuthException(code: AuthException.invalidArgument, message: 'Cannot update protected field: $field');
      }
    }
  }

  /// Maps Firestore exceptions to domain-specific AuthExceptions.
  ///
  /// This provides consistent error handling across all Firestore operations
  /// and translates Firebase error codes into user-friendly messages that
  /// match the design document specifications.
  ///
  /// Requirements: 7.5, 10.3
  AuthException _mapFirestoreException(FirebaseException e, String operation) {
    switch (e.code) {
      case 'permission-denied':
        return AuthException(code: AuthException.permissionDenied, message: 'Access denied. Please sign in again.');

      case 'not-found':
        return AuthException(code: AuthException.notFound, message: 'User data not found.');

      case 'unavailable':
        return AuthException(code: AuthException.unavailable, message: 'Service temporarily unavailable. Please try again.');

      case 'deadline-exceeded':
        return AuthException(code: AuthException.deadlineExceeded, message: 'Request timed out. Please check your connection.');

      case 'already-exists':
        return AuthException(code: AuthException.alreadyExists, message: 'User already exists.');

      case 'resource-exhausted':
        return AuthException(code: AuthException.resourceExhausted, message: 'Too many requests. Please try again later.');

      case 'cancelled':
        return AuthException(code: AuthException.cancelled, message: 'Operation was cancelled.');

      case 'data-loss':
      case 'internal':
        return AuthException(code: AuthException.internalError, message: 'Internal error occurred. Please try again.');

      case 'invalid-argument':
        return AuthException(code: AuthException.invalidArgument, message: 'Invalid data provided.');

      case 'failed-precondition':
        return AuthException(code: AuthException.failedPrecondition, message: 'Operation cannot be performed in current state.');

      case 'aborted':
        return AuthException(code: AuthException.aborted, message: 'Operation was aborted. Please try again.');

      case 'out-of-range':
        return AuthException(code: AuthException.invalidArgument, message: 'Invalid data range.');

      case 'unimplemented':
        return AuthException(code: 'unexpected', message: 'This operation is not supported.');

      default:
        AppLogger.debug(
          'Unmapped Firestore error code: ${e.code}',
        );
        return AuthException(code: AuthException.userDataError, message: 'Failed to $operation: ${e.message ?? "Unknown error"}');
    }
  }
}
