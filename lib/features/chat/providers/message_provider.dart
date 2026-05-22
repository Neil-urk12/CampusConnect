import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/datasources/firestore_message_datasource.dart';
import '../data/repositories/message_repository_impl.dart';
import '../domain/entities/message.dart';
import '../domain/repositories/message_repository.dart';

/// Provider for FirestoreMessageDataSource.
final messageDataSourceProvider = Provider<FirestoreMessageDataSource>((ref) {
  return FirestoreMessageDataSource();
});

/// Provider for MessageRepository.
final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  final dataSource = ref.watch(messageDataSourceProvider);
  return MessageRepositoryImpl(dataSource: dataSource);
});

/// Provider for streaming messages for a specific chat.
final messagesStreamProvider = StreamProvider.family<List<Message>, String>((
  ref,
  chatId,
) {
  final repository = ref.watch(messageRepositoryProvider);
  return repository.streamMessages(chatId);
});
