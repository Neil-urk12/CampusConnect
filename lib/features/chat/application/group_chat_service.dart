import '../domain/entities/group_chat.dart';
import '../domain/exceptions/chat_exceptions.dart';
import '../domain/repositories/group_chat_repository.dart';

/// Service layer for group chat operations.
///
/// Adds validation, permission checks, and error wrapping
/// on top of the repository seam.
class GroupChatService {
  final GroupChatRepository _repository;

  const GroupChatService({
    required GroupChatRepository repository,
  }) : _repository = repository;

  /// Get all chats visible to a user (their memberships + public chats).
  Future<List<GroupChat>> getUserChats(String userId) async {
    try {
      if (userId.isEmpty) {
        throw const ChatException(
          code: ChatException.validationError,
          message: 'User ID cannot be empty',
        );
      }
      return await _repository.getUserChats(userId);
    } on ChatException {
      rethrow;
    } catch (e) {
      throw ChatException(
        code: ChatException.networkError,
        message: 'Failed to fetch chats',
        originalError: e,
      );
    }
  }

  /// Get a single group chat by ID.
  Future<GroupChat> getGroupChatById(String chatId) async {
    try {
      if (chatId.isEmpty) {
        throw const ChatException(
          code: ChatException.validationError,
          message: 'Chat ID cannot be empty',
        );
      }
      return await _repository.getGroupChatById(chatId);
    } on ChatException {
      rethrow;
    } catch (e) {
      throw ChatException(
        code: ChatException.networkError,
        message: 'Failed to fetch group chat',
        originalError: e,
      );
    }
  }

  /// Create a new group chat.
  ///
  /// Validates name and ensures creator is included in memberIds.
  Future<GroupChat> createGroupChat({
    required String name,
    String? description,
    required List<String> memberIds,
    required String creatorId,
    required bool isPublic,
    String? avatarUrl,
  }) async {
    try {
      _validateGroupChatName(name);
      name = name.trim();

      if (creatorId.isEmpty) {
        throw const ChatException(
          code: ChatException.validationError,
          message: 'Creator ID cannot be empty',
        );
      }

      // Ensure creator is in memberIds
      if (!memberIds.contains(creatorId)) {
        memberIds = [...memberIds, creatorId];
      }

      return await _repository.createGroupChat(
        name: name,
        description: description,
        memberIds: memberIds,
        creatorId: creatorId,
        isPublic: isPublic,
        avatarUrl: avatarUrl,
      );
    } on ChatException {
      rethrow;
    } catch (e) {
      throw ChatException(
        code: ChatException.networkError,
        message: 'Failed to create group chat',
        originalError: e,
      );
    }
  }

  /// Update a group chat's name, description, or avatar.
  ///
  /// Only the chat creator or an admin can update.
  Future<void> updateGroupChat({
    required String chatId,
    required String currentUserId,
    required String currentUserRole,
    String? name,
    String? description,
    String? avatarUrl,
  }) async {
    try {
      if (chatId.isEmpty) {
        throw const ChatException(
          code: ChatException.validationError,
          message: 'Chat ID cannot be empty',
        );
      }

      if (name != null) {
        _validateGroupChatName(name);
        name = name.trim();
      }

      // Permission check: creator or admin
      final chat = await _repository.getGroupChatById(chatId);
      _assertCanEditChat(
        currentUserId: currentUserId,
        currentUserRole: currentUserRole,
        creatorId: chat.creatorId,
      );

      await _repository.updateGroupChat(
        chatId: chatId,
        name: name,
        description: description,
        avatarUrl: avatarUrl,
      );
    } on ChatException {
      rethrow;
    } catch (e) {
      throw ChatException(
        code: ChatException.networkError,
        message: 'Failed to update group chat',
        originalError: e,
      );
    }
  }

  /// Add members to a group chat.
  ///
  /// Only the chat creator or an admin can add members.
  /// Skips users who are already members.
  Future<void> addMembers({
    required String chatId,
    required List<String> memberIds,
    required String currentUserId,
    required String currentUserRole,
  }) async {
    try {
      if (chatId.isEmpty) {
        throw const ChatException(
          code: ChatException.validationError,
          message: 'Chat ID cannot be empty',
        );
      }

      if (memberIds.isEmpty) {
        throw const ChatException(
          code: ChatException.validationError,
          message: 'Member list cannot be empty',
        );
      }

      // Permission check: creator or admin
      final chat = await _repository.getGroupChatById(chatId);
      _assertCanEditChat(
        currentUserId: currentUserId,
        currentUserRole: currentUserRole,
        creatorId: chat.creatorId,
      );

      // Filter out existing members
      final newMembers = memberIds
          .where((id) => !chat.memberIds.contains(id))
          .toList();

      if (newMembers.isEmpty) return;

      await _repository.addMembers(chatId, newMembers);
    } on ChatException {
      rethrow;
    } catch (e) {
      throw ChatException(
        code: ChatException.networkError,
        message: 'Failed to add members',
        originalError: e,
      );
    }
  }

  /// Add members with cross-document sync (groupMemberships on user docs).
  ///
  /// Uses a Firestore batch to atomically update both the chat's memberIds
  /// and each user's groupMemberships. Only the chat creator or an admin
  /// can add members.
  Future<void> addMembersWithSync({
    required String chatId,
    required List<String> memberIds,
    required String currentUserId,
    required String currentUserRole,
  }) async {
    try {
      if (chatId.isEmpty) {
        throw const ChatException(
          code: ChatException.validationError,
          message: 'Chat ID cannot be empty',
        );
      }

      if (memberIds.isEmpty) {
        throw const ChatException(
          code: ChatException.validationError,
          message: 'Member list cannot be empty',
        );
      }

      // Permission check: creator or admin
      final chat = await _repository.getGroupChatById(chatId);
      _assertCanEditChat(
        currentUserId: currentUserId,
        currentUserRole: currentUserRole,
        creatorId: chat.creatorId,
      );

      // Filter out existing members
      final newMembers = memberIds
          .where((id) => !chat.memberIds.contains(id))
          .toList();

      if (newMembers.isEmpty) return;

      await _repository.addMembersWithSync(chatId, newMembers);
    } on ChatException {
      rethrow;
    } catch (e) {
      throw ChatException(
        code: ChatException.networkError,
        message: 'Failed to add members with sync',
        originalError: e,
      );
    }
  }

  /// Join a public chat as the current user.
  ///
  /// No permission check — any authenticated user can join a public chat.
  /// Throws if the chat is private or the user is already a member.
  Future<void> joinPublicChat({
    required String chatId,
    required String userId,
  }) async {
    try {
      if (chatId.isEmpty) {
        throw const ChatException(
          code: ChatException.validationError,
          message: 'Chat ID cannot be empty',
        );
      }
      if (userId.isEmpty) {
        throw const ChatException(
          code: ChatException.validationError,
          message: 'User ID cannot be empty',
        );
      }

      final chat = await _repository.getGroupChatById(chatId);

      if (!chat.isPublic) {
        throw const ChatException(
          code: ChatException.permissionDenied,
          message: 'Cannot join a private chat without an invitation',
        );
      }

      if (chat.memberIds.contains(userId)) return;

      await _repository.addMembersWithSync(chatId, [userId]);
    } on ChatException {
      rethrow;
    } catch (e) {
      throw ChatException(
        code: ChatException.networkError,
        message: 'Failed to join chat',
        originalError: e,
      );
    }
  }

  /// Check if a user can edit a chat (creator or admin).
  bool canEditChat({
    required String currentUserId,
    required String currentUserRole,
    required String creatorId,
  }) {
    if (currentUserRole == 'admin') return true;
    if (currentUserId == creatorId) return true;
    return false;
  }

  // --- Private helpers ---

  void _validateGroupChatName(String name) {
    if (name.trim().isEmpty) {
      throw const ChatException(
        code: ChatException.validationError,
        message: 'Group name cannot be empty',
      );
    }
    if (name.trim().length < 3) {
      throw const ChatException(
        code: ChatException.validationError,
        message: 'Group name must be at least 3 characters',
      );
    }
    if (name.trim().length > 100) {
      throw const ChatException(
        code: ChatException.validationError,
        message: 'Group name must be 100 characters or less',
      );
    }
  }

  void _assertCanEditChat({
    required String currentUserId,
    required String currentUserRole,
    required String creatorId,
  }) {
    if (!canEditChat(
      currentUserId: currentUserId,
      currentUserRole: currentUserRole,
      creatorId: creatorId,
    )) {
      throw const ChatException(
        code: ChatException.permissionDenied,
        message: 'Only the chat creator or an admin can perform this action',
      );
    }
  }
}
