import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/message_service.dart';
import '../data/datasources/firestore_message_datasource.dart';
import '../domain/datasources/message_datasource.dart';
import '../domain/entities/message.dart';
import 'group_chat_provider.dart';

/// Provider for FirestoreMessageDataSource.
final messageDataSourceProvider = Provider<MessageDataSource>((ref) {
  return FirestoreMessageDataSource();
});


/// Provider for MessageService.
final messageServiceProvider = Provider<MessageService>((ref) {
  final messageDataSource = ref.watch(messageDataSourceProvider);
  final chatDataSource = ref.watch(groupChatDataSourceProvider);
  return MessageService(
    messageDataSource: messageDataSource,
    chatDataSource: chatDataSource,
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
