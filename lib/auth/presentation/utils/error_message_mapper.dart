import '../../../auth/domain/exceptions/auth_exception.dart';

/// Utility class for mapping domain exceptions to user-friendly error messages.
class ErrorMessageMapper {
  ErrorMessageMapper._();

  /// Maps an [AuthException] to a user-friendly error message based on its code.
  static String map(AuthException e) {
    switch (e.code) {
      case AuthException.invalidCredentials:
        return 'Invalid email or password.';
      case AuthException.emailAlreadyInUse:
        return 'This email is already registered. Please sign in instead.';
      case AuthException.userDisabled:
        return 'This account has been disabled. Please contact support.';
      case AuthException.tooManyRequests:
        return 'Too many failed attempts. Please try again later.';
      case AuthException.operationNotAllowed:
        return 'This operation is not allowed. Please contact support.';
      case AuthException.sessionExpired:
        return 'Your session has expired. Please sign in again.';
      case AuthException.networkError:
        return 'Network error. Please check your connection.';
      case AuthException.deadlineExceeded:
        return 'Request timed out. Please check your connection.';
      case AuthException.serviceError:
      case AuthException.unavailable:
        return 'Service temporarily unavailable. Please try again.';
      case AuthException.permissionDenied:
        return 'Access denied. Please sign in again.';
      case AuthException.notFound:
        return 'User data not found.';
      case AuthException.userDataError:
      case AuthException.internalError:
        return 'Failed to load user data. Please try again.';
      case AuthException.validationError:
        return e.message.isNotEmpty ? e.message : 'Invalid input.';
      default:
        return e.message.isNotEmpty ? e.message : 'An unexpected error occurred. Please try again.';
    }
  }

  /// Maps any exception to a user-friendly error message.
  ///
  /// Delegates to [map] for [AuthException]; returns a generic fallback for
  /// unknown exception types.
  static String mapException(Object exception) {
    if (exception is AuthException) return map(exception);
    return 'An unexpected error occurred. Please try again.';
  }
}
