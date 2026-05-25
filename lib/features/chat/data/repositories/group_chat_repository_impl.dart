import '../../domain/entities/group_chat.dart';
import '../../domain/repositories/group_chat_repository.dart';
import '../datasources/firestore_group_chat_datasource.dart';

/// Implementation of GroupChatRepository using Firestore.
class GroupChatRepositoryImpl implements GroupChatRepository {
  final FirestoreGroupChatDataSource _dataSource;

  GroupChatRepositoryImpl({required FirestoreGroupChatDataSource dataSource})
    : _dataSource = dataSource;

  @override
  Future<List<GroupChat>> getUserChats(String userId) async {
    return await _dataSource.getUserChats(userId);
  }

  @override
  Future<GroupChat> createGroupChat({
    required String name,
    String? description,
    required List<String> memberIds,
    required String creatorId,
    required bool isPublic,
    String? avatarUrl,
  }) async {
    return await _dataSource.createGroupChat(
      name: name,
      description: description,
      memberIds: memberIds,
      creatorId: creatorId,
      isPublic: isPublic,
      avatarUrl: avatarUrl,
    );
  }

  @override
  Future<GroupChat> getGroupChatById(String chatId) async {
    return await _dataSource.getGroupChatById(chatId);
  }

  @override
  Future<void> addMembers(String chatId, List<String> memberIds) async {
    await _dataSource.addMembers(chatId, memberIds);
  }

  @override
  /// Adds members to a group chat and syncs with UserModel.groupMemberships.
  Future<void> addMembersWithSync(String chatId, List<String> memberIds) async {
    await _dataSource.addMembersWithSync(chatId, memberIds);
  }

  @override
  Future<void> updateGroupChat({
    required String chatId,
    String? name,
    String? description,
    String? avatarUrl,
  }) async {
    await _dataSource.updateGroupChat(
      chatId: chatId,
      name: name,
      description: description,
      avatarUrl: avatarUrl,
    );
  }
}
