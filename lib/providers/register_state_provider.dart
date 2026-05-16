import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/domain/exceptions/auth_exception.dart';
import '../auth/presentation/utils/error_message_mapper.dart';

import 'auth_providers.dart';

/// State class for register screen
class RegisterState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const RegisterState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  RegisterState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return RegisterState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

/// Notifier for managing register state and operations
class RegisterNotifier extends Notifier<RegisterState> {
  @override
  RegisterState build() => const RegisterState();

  /// Register with full name, email, student ID, and password
  Future<bool> register({
    required String fullName,
    required String email,
    required String studentId,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final authService = ref.read(authServiceProvider);

      await authService.register(
        fullName: fullName,
        email: email,
        studentId: studentId,
        password: password,
      );

      // Refresh auth state so auth gate detects the new user
      ref.read(authStateNotifierProvider.notifier).refresh();

      state = state.copyWith(isLoading: false, isSuccess: true);

      return true;
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: ErrorMessageMapper.map(e),
        isSuccess: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: ErrorMessageMapper.mapException(e),
        isSuccess: false,
      );
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Provider for the register state notifier
final registerProvider = NotifierProvider<RegisterNotifier, RegisterState>(() {
  return RegisterNotifier();
});
