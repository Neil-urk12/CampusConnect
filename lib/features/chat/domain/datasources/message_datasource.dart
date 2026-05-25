import '../entities/message.dart';

/// Abstract data source interface for message operations.
///
/// Lives in the domain layer so application/service code can depend on
/// the interface without coupling to Firestore.
abstract class MessageDataSource {
  /// Streams messages for a specific chat in real-time.
  Stream<List<Message>> streamMessages(String chatId, {int limit = 50});

  /// Sends a new message to a chat.
  Future<Message> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String content,
    String? attachmentUrl,
  });

  /// Soft-deletes a message (sets isDeleted to true).
  Future<void> deleteMessage(String chatId, String messageId);
}
