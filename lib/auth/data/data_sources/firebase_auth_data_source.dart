import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/utils/app_logger.dart';

class FirebaseAuthDataSource {
  final FirebaseAuth _firebaseAuth;

  const FirebaseAuthDataSource({required FirebaseAuth firebaseAuth})
    : _firebaseAuth = firebaseAuth;

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.debug('Attempting sign in for email: $email');

      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      AppLogger.info('Sign in successful for user: ${credential.user?.uid}');

      return credential;
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Sign in failed with code: ${e.code}', error: e);
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected error during sign in', error: e);
      rethrow;
    }
  }

  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.debug('Attempting to create user account for email: $email');

      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      AppLogger.info(
        'User account created successfully: ${credential.user?.uid}',
      );

      return credential;
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Account creation failed with code: ${e.code}', error: e);
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected error during account creation', error: e);
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      final userId = _firebaseAuth.currentUser?.uid;
      AppLogger.debug('Attempting sign out for user: $userId');

      await _firebaseAuth.signOut();

      AppLogger.info('Sign out successful');
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Sign out failed with code: ${e.code}', error: e);
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected error during sign out', error: e);
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      AppLogger.debug('Attempting to send password reset email to: $email');

      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());

      AppLogger.info('Password reset email sent successfully');
    } on FirebaseAuthException catch (e) {
      AppLogger.error(
        'Password reset email failed with code: ${e.code}',
        error: e,
      );
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected error during password reset email', error: e);
      rethrow;
    }
  }

  User? getCurrentUser() {
    try {
      final user = _firebaseAuth.currentUser;

      if (user != null) {
        AppLogger.debug('Current user retrieved: ${user.uid}');
      } else {
        AppLogger.debug('No current user authenticated');
      }

      return user;
    } catch (e) {
      AppLogger.error('Error retrieving current user', error: e);
      rethrow;
    }
  }

  Stream<User?> authStateChanges() {
    try {
      AppLogger.debug('Creating auth state changes stream');

      return _firebaseAuth.authStateChanges();
    } catch (e) {
      AppLogger.error('Error creating auth state changes stream', error: e);
      rethrow;
    }
  }

  /// Updates the user's password after reauthenticating with the current one.
  ///
  /// Process:
  /// 1. Retrieves the currently authenticated Firebase user
  /// 2. Reauthenticates using the current password via [EmailAuthProvider]
  /// 3. Updates the password to the new value
  ///
  /// This two-step process ensures the user genuinely knows the current
  /// password before allowing a change, protecting against session hijacking.
  ///
  /// Throws:
  /// - [FirebaseAuthException] with code 'user-not-found' if no user is signed in
  /// - [FirebaseAuthException] with code 'invalid-email' if user email is unavailable
  /// - [FirebaseAuthException] with code 'wrong-password' if current password is incorrect
  /// - [FirebaseAuthException] with code 'weak-password' if new password is too short
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        AppLogger.error('No authenticated user for password update');
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No authenticated user',
        );
      }

      final email = user.email;
      if (email == null) {
        AppLogger.error('User email is null for password update');
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'User email not available',
        );
      }

      AppLogger.debug('Attempting password update for user: ${user.uid}');

      // Reauthenticate with current password
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      AppLogger.debug('Reauthentication successful');

      // Update to new password
      await user.updatePassword(newPassword);
      AppLogger.info('Password updated successfully for user: ${user.uid}');
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Password update failed with code: ${e.code}', error: e);
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected error during password update', error: e);
      rethrow;
    }
  }
}
