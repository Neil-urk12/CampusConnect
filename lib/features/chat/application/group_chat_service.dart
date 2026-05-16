import '../domain/entities/group_chat.dart';
import '../domain/repositories/group_chat_repository.dart';

/// Service layer for group chat operations.
class GroupChatService {
  final GroupChatRepository _repository;

  GroupChatService({required GroupChatRepository repository})
    : _repository = repository;

  /// Fetches all group chats where the user is a member.
  Future<List<GroupChat>> getUserChats(String userId) async {
    try {
      return await _repository.getUserChats(userId);
    } catch (e) {
      throw Exception('Failed to get user chats: $e');
    }
  }

  /// Creates a new group chat.
  Future<GroupChat> createGroupChat({
    required String name,
    String? description,
    required List<String> memberIds,
    required String creatorId,
    required bool isPublic,
    String? avatarUrl,
  }) async {
    try {
      return await _repository.createGroupChat(
        name: name,
        description: description,
        memberIds: memberIds,
        creatorId: creatorId,
        isPublic: isPublic,
        avatarUrl: avatarUrl,
      );
    } catch (e) {
      throw Exception('Failed to create group chat: $e');
    }
  }

  /// Fetches a single group chat by ID.
  Future<GroupChat> getGroupChatById(String chatId) async {
    try {
      return await _repository.getGroupChatById(chatId);
    } catch (e) {
      throw Exception('Failed to get group chat: $e');
    }
  }

  /// Adds members to an existing group chat.
  Future<void> addMembers(String chatId, List<String> memberIds) async {
    try {
      await _repository.addMembers(chatId, memberIds);
    } catch (e) {
      throw Exception('Failed to add members: $e');
    }
  }

  /// Updates group chat details (name, description, avatarUrl).
  Future<void> updateGroupChat({
    required String chatId,
    String? name,
    String? description,
    String? avatarUrl,
  }) async {
    try {
      await _repository.updateGroupChat(
        chatId: chatId,
        name: name,
        description: description,
        avatarUrl: avatarUrl,
      );
    } catch (e) {
      throw Exception('Failed to update group chat: $e');
    }
  }
}
