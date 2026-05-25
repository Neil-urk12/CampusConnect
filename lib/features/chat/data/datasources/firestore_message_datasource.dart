import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/datasources/message_datasource.dart';
import '../../domain/entities/message.dart';
import '../extensions/chat_firestore_extensions.dart';

/// Firestore data source for message operations.
class FirestoreMessageDataSource implements MessageDataSource {
  final FirebaseFirestore _firestore;

  FirestoreMessageDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Streams messages for a specific chat in real-time.
  @override
  Stream<List<Message>> streamMessages(String chatId, {int limit = 50}) {
    try {
      return _firestore
          .collection('groupChats')
          .doc(chatId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => doc.toMessage(chatId))
                .toList(),
          );
    } catch (e) {
      throw Exception('Failed to stream messages: $e');
    }
  }

  /// Sends a new message to a chat.
  @override
  Future<Message> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String content,
    String? attachmentUrl,
  }) async {
    try {
      final now = DateTime.now();
      final message = Message(
        id: '',  // will be set after add
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        content: content,
        attachmentUrl: attachmentUrl,
        isDeleted: false,
        createdAt: now,
      );
      final docRef = await _firestore
          .collection('groupChats')
          .doc(chatId)
          .collection('messages')
          .add(message.toFirestoreMap());

      final doc = await docRef.get();
      return doc.toMessage(chatId);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Soft-deletes a message (sets isDeleted to true).
  @override
  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      await _firestore
          .collection('groupChats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({'isDeleted': true});
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }
}
