import '../domain/entities/message.dart';
import '../domain/exceptions/chat_exceptions.dart';
import '../domain/datasources/message_datasource.dart';
import '../domain/datasources/group_chat_datasource.dart';

/// Service layer for message operations.
///
/// Adds validation, permission checks, and error wrapping
/// on top of the datasource seam.
class MessageService {
  final MessageDataSource _messageDataSource;
  final GroupChatDataSource _chatDataSource;

  const MessageService({
    required MessageDataSource messageDataSource,
    required GroupChatDataSource chatDataSource,
  })  : _messageDataSource = messageDataSource,
        _chatDataSource = chatDataSource;

  /// Stream messages for a chat.
  Stream<List<Message>> streamMessages(String chatId, {int limit = 50}) {
    if (chatId.isEmpty) {
      return Stream.error(
        const ChatException(
          code: ChatException.validationError,
          message: 'Chat ID cannot be empty',
        ),
      );
    }
    return _messageDataSource.streamMessages(chatId, limit: limit);
  }

  /// Send a message to a group chat.
  ///
  /// Validates content and verifies sender is a chat member.
  Future<Message> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String content,
    String? attachmentUrl,
  }) async {
    try {
      if (chatId.isEmpty) {
        throw const ChatException(
          code: ChatException.validationError,
          message: 'Chat ID cannot be empty',
        );
      }

      if (senderId.isEmpty) {
        throw const ChatException(
          code: ChatException.validationError,
          message: 'Sender ID cannot be empty',
        );
      }

      // Must have either text content or an attachment
      if (content.trim().isEmpty && attachmentUrl == null) {
        throw const ChatException(
          code: ChatException.validationError,
          message: 'Message cannot be empty',
        );
      }

      if (content.length > 5000) {
        throw const ChatException(
          code: ChatException.validationError,
          message: 'Message must be 5000 characters or less',
        );
      }

      // Verify sender is a member of the chat
      final chat = await _chatDataSource.getGroupChatById(chatId);
      if (!chat.memberIds.contains(senderId)) {
        throw const ChatException(
          code: ChatException.permissionDenied,
          message: 'You must be a member to send messages',
        );
      }

      return await _messageDataSource.sendMessage(
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        content: content,
        attachmentUrl: attachmentUrl,
      );
    } on ChatException {
      rethrow;
    } catch (e) {
      throw ChatException(
        code: ChatException.networkError,
        message: 'Failed to send message',
        originalError: e,
      );
    }
  }

  /// Delete (soft-delete) a message.
  ///
  /// Only the message sender, an admin,
  /// or the chat creator can delete messages.
  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
    required String currentUserId,
    required String currentUserRole,
    required String messageSenderId,
    required String chatCreatorId,
  }) async {
    try {
      if (chatId.isEmpty) {
        throw const ChatException(
          code: ChatException.validationError,
          message: 'Chat ID cannot be empty',
        );
      }

      if (messageId.isEmpty) {
        throw const ChatException(
          code: ChatException.validationError,
          message: 'Message ID cannot be empty',
        );
      }

      if (!canModerateMessage(
        currentUserId: currentUserId,
        currentUserRole: currentUserRole,
        messageSenderId: messageSenderId,
        chatCreatorId: chatCreatorId,
      )) {
        throw const ChatException(
          code: ChatException.permissionDenied,
          message: 'You do not have permission to delete this message',
        );
      }

      await _messageDataSource.deleteMessage(chatId, messageId);
    } on ChatException {
      rethrow;
    } catch (e) {
      throw ChatException(
        code: ChatException.networkError,
        message: 'Failed to delete message',
        originalError: e,
      );
    }
  }

  /// Check if a user can moderate (delete) a message.
  ///
  /// Rules:
  /// - Admin can delete any message
  /// - Message sender can delete their own message (self-delete)
  /// - Chat creator with organization_leader role can delete
  bool canModerateMessage({
    required String currentUserId,
    required String currentUserRole,
    required String messageSenderId,
    required String chatCreatorId,
  }) {
    if (currentUserRole == 'admin') return true;
    // Allow message sender to delete their own message
    if (currentUserId == messageSenderId) return true;
    if (currentUserId == chatCreatorId &&
        currentUserRole == 'organization_leader') {
      return true;
    }
    return false;
  }
}
