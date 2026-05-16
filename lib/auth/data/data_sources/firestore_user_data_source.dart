import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/exceptions/auth_exception.dart';
import '../../../core/utils/app_logger.dart';

class FirestoreUserDataSource {
  final FirebaseFirestore _firestore;

  static const String _usersCollection = 'users';

  const FirestoreUserDataSource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  Future<void> createUser({
    required String userId,
    required String fullName,
    required String email,
    required String studentId,
  }) async {
    try {
      AppLogger.debug('Creating user document for userId: $userId');

      final now = FieldValue.serverTimestamp();
      final userData = {
        'fullName': fullName,
        'email': email,
        'studentId': studentId,
        'role': 'student',
        'groupMemberships': [],
        'createdAt': now,
        'updatedAt': now,
      };

      await _firestore.collection(_usersCollection).doc(userId).set(userData);

      AppLogger.info('Successfully created user document for userId: $userId');
    } on FirebaseException catch (e) {
      AppLogger.error('Firestore error creating user: ${e.code}', error: e);

      throw _mapFirestoreException(e, 'create user');
    } catch (e) {
      AppLogger.error('Unexpected error creating user', error: e);

      throw AuthException(message: 'Failed to create user: ${e.toString()}');
    }
  }

  Future<DocumentSnapshot?> getUser({required String userId}) async {
    try {
      AppLogger.debug('Fetching user document for userId: $userId');

      final docSnapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();

      if (!docSnapshot.exists) {
        AppLogger.debug('User document not found for userId: $userId');
        return null;
      }

      AppLogger.debug('Successfully fetched user document for userId: $userId');

      return docSnapshot;
    } on FirebaseException catch (e) {
      AppLogger.error('Firestore error fetching user: ${e.code}', error: e);

      throw _mapFirestoreException(e, 'fetch user');
    } catch (e) {
      AppLogger.error('Unexpected error fetching user', error: e);

      throw AuthException(message: 'Failed to fetch user: ${e.toString()}');
    }
  }

  Future<void> updateUser({
    required String userId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      AppLogger.debug(
        'Updating user document for userId: $userId with fields: ${updates.keys.join(", ")}',
      );

      final updatesWithTimestamp = {
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .update(updatesWithTimestamp);

      AppLogger.info('Successfully updated user document for userId: $userId');
    } on FirebaseException catch (e) {
      AppLogger.error('Firestore error updating user: ${e.code}', error: e);

      throw _mapFirestoreException(e, 'update user');
    } catch (e) {
      AppLogger.error('Unexpected error updating user', error: e);

      throw AuthException(message: 'Failed to update user: ${e.toString()}');
    }
  }

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
      default:
        return AuthException(code: AuthException.userDataError, message: 'Failed to $operation: ${e.message ?? "Unknown error"}');
    }
  }
}
