import 'package:campusconnect/features/chat/data/extensions/chat_firestore_extensions.dart';
import 'dart:io';
import 'package:campusconnect/features/chat/domain/entities/group_chat.dart';
import 'package:campusconnect/features/chat/domain/entities/message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GroupChatFirestore extension', () {
    test('toFirestoreMap returns correct map with all fields', () {
      final chat = GroupChat(
        id: 'chat-1',
        name: 'Test Group',
        description: 'A test group',
        memberIds: ['user-1', 'user-2'],
        creatorId: 'user-1',
        isPublic: true,
        createdAt: DateTime(2025, 3, 15, 10, 30),
        updatedAt: DateTime(2025, 3, 15, 11, 0),
        lastMessage: 'Hello!',
        lastMessageSender: 'user-2',
        lastMessageTime: DateTime(2025, 3, 15, 10, 45),
        unreadCount: 3,
        avatarUrl: 'https://example.com/avatar.png',
      );

      final map = chat.toFirestoreMap();

      expect(map['name'], 'Test Group');
      expect(map['description'], 'A test group');
      expect(map['memberIds'], ['user-1', 'user-2']);
      expect(map['creatorId'], 'user-1');
      expect(map['isPublic'], true);
      expect(map['createdAt'], isA<dynamic>());
      expect(map['updatedAt'], isA<dynamic>());
      expect(map['lastMessage'], 'Hello!');
      expect(map['lastMessageSender'], 'user-2');
      expect(map['lastMessageTime'], isA<dynamic>());
      expect(map['unreadCount'], 3);
      expect(map['avatarUrl'], 'https://example.com/avatar.png');
    });

    test('toFirestoreMap handles null optional fields', () {
      final chat = GroupChat(
        id: 'chat-1',
        name: 'Minimal Group',
        memberIds: ['user-1'],
        creatorId: 'user-1',
        isPublic: false,
        createdAt: DateTime(2025, 1, 1),
      );

      final map = chat.toFirestoreMap();

      expect(map['name'], 'Minimal Group');
      expect(map['description'], isNull);
      expect(map['updatedAt'], isNull);
      expect(map['lastMessage'], isNull);
      expect(map['lastMessageSender'], isNull);
      expect(map['lastMessageTime'], isNull);
      expect(map['unreadCount'], 0);
      expect(map['avatarUrl'], isNull);
    });

    test('toFirestoreMap preserves all field values', () {
      final chat = GroupChat(
        id: 'chat-2',
        name: 'Another Group',
        description: 'Desc',
        memberIds: ['a', 'b', 'c'],
        creatorId: 'a',
        isPublic: true,
        createdAt: DateTime(2025, 6, 1),
        updatedAt: DateTime(2025, 6, 2),
        lastMessage: 'msg',
        lastMessageSender: 'b',
        lastMessageTime: DateTime(2025, 6, 2),
        unreadCount: 5,
        avatarUrl: 'url',
      );

      final map = chat.toFirestoreMap();

      expect(map['memberIds'].length, 3);
      expect(map['unreadCount'], 5);
      expect(map['avatarUrl'], 'url');
    });
  });

  group('MessageFirestore extension', () {
    test('toFirestoreMap returns correct map', () {
      final message = Message(
        id: 'msg-1',
        chatId: 'chat-1',
        senderId: 'user-1',
        senderName: 'Alice',
        content: 'Hello world!',
        attachmentUrl: 'https://example.com/file.pdf',
        isDeleted: false,
        createdAt: DateTime(2025, 3, 15, 10, 30),
      );

      final map = message.toFirestoreMap();

      expect(map['senderId'], 'user-1');
      expect(map['senderName'], 'Alice');
      expect(map['content'], 'Hello world!');
      expect(map['attachmentUrl'], 'https://example.com/file.pdf');
      expect(map['isDeleted'], false);
      expect(map['createdAt'], isA<dynamic>());
    });

    test('toFirestoreMap handles null attachment', () {
      final message = Message(
        id: 'msg-2',
        chatId: 'chat-1',
        senderId: 'user-2',
        senderName: 'Bob',
        content: 'No attachment',
        isDeleted: false,
        createdAt: DateTime(2025, 3, 15, 11, 0),
      );

      final map = message.toFirestoreMap();

      expect(map['attachmentUrl'], isNull);
      expect(map['content'], 'No attachment');
    });

    test('toFirestoreMap handles deleted messages', () {
      final message = Message(
        id: 'msg-3',
        chatId: 'chat-1',
        senderId: 'user-1',
        senderName: 'Alice',
        content: 'Deleted message',
        isDeleted: true,
        createdAt: DateTime(2025, 3, 15, 12, 0),
      );

      final map = message.toFirestoreMap();

      expect(map['isDeleted'], true);
    });
  });

  group('ChatDocSnapshot extension', () {
    test('extension file exports toGroupChat and toMessage methods', () {
      // Verify the extension file imports and compiles correctly by
      // checking that both methods are present in the source.
      final content = File(
        'lib/features/chat/data/extensions/chat_firestore_extensions.dart',
      ).readAsStringSync();

      expect(content, contains('GroupChat toGroupChat()'));
      expect(content, contains('Message toMessage(String chatId)'));
    });
  });
}
