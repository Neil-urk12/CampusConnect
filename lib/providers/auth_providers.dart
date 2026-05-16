import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

// Data Sources
import '../auth/data/data_sources/firebase_auth_data_source.dart';
import '../auth/data/data_sources/firestore_user_data_source.dart';

// Repositories
import '../auth/domain/repositories/auth_repository.dart';
import '../auth/domain/repositories/user_repository.dart';
import '../auth/data/repositories/auth_repository_impl.dart';
import '../auth/data/repositories/user_repository_impl.dart';

// Application Services
import '../auth/application/auth_service.dart';

// Entities
import '../auth/domain/entities/user_entity.dart';

// Auth State
import '../auth/presentation/providers/auth_state_provider.dart';

// Appwrite session bridge
import '../appwrite_config.dart';

// ============================================================================
// Firebase Instances
// ============================================================================

/// Provider for FirebaseAuth instance
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Provider for FirebaseFirestore instance
final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// ============================================================================
// Data Sources
// ============================================================================

/// Provider for FirebaseAuthDataSource
final firebaseAuthDataSourceProvider = Provider<FirebaseAuthDataSource>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return FirebaseAuthDataSource(firebaseAuth: firebaseAuth);
});

/// Provider for FirestoreUserDataSource
final firestoreUserDataSourceProvider = Provider<FirestoreUserDataSource>((
  ref,
) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return FirestoreUserDataSource(firestore: firestore);
});

// ============================================================================
// Repositories
// ============================================================================

/// Provider for UserRepository
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final dataSource = ref.watch(firestoreUserDataSourceProvider);
  return UserRepositoryImpl(dataSource: dataSource);
});

/// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final authDataSource = ref.watch(firebaseAuthDataSourceProvider);
  final userRepository = ref.watch(userRepositoryProvider);
  return AuthRepositoryImpl(
    authDataSource: authDataSource,
    userRepository: userRepository,
  );
});

// ============================================================================
// Application Services
// ============================================================================

/// Provider for the auth application service.
final authServiceProvider = Provider<AuthService>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final userRepository = ref.watch(userRepositoryProvider);
  return AuthService(
    authRepository: authRepository,
    userRepository: userRepository,
  );
});

// ============================================================================
// Auth State Management
// ============================================================================

/// Provider for AuthStateNotifier
/// This manages the global authentication state and listens to auth changes
final authStateNotifierProvider =
    NotifierProvider<AuthStateNotifier, AuthState>(AuthStateNotifier.new);

/// Convenience provider to get current user
final currentUserProvider = Provider<UserEntity?>((ref) {
  return ref.watch(authStateNotifierProvider).user;
});

/// Convenience provider to check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateNotifierProvider).isAuthenticated;
});

/// Convenience provider to check if user is unauthenticated
final isUnauthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateNotifierProvider).isUnauthenticated;
});

/// Convenience provider to check if auth state is loading
final isAuthLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authStateNotifierProvider).isLoading;
});

/// Convenience provider to check if user is admin or moderator
final isAdminProvider = Provider<bool>((ref) {
  final role = ref.watch(authStateNotifierProvider).user?.role ?? '';
  return role == 'admin' || role == 'moderator';
});

/// Notifier for managing authentication state
class AuthStateNotifier extends Notifier<AuthState> {
  late AuthService _authService;
  StreamSubscription<UserEntity?>? _authStateSubscription;

  @override
  AuthState build() {
    _authService = ref.watch(authServiceProvider);

    // Initialize authentication state
    _initialize();

    ref.onDispose(() {
      _authStateSubscription?.cancel();
    });

    // Return initial loading state
    return const AuthState(isLoading: true);
  }

  /// Initialize authentication state and listen to changes
  Future<void> _initialize() async {
    try {
      // Check for existing session on app start
      final currentUser = await _authService.getCurrentUser();

      // Bridge: ensure Appwrite session exists if Firebase user is logged in
      if (currentUser != null) {
        await AppwriteConfig.ensureSession();
      }

      state = AuthState(user: currentUser, isLoading: false);

      // Listen to authentication state changes
      _authStateSubscription = _authService.authStateChanges().listen(
        (user) async {
          if (user != null) {
            // User signed in — ensure Appwrite session is active
            await AppwriteConfig.ensureSession();
          } else {
            // User signed out — clean up Appwrite session
            await AppwriteConfig.deleteSession();
          }
          state = AuthState(user: user, isLoading: false);
        },
        onError: (error) {
          state = AuthState(
            user: null,
            isLoading: false,
            error: error.toString(),
          );
        },
      );
    } catch (e) {
      state = AuthState(
        user: null,
        isLoading: false,
        error: 'Failed to restore session: ${e.toString()}',
      );
    }
  }

  /// Get current user entity
  UserEntity? get currentUser => state.user;

  /// Check if user is authenticated
  bool get isAuthenticated => state.isAuthenticated;

  /// Check if user is unauthenticated
  bool get isUnauthenticated => state.isUnauthenticated;

  /// Manually refresh authentication state
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final currentUser = await _authService.getCurrentUser();
      state = AuthState(user: currentUser, isLoading: false);
    } catch (e) {
      state = AuthState(
        user: null,
        isLoading: false,
        error: 'Failed to refresh session: ${e.toString()}',
      );
    }
  }

  /// Clear any error state
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
