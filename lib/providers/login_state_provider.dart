import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/domain/exceptions/auth_exception.dart';
import '../auth/presentation/utils/error_message_mapper.dart';
import 'auth_providers.dart';

/// State class for login screen
class LoginState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const LoginState({this.isLoading = false, this.errorMessage, this.isSuccess = false});

  LoginState copyWith({bool? isLoading, String? errorMessage, bool? isSuccess}) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

/// StateNotifier for managing login state and operations
class LoginNotifier extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginState();

  /// Sign in with email and password.
  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signIn(email: email, password: password);

      // Refresh auth state so auth gate detects the authenticated user
      ref.read(authStateNotifierProvider.notifier).refresh();

      state = state.copyWith(isLoading: false, isSuccess: true);
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: ErrorMessageMapper.map(e),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: ErrorMessageMapper.mapException(e),
      );
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Provider for the login state notifier
final loginProvider = NotifierProvider<LoginNotifier, LoginState>(() {
  return LoginNotifier();
});
