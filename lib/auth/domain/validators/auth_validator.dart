class AuthValidator {
  AuthValidator._();

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp _studentIdRegex = RegExp(r'^[a-zA-Z0-9]{6,10}$');

  static const int _minPasswordLength = 6;
  static const int _minPasswordLengthStrict = 8;

  static String? validateEmail(String email) {
    final trimmedEmail = email.trim();

    if (trimmedEmail.isEmpty) {
      return 'Email is required';
    }

    if (!_emailRegex.hasMatch(trimmedEmail)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Validates password with 6-character minimum.
  /// Use for current password validation (supports legacy accounts).
  static String? validatePassword(String password) {
    if (password.isEmpty) {
      return 'Password is required';
    }

    if (password.length < _minPasswordLength) {
      return 'Password must be at least $_minPasswordLength characters';
    }

    return null;
  }

  /// Validates password with 8-character minimum.
  /// Use for new password validation (stricter security requirement).
  static String? validatePasswordStrict(String password) {
    if (password.isEmpty) {
      return 'Password is required';
    }

    if (password.length < _minPasswordLengthStrict) {
      return 'Password must be at least $_minPasswordLengthStrict characters';
    }

    return null;
  }

  static String? validateRequired(String value, String fieldName) {
    final trimmedValue = value.trim();

    if (trimmedValue.isEmpty) {
      return '$fieldName is required';
    }

    return null;
  }

  static String? validateStudentId(String studentId) {
    final trimmedStudentId = studentId.trim();

    if (trimmedStudentId.isEmpty) {
      return 'Student ID is required';
    }

    if (!_studentIdRegex.hasMatch(trimmedStudentId)) {
      return 'Please enter a valid student ID (6-10 alphanumeric characters)';
    }

    return null;
  }
}
