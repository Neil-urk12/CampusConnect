import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/group_chat_service.dart';
import '../data/datasources/firestore_group_chat_datasource.dart';
import '../data/repositories/group_chat_repository_impl.dart';
import '../domain/entities/group_chat.dart';
import '../domain/repositories/group_chat_repository.dart';

/// Provider for FirestoreGroupChatDataSource.
final groupChatDataSourceProvider = Provider<FirestoreGroupChatDataSource>((
  ref,
) {
  return FirestoreGroupChatDataSource();
});

/// Provider for GroupChatRepository.
final groupChatRepositoryProvider = Provider<GroupChatRepository>((ref) {
  final dataSource = ref.watch(groupChatDataSourceProvider);
  return GroupChatRepositoryImpl(dataSource: dataSource);
});

/// Provider for GroupChatService.
final groupChatServiceProvider = Provider<GroupChatService>((ref) {
  final repository = ref.watch(groupChatRepositoryProvider);
  return GroupChatService(repository: repository);
});

/// Provider for fetching user's group chats.
final userGroupChatsProvider = FutureProvider.family<List<GroupChat>, String>((
  ref,
  userId,
) async {
  final service = ref.watch(groupChatServiceProvider);
  return await service.getUserChats(userId);
});

/// Provider for fetching a single group chat by ID.
final groupChatByIdProvider = FutureProvider.family<GroupChat, String>((
  ref,
  chatId,
) async {
  final service = ref.watch(groupChatServiceProvider);
  return await service.getGroupChatById(chatId);
});
