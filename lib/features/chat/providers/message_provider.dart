import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/message_service.dart';
import '../data/datasources/firestore_message_datasource.dart';
import '../data/repositories/message_repository_impl.dart';
import '../domain/entities/message.dart';
import '../domain/repositories/message_repository.dart';
import 'group_chat_provider.dart';

/// Provider for FirestoreMessageDataSource.
final messageDataSourceProvider = Provider<FirestoreMessageDataSource>((ref) {
  return FirestoreMessageDataSource();
});

/// Provider for MessageRepository.
final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  final dataSource = ref.watch(messageDataSourceProvider);
  return MessageRepositoryImpl(dataSource: dataSource);
});

/// Provider for MessageService.
final messageServiceProvider = Provider<MessageService>((ref) {
  final messageRepository = ref.watch(messageRepositoryProvider);
  final chatRepository = ref.watch(groupChatRepositoryProvider);
  return MessageService(
    messageRepository: messageRepository,
    chatRepository: chatRepository,
  );
});

/// Provider for streaming messages for a specific chat.
final messagesStreamProvider = StreamProvider.family<List<Message>, String>((
  ref,
  chatId,
) {
  final service = ref.watch(messageServiceProvider);
  return service.streamMessages(chatId);
});
