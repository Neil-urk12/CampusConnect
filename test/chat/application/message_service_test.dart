import 'dart:async';

import 'package:campusconnect/features/chat/application/message_service.dart';
import 'package:campusconnect/features/chat/domain/entities/group_chat.dart';
import 'package:campusconnect/features/chat/domain/entities/message.dart';
import 'package:campusconnect/features/chat/domain/exceptions/chat_exceptions.dart';
import 'package:campusconnect/features/chat/domain/repositories/group_chat_repository.dart';
import 'package:campusconnect/features/chat/domain/repositories/message_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MessageService', () {
    // ---------------------------------------------------------------------------
    // sendMessage — validation
    // ---------------------------------------------------------------------------

    test('sendMessage rejects empty chatId', () async {
      final service = MessageService(
        messageRepository: _FakeMessageRepository(),
        chatRepository: _FakeGroupChatRepository(),
      );

      await expectLater(
        service.sendMessage(
          chatId: '',
          senderId: 'user-1',
          senderName: 'Alice',
          content: 'Hello',
        ),
        throwsA(
          isA<ChatException>().having((e) => e.code, 'code', ChatException.validationError).having(
            (e) => e.message,
            'message',
            'Chat ID cannot be empty',
          ),
        ),
      );
    });

    test('sendMessage rejects empty senderId', () async {
      final service = MessageService(
        messageRepository: _FakeMessageRepository(),
        chatRepository: _FakeGroupChatRepository(),
      );

      await expectLater(
        service.sendMessage(
          chatId: 'chat-1',
          senderId: '',
          senderName: 'Alice',
          content: 'Hello',
        ),
        throwsA(
          isA<ChatException>().having((e) => e.code, 'code', ChatException.validationError).having(
            (e) => e.message,
            'message',
            'Sender ID cannot be empty',
          ),
        ),
      );
    });

    test('sendMessage rejects empty content with no attachment', () async {
      final service = MessageService(
        messageRepository: _FakeMessageRepository(),
        chatRepository: _FakeGroupChatRepository(),
      );

      await expectLater(
        service.sendMessage(
          chatId: 'chat-1',
          senderId: 'user-1',
          senderName: 'Alice',
          content: '   ',
        ),
        throwsA(
          isA<ChatException>().having((e) => e.code, 'code', ChatException.validationError).having(
            (e) => e.message,
            'message',
            'Message cannot be empty',
          ),
        ),
      );
    });

    test('sendMessage rejects content over 5000 characters', () async {
      final service = MessageService(
        messageRepository: _FakeMessageRepository(),
        chatRepository: _FakeGroupChatRepository(),
      );

      await expectLater(
        service.sendMessage(
          chatId: 'chat-1',
          senderId: 'user-1',
          senderName: 'Alice',
          content: 'a' * 5001,
        ),
        throwsA(
          isA<ChatException>().having((e) => e.code, 'code', ChatException.validationError).having(
            (e) => e.message,
            'message',
            'Message must be 5000 characters or less',
          ),
        ),
      );
    });

    // ---------------------------------------------------------------------------
    // sendMessage — permission (non-member)
    // ---------------------------------------------------------------------------

    test(
      'sendMessage throws permission error for non-member sender',
      () async {
        final service = MessageService(
          messageRepository: _FakeMessageRepository(),
          chatRepository: _FakeGroupChatRepository(
            chatMemberIds: ['other-user'],
          ),
        );

        await expectLater(
          service.sendMessage(
            chatId: 'chat-1',
            senderId: 'user-1',
            senderName: 'Alice',
            content: 'Hello',
          ),
          throwsA(
            isA<ChatException>().having((e) => e.code, 'code', ChatException.permissionDenied).having(
              (e) => e.message,
              'message',
              'You must be a member to send messages',
            ),
          ),
        );
      },
    );

    // ---------------------------------------------------------------------------
    // sendMessage — error wrapping
    // ---------------------------------------------------------------------------

    test('sendMessage wraps repository exceptions as network error',
        () async {
      final service = MessageService(
        messageRepository: _FakeMessageRepository(
          sendMessageError: Exception('Firestore down'),
        ),
        chatRepository: _FakeGroupChatRepository(
          chatMemberIds: ['user-1'],
        ),
      );

      await expectLater(
        service.sendMessage(
          chatId: 'chat-1',
          senderId: 'user-1',
          senderName: 'Alice',
          content: 'Hello',
        ),
        throwsA(isA<ChatException>().having((e) => e.code, 'code', ChatException.networkError)),
      );
    });

    // ---------------------------------------------------------------------------
    // sendMessage — happy path
    // ---------------------------------------------------------------------------

    test('sendMessage returns Message on success', () async {
      final service = MessageService(
        messageRepository: _FakeMessageRepository(),
        chatRepository: _FakeGroupChatRepository(chatMemberIds: ['user-1']),
      );

      final message = await service.sendMessage(
        chatId: 'chat-1',
        senderId: 'user-1',
        senderName: 'Alice',
        content: 'Hello world',
      );

      expect(message.id, 'msg-new');
      expect(message.chatId, 'chat-1');
      expect(message.senderId, 'user-1');
      expect(message.content, 'Hello world');
    });

    test('sendMessage accepts empty content when attachmentUrl is provided',
        () async {
      final service = MessageService(
        messageRepository: _FakeMessageRepository(),
        chatRepository: _FakeGroupChatRepository(chatMemberIds: ['user-1']),
      );

      final message = await service.sendMessage(
        chatId: 'chat-1',
        senderId: 'user-1',
        senderName: 'Alice',
        content: '   ',
        attachmentUrl: 'https://example.com/image.jpg',
      );

      expect(message.id, 'msg-new');
    });


    // ---------------------------------------------------------------------------
    // deleteMessage — permission (non-admin, non-creator, non-sender)
    // ---------------------------------------------------------------------------

    test(
      'deleteMessage throws permission error when user is not admin, '
      'creator, or sender',
      () async {
        final service = MessageService(
          messageRepository: _FakeMessageRepository(),
          chatRepository: _FakeGroupChatRepository(),
        );

        await expectLater(
          service.deleteMessage(
            chatId: 'chat-1',
            messageId: 'msg-1',
            currentUserId: 'user-99',
            currentUserRole: 'member',
            messageSenderId: 'sender-1',
            chatCreatorId: 'creator-1',
          ),
          throwsA(
            isA<ChatException>().having((e) => e.code, 'code', ChatException.permissionDenied).having(
              (e) => e.message,
              'message',
              'You do not have permission to delete this message',
            ),
          ),
        );
      },
    );

    test('deleteMessage succeeds for admin', () async {
      final repo = _FakeMessageRepository();
      final service = MessageService(
        messageRepository: repo,
        chatRepository: _FakeGroupChatRepository(),
      );

      await service.deleteMessage(
        chatId: 'chat-1',
        messageId: 'msg-1',
        currentUserId: 'admin-1',
        currentUserRole: 'admin',
        messageSenderId: 'sender-1',
        chatCreatorId: 'creator-1',
      );

      expect(repo.deletedChatId, 'chat-1');
      expect(repo.deletedMessageId, 'msg-1');
    });

    test('deleteMessage succeeds for message sender (self-delete)', () async {
      final repo = _FakeMessageRepository();
      final service = MessageService(
        messageRepository: repo,
        chatRepository: _FakeGroupChatRepository(),
      );

      await service.deleteMessage(
        chatId: 'chat-1',
        messageId: 'msg-1',
        currentUserId: 'sender-1',
        currentUserRole: 'member',
        messageSenderId: 'sender-1',
        chatCreatorId: 'creator-1',
      );

      expect(repo.deletedMessageId, 'msg-1');
    });

    // ---------------------------------------------------------------------------
    // deleteMessage — validation
    // ---------------------------------------------------------------------------

    test('deleteMessage rejects empty chatId', () async {
      final service = MessageService(
        messageRepository: _FakeMessageRepository(),
        chatRepository: _FakeGroupChatRepository(),
      );

      await expectLater(
        service.deleteMessage(
          chatId: '',
          messageId: 'msg-1',
          currentUserId: 'admin-1',
          currentUserRole: 'admin',
          messageSenderId: 'sender-1',
          chatCreatorId: 'creator-1',
        ),
        throwsA(
          isA<ChatException>().having((e) => e.code, 'code', ChatException.validationError).having(
            (e) => e.message,
            'message',
            'Chat ID cannot be empty',
          ),
        ),
      );
    });

    test('deleteMessage rejects empty messageId', () async {
      final service = MessageService(
        messageRepository: _FakeMessageRepository(),
        chatRepository: _FakeGroupChatRepository(),
      );

      await expectLater(
        service.deleteMessage(
          chatId: 'chat-1',
          messageId: '',
          currentUserId: 'admin-1',
          currentUserRole: 'admin',
          messageSenderId: 'sender-1',
          chatCreatorId: 'creator-1',
        ),
        throwsA(
          isA<ChatException>().having((e) => e.code, 'code', ChatException.validationError).having(
            (e) => e.message,
            'message',
            'Message ID cannot be empty',
          ),
        ),
      );
    });


    // ---------------------------------------------------------------------------
    // deleteMessage — error wrapping
    // ---------------------------------------------------------------------------

    test('deleteMessage wraps repository exceptions as network error',
        () async {
      final service = MessageService(
        messageRepository: _FakeMessageRepository(
          deleteMessageError: Exception('Firestore down'),
        ),
        chatRepository: _FakeGroupChatRepository(),
      );

      await expectLater(
        service.deleteMessage(
          chatId: 'chat-1',
          messageId: 'msg-1',
          currentUserId: 'admin-1',
          currentUserRole: 'admin',
          messageSenderId: 'sender-1',
          chatCreatorId: 'creator-1',
        ),
        throwsA(isA<ChatException>().having((e) => e.code, 'code', ChatException.networkError)),
      );
    });

    // ---------------------------------------------------------------------------
    // canModerateMessage
    // ---------------------------------------------------------------------------

    test('canModerateMessage returns true for admin role', () {
      final service = MessageService(
        messageRepository: _FakeMessageRepository(),
        chatRepository: _FakeGroupChatRepository(),
      );

      expect(
        service.canModerateMessage(
          currentUserId: 'admin-1',
          currentUserRole: 'admin',
          messageSenderId: 'sender-1',
          chatCreatorId: 'creator-1',
        ),
        isTrue,
      );
    });

    test('canModerateMessage returns true for chat creator with org_leader role',
        () {
      final service = MessageService(
        messageRepository: _FakeMessageRepository(),
        chatRepository: _FakeGroupChatRepository(),
      );

      expect(
        service.canModerateMessage(
          currentUserId: 'creator-1',
          currentUserRole: 'organization_leader',
          messageSenderId: 'sender-1',
          chatCreatorId: 'creator-1',
        ),
        isTrue,
      );
    });

    test('canModerateMessage returns true for message sender (self-delete)',
        () {
      final service = MessageService(
        messageRepository: _FakeMessageRepository(),
        chatRepository: _FakeGroupChatRepository(),
      );

      expect(
        service.canModerateMessage(
          currentUserId: 'sender-1',
          currentUserRole: 'member',
          messageSenderId: 'sender-1',
          chatCreatorId: 'creator-1',
        ),
        isTrue,
      );
    });

    test(
      'canModerateMessage returns false for unrelated user with member role',
      () {
        final service = MessageService(
          messageRepository: _FakeMessageRepository(),
          chatRepository: _FakeGroupChatRepository(),
        );

        expect(
          service.canModerateMessage(
            currentUserId: 'user-99',
            currentUserRole: 'member',
            messageSenderId: 'sender-1',
            chatCreatorId: 'creator-1',
          ),
          isFalse,
        );
      },
    );

    // ---------------------------------------------------------------------------
    // streamMessages — validation
    // ---------------------------------------------------------------------------

    test('streamMessages returns Stream.error for empty chatId', () async {
      final service = MessageService(
        messageRepository: _FakeMessageRepository(),
        chatRepository: _FakeGroupChatRepository(),
      );

      await expectLater(
        service.streamMessages(''),
        emitsError(isA<ChatException>().having((e) => e.code, 'code', ChatException.validationError)),
      );
    });

    test('streamMessages delegates to repository for valid chatId', () async {
      final repo = _FakeMessageRepository();
      final service = MessageService(
        messageRepository: repo,
        chatRepository: _FakeGroupChatRepository(),
      );

      // Just verify it doesn't throw and delegates correctly
      service.streamMessages('chat-1');
      expect(repo.streamMessagesChatId, 'chat-1');
    });
  });
}

// =============================================================================
// Fakes
// =============================================================================

class _FakeMessageRepository implements MessageRepository {
  final Exception? sendMessageError;
  final Exception? deleteMessageError;

  // Track calls
  String? lastSendMessageChatId;
  String? lastSendMessageSenderId;
  String? lastSendMessageContent;
  String? deletedChatId;
  String? deletedMessageId;
  String? streamMessagesChatId;

  _FakeMessageRepository({
    this.sendMessageError,
    this.deleteMessageError,
  });

  @override
  Stream<List<Message>> streamMessages(String chatId, {int limit = 50}) {
    streamMessagesChatId = chatId;
    return const Stream.empty();
  }

  @override
  Future<Message> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String content,
    String? attachmentUrl,
  }) async {
    if (sendMessageError != null) throw sendMessageError!;
    lastSendMessageChatId = chatId;
    lastSendMessageSenderId = senderId;
    lastSendMessageContent = content;

    return Message(
      id: 'msg-new',
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      content: content,
      attachmentUrl: attachmentUrl,
      isDeleted: false,
      createdAt: DateTime(2025, 1, 1),
    );
  }

  @override
  Future<void> deleteMessage(String chatId, String messageId) async {
    if (deleteMessageError != null) throw deleteMessageError!;
    deletedChatId = chatId;
    deletedMessageId = messageId;
  }
}

class _FakeGroupChatRepository implements GroupChatRepository {
  final List<String> chatMemberIds;
  final String chatCreatorId;

  _FakeGroupChatRepository({
    this.chatMemberIds = const ['user-1'],
    this.chatCreatorId = 'creator-1',
  });

  @override
  Future<GroupChat> getGroupChatById(String chatId) async {
    return GroupChat(
      id: chatId,
      name: 'Test Chat',
      memberIds: chatMemberIds,
      creatorId: chatCreatorId,
      isPublic: true,
      createdAt: DateTime(2025, 1, 1),
    );
  }

  @override
  Future<List<GroupChat>> getUserChats(String userId) =>
      throw UnimplementedError();

  @override
  Future<GroupChat> createGroupChat({
    required String name,
    String? description,
    required List<String> memberIds,
    required String creatorId,
    required bool isPublic,
    String? avatarUrl,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> addMembers(String chatId, List<String> memberIds) =>
      throw UnimplementedError();

  @override
  Future<void> addMembersWithSync(String chatId, List<String> memberIds) =>
      throw UnimplementedError();

  @override
  Future<void> updateGroupChat({
    required String chatId,
    String? name,
    String? description,
    String? avatarUrl,
  }) =>
      throw UnimplementedError();
}
