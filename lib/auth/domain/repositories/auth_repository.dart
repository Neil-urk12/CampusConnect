import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> signIn({required String email, required String password});
  Future<String> register({required String email, required String password});
  Future<void> signOut();
  Future<void> sendPasswordResetEmail({required String email});
  Future<UserEntity?> getCurrentUser();
  Stream<UserEntity?> authStateChanges();
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}
