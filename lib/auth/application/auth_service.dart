import '../domain/entities/user_entity.dart';
import '../domain/exceptions/auth_exception.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/user_repository.dart';
import '../domain/validators/auth_validator.dart';

class AuthService {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  const AuthService({
    required AuthRepository authRepository,
    required UserRepository userRepository,
  }) : _authRepository = authRepository,
       _userRepository = userRepository;

  Stream<UserEntity?> authStateChanges() {
    return _authRepository.authStateChanges();
  }

  Future<UserEntity?> getCurrentUser() async {
    try {
      return await _authRepository.getCurrentUser();
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(message: e.toString());
    }
  }

  Future<UserEntity> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final emailError = AuthValidator.validateEmail(email);
      if (emailError != null) {
        throw AuthException(
          code: AuthException.validationError,
          message: emailError,
          field: 'email',
        );
      }

      final passwordError = AuthValidator.validatePassword(password);
      if (passwordError != null) {
        throw AuthException(
          code: AuthException.validationError,
          message: passwordError,
          field: 'password',
        );
      }

      return await _authRepository.signIn(
        email: email.trim(),
        password: password,
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(message: e.toString());
    }
  }

  Future<UserEntity> register({
    required String fullName,
    required String email,
    required String studentId,
    required String password,
  }) async {
    try {
      final fullNameError = AuthValidator.validateRequired(
        fullName,
        'Full name',
      );
      if (fullNameError != null) {
        throw AuthException(
          code: AuthException.validationError,
          message: fullNameError,
          field: 'fullName',
        );
      }

      final emailError = AuthValidator.validateEmail(email);
      if (emailError != null) {
        throw AuthException(
          code: AuthException.validationError,
          message: emailError,
          field: 'email',
        );
      }

      final studentIdError = AuthValidator.validateStudentId(studentId);
      if (studentIdError != null) {
        throw AuthException(
          code: AuthException.validationError,
          message: studentIdError,
          field: 'studentId',
        );
      }

      final passwordError = AuthValidator.validatePassword(password);
      if (passwordError != null) {
        throw AuthException(
          code: AuthException.validationError,
          message: passwordError,
          field: 'password',
        );
      }

      final userId = await _authRepository.register(
        email: email.trim(),
        password: password,
      );

      await _userRepository.createUserMetadata(
        userId: userId,
        fullName: fullName.trim(),
        email: email.trim(),
        studentId: studentId.trim(),
      );

      final user = await _authRepository.getCurrentUser();
      if (user == null) {
        throw AuthException(
          code: AuthException.internalError,
          message: 'Failed to retrieve user after registration',
        );
      }

      return user;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(message: e.toString());
    }
  }

  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(
        message:
            'An unexpected error occurred during sign out: ${e.toString()}',
      );
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      final emailError = AuthValidator.validateEmail(email);
      if (emailError != null) {
        throw AuthException(
          code: AuthException.validationError,
          message: emailError,
          field: 'email',
        );
      }

      await _authRepository.sendPasswordResetEmail(email: email.trim());
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(message: e.toString());
    }
  }

  Future<void> updateProfile({
    required String userId,
    required String fullName,
    required String studentId,
  }) async {
    final fullNameError = AuthValidator.validateRequired(fullName, 'Full name');
    if (fullNameError != null) {
      throw AuthException(
        code: AuthException.validationError,
        message: fullNameError,
        field: 'fullName',
      );
    }

    final studentIdError = AuthValidator.validateStudentId(studentId);
    if (studentIdError != null) {
      throw AuthException(
        code: AuthException.validationError,
        message: studentIdError,
        field: 'studentId',
      );
    }

    try {
      await _userRepository.updateUserMetadata(
        userId: userId,
        updates: {'fullName': fullName.trim(), 'studentId': studentId.trim()},
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(
        code: AuthException.userDataError,
        message: 'Failed to update profile: ${e.toString()}',
      );
    }
  }

  /// Changes the user's password after validating current and new passwords.
  ///
  /// Validates the current password with a 6-character minimum (supporting
  /// legacy accounts) and the new password with an 8-character minimum
  /// for stronger security. Also ensures the new password differs from the
  /// current one.
  ///
  /// Throws:
  /// - [AuthException] with field 'currentPassword' if current password is invalid
  /// - [AuthException] with field 'newPassword' if new password is invalid
  /// - [AuthException] if the current password is incorrect
  /// - [AuthException] for network or service errors
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // Validate current password (6-char minimum for legacy accounts)
      final currentPasswordError = AuthValidator.validatePassword(
        currentPassword,
      );
      if (currentPasswordError != null) {
        throw AuthException(
          code: AuthException.validationError,
          message: currentPasswordError,
          field: 'currentPassword',
        );
      }

      // Validate new password (8-char minimum, stricter requirement)
      final newPasswordError = AuthValidator.validatePasswordStrict(
        newPassword,
      );
      if (newPasswordError != null) {
        throw AuthException(
          code: AuthException.validationError,
          message: newPasswordError,
          field: 'newPassword',
        );
      }

      // Validate new password differs from current
      if (currentPassword == newPassword) {
        throw const AuthException(
          code: AuthException.validationError,
          message: 'New password must be different from current password',
          field: 'newPassword',
        );
      }

      await _authRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(message: 'Password change failed: ${e.toString()}');
    }
  }
}
