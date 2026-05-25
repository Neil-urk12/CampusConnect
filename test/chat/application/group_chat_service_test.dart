import 'package:campusconnect/features/chat/application/group_chat_service.dart';
import 'package:campusconnect/features/chat/domain/entities/group_chat.dart';
import 'package:campusconnect/features/chat/domain/exceptions/chat_exceptions.dart';
import 'package:campusconnect/features/chat/domain/datasources/group_chat_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GroupChatService', () {
    late _FakeGroupChatDataSource dataSource;
    late GroupChatService service;

    setUp(() {
      dataSource = _FakeGroupChatDataSource();
      service = GroupChatService(dataSource: dataSource);
    });

    // --- getUserChats ---

    group('getUserChats', () {
      test('throws validation error when userId is empty', () async {
        await expectLater(
          service.getUserChats(''),
          throwsA(
            isA<ChatException>().having((e) => e.code, 'code', ChatException.validationError).having(
              (e) => e.message,
              'message',
              'User ID cannot be empty',
            ),
          ),
        );
      });

      test('returns chats from repository', () async {
        dataSource.seedChat(_makeChat(id: 'chat-1', creatorId: 'user-1', memberIds: ['user-1']));

        final chats = await service.getUserChats('user-1');

        expect(chats, hasLength(1));
        expect(chats.first.id, 'chat-1');
      });

      test('wraps non-ChatException as network error', () async {
        dataSource.getUserChatsError = Exception('firestore down');

        await expectLater(
          service.getUserChats('user-1'),
          throwsA(
            isA<ChatException>().having((e) => e.code, 'code', ChatException.networkError)
                .having((e) => e.message, 'message', 'Failed to fetch chats')
                .having(
                  (e) => e.originalError,
                  'originalError',
                  isA<Exception>(),
                ),
          ),
        );
      });
    });

    // --- getGroupChatById ---

    group('getGroupChatById', () {
      test('throws validation error when chatId is empty', () async {
        await expectLater(
          service.getGroupChatById(''),
          throwsA(
            isA<ChatException>().having((e) => e.code, 'code', ChatException.validationError).having(
              (e) => e.message,
              'message',
              'Chat ID cannot be empty',
            ),
          ),
        );
      });

      test('returns chat from repository', () async {
        dataSource.seedChat(_makeChat(id: 'chat-1', creatorId: 'user-1'));

        final chat = await service.getGroupChatById('chat-1');

        expect(chat.id, 'chat-1');
      });

      test('wraps non-ChatException as network error', () async {
        dataSource.getGroupChatByIdError = Exception('timeout');

        await expectLater(
          service.getGroupChatById('chat-1'),
          throwsA(
            isA<ChatException>().having((e) => e.code, 'code', ChatException.networkError).having(
              (e) => e.message,
              'message',
              'Failed to fetch group chat',
            ),
          ),
        );
      });
    });

    // --- createGroupChat ---

    group('createGroupChat', () {
      test('throws validation error when name is empty', () async {
        await expectLater(
          service.createGroupChat(
            name: '',
            memberIds: ['user-1'],
            creatorId: 'user-1',
            isPublic: true,
          ),
          throwsA(
            isA<ChatException>().having((e) => e.code, 'code', ChatException.validationError).having(
              (e) => e.message,
              'message',
              'Group name cannot be empty',
            ),
          ),
        );
      });

      test('throws when name is whitespace only', () async {
        await expectLater(
          service.createGroupChat(
            name: '   ',
            memberIds: ['user-1'],
            creatorId: 'user-1',
            isPublic: true,
          ),
          throwsA(isA<ChatException>().having((e) => e.code, 'code', ChatException.validationError)),
        );
      });

      test('throws when name is less than 3 characters', () async {
        await expectLater(
          service.createGroupChat(
            name: 'ab',
            memberIds: ['user-1'],
            creatorId: 'user-1',
            isPublic: true,
          ),
          throwsA(
            isA<ChatException>().having((e) => e.code, 'code', ChatException.validationError).having(
              (e) => e.message,
              'message',
              'Group name must be at least 3 characters',
            ),
          ),
        );
      });

      test('throws when name exceeds 100 characters', () async {
        final longName = 'a' * 101;

        await expectLater(
          service.createGroupChat(
            name: longName,
            memberIds: ['user-1'],
            creatorId: 'user-1',
            isPublic: true,
          ),
          throwsA(
            isA<ChatException>().having((e) => e.code, 'code', ChatException.validationError).having(
              (e) => e.message,
              'message',
              'Group name must be 100 characters or less',
            ),
          ),
        );
      });

      test('throws validation error when creatorId is empty', () async {
        await expectLater(
          service.createGroupChat(
            name: 'Test Group',
            memberIds: ['user-1'],
            creatorId: '',
            isPublic: true,
          ),
          throwsA(
            isA<ChatException>().having((e) => e.code, 'code', ChatException.validationError).having(
              (e) => e.message,
              'message',
              'Creator ID cannot be empty',
            ),
          ),
        );
      });

      test('auto-adds creator to memberIds if missing', () async {
        await service.createGroupChat(
          name: 'Test Group',
          memberIds: ['user-2', 'user-3'],
          creatorId: 'user-1',
          isPublic: true,
        );

        expect(
          dataSource.lastCreateMemberIds,
          containsAll(['user-1', 'user-2', 'user-3']),
        );
      });

      test('does not duplicate creatorId if already in memberIds', () async {
        await service.createGroupChat(
          name: 'Test Group',
          memberIds: ['user-1', 'user-2'],
          creatorId: 'user-1',
          isPublic: true,
        );

        expect(
          dataSource.lastCreateMemberIds!.where((id) => id == 'user-1').length,
          1,
        );
      });

      test('passes all params to repository on success', () async {
        await service.createGroupChat(
          name: 'My Group',
          description: 'A desc',
          memberIds: ['user-1'],
          creatorId: 'user-1',
          isPublic: false,
          avatarUrl: 'https://img.png',
        );

        expect(dataSource.lastCreateName, 'My Group');
        expect(dataSource.lastCreateDescription, 'A desc');
        expect(dataSource.lastCreateIsPublic, false);
        expect(dataSource.lastCreateAvatarUrl, 'https://img.png');
      });

      test('wraps non-ChatException as network error', () async {
        dataSource.createGroupChatError = Exception('write failed');

        await expectLater(
          service.createGroupChat(
            name: 'Valid Name',
            memberIds: ['user-1'],
            creatorId: 'user-1',
            isPublic: true,
          ),
          throwsA(
            isA<ChatException>().having((e) => e.code, 'code', ChatException.networkError).having(
              (e) => e.message,
              'message',
              'Failed to create group chat',
            ),
          ),
        );
      });

      test('trims whitespace from name before passing to repository', () async {
        await service.createGroupChat(
          name: '  My Group  ',
          memberIds: ['user-1'],
          creatorId: 'user-1',
          isPublic: true,
        );

        expect(dataSource.lastCreateName, 'My Group');
      });

      test('accepts name with exactly 3 characters', () async {
        await service.createGroupChat(
          name: 'abc',
          memberIds: ['user-1'],
          creatorId: 'user-1',
          isPublic: true,
        );

        expect(dataSource.lastCreateName, 'abc');
      });

      test('accepts name with exactly 100 characters', () async {
        final name100 = 'a' * 100;
        await service.createGroupChat(
          name: name100,
          memberIds: ['user-1'],
          creatorId: 'user-1',
          isPublic: true,
        );

        expect(dataSource.lastCreateName, name100);
      });
    });

    // --- updateGroupChat ---

    group('updateGroupChat', () {
      test('throws validation error when chatId is empty', () async {
        await expectLater(
          service.updateGroupChat(
            chatId: '',
            currentUserId: 'user-1',
            currentUserRole: 'admin',
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

      test('validates name if provided', () async {
        dataSource.seedChat(
          _makeChat(id: 'chat-1', creatorId: 'user-1', memberIds: ['user-1']),
        );

        await expectLater(
          service.updateGroupChat(
            chatId: 'chat-1',
            currentUserId: 'user-1',
            currentUserRole: 'member',
            name: 'ab',
          ),
          throwsA(
            isA<ChatException>().having((e) => e.code, 'code', ChatException.validationError).having(
              (e) => e.message,
              'message',
              'Group name must be at least 3 characters',
            ),
          ),
        );
      });

      test('allows creator to update', () async {
        dataSource.seedChat(
          _makeChat(id: 'chat-1', creatorId: 'user-1', memberIds: ['user-1']),
        );

        await service.updateGroupChat(
          chatId: 'chat-1',
          currentUserId: 'user-1',
          currentUserRole: 'member',
          name: 'New Name',
        );

        expect(dataSource.lastUpdateChatId, 'chat-1');
        expect(dataSource.lastUpdateName, 'New Name');
      });

      test('allows admin to update', () async {
        dataSource.seedChat(
          _makeChat(id: 'chat-1', creatorId: 'user-1', memberIds: ['user-1']),
        );

        await service.updateGroupChat(
          chatId: 'chat-1',
          currentUserId: 'user-2',
          currentUserRole: 'admin',
          description: 'Updated desc',
        );

        expect(dataSource.lastUpdateDescription, 'Updated desc');
      });

      test(
        'throws permission error for non-admin non-creator',
        () async {
          dataSource.seedChat(
            _makeChat(
              id: 'chat-1',
              creatorId: 'user-1',
              memberIds: ['user-1', 'user-2'],
            ),
          );

          await expectLater(
            service.updateGroupChat(
              chatId: 'chat-1',
              currentUserId: 'user-2',
              currentUserRole: 'member',
              name: 'Hacked Name',
            ),
            throwsA(
              isA<ChatException>().having((e) => e.code, 'code', ChatException.permissionDenied).having(
                (e) => e.message,
                'message',
                'Only the chat creator or an admin can perform this action',
              ),
            ),
          );

          expect(dataSource.updateGroupChatCalled, false);
        },
      );

      test('wraps non-ChatException as network error', () async {
        dataSource.seedChat(
          _makeChat(id: 'chat-1', creatorId: 'user-1', memberIds: ['user-1']),
        );
        dataSource.updateGroupChatError = Exception('write failed');

        await expectLater(
          service.updateGroupChat(
            chatId: 'chat-1',
            currentUserId: 'user-1',
            currentUserRole: 'member',
          ),
          throwsA(
            isA<ChatException>().having((e) => e.code, 'code', ChatException.networkError).having(
              (e) => e.message,
              'message',
              'Failed to update group chat',
            ),
          ),
        );
      });

      test('trims whitespace from name before passing to repository', () async {
        dataSource.seedChat(
          _makeChat(id: 'chat-1', creatorId: 'user-1', memberIds: ['user-1']),
        );

        await service.updateGroupChat(
          chatId: 'chat-1',
          currentUserId: 'user-1',
          currentUserRole: 'member',
          name: '  Updated Name  ',
        );

        expect(dataSource.lastUpdateName, 'Updated Name');
      });
    });

    // --- addMembers ---

    group('addMembers', () {
      test('throws validation error when chatId is empty', () async {
        await expectLater(
          service.addMembers(
            chatId: '',
            memberIds: ['user-2'],
            currentUserId: 'user-1',
            currentUserRole: 'admin',
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

      test('throws validation error when memberIds is empty', () async {
        await expectLater(
          service.addMembers(
            chatId: 'chat-1',
            memberIds: [],
            currentUserId: 'user-1',
            currentUserRole: 'admin',
          ),
          throwsA(
            isA<ChatException>().having((e) => e.code, 'code', ChatException.validationError).having(
              (e) => e.message,
              'message',
              'Member list cannot be empty',
            ),
          ),
        );
      });

      test('throws permission error for non-admin non-creator', () async {
        dataSource.seedChat(
          _makeChat(id: 'chat-1', creatorId: 'user-1', memberIds: ['user-1']),
        );

        await expectLater(
          service.addMembers(
            chatId: 'chat-1',
            memberIds: ['user-3'],
            currentUserId: 'user-2',
            currentUserRole: 'member',
          ),
          throwsA(isA<ChatException>().having((e) => e.code, 'code', ChatException.permissionDenied)),
        );
      });

      test('filters out existing members before calling repository', () async {
        dataSource.seedChat(
          _makeChat(
            id: 'chat-1',
            creatorId: 'user-1',
            memberIds: ['user-1', 'user-2'],
          ),
        );

        await service.addMembers(
          chatId: 'chat-1',
          memberIds: ['user-2', 'user-3', 'user-4'],
          currentUserId: 'user-1',
          currentUserRole: 'member',
        );

        expect(dataSource.lastAddMembersIds, ['user-3', 'user-4']);
      });

      test('skips repository call when all members already exist', () async {
        dataSource.seedChat(
          _makeChat(
            id: 'chat-1',
            creatorId: 'user-1',
            memberIds: ['user-1', 'user-2'],
          ),
        );

        await service.addMembers(
          chatId: 'chat-1',
          memberIds: ['user-2'],
          currentUserId: 'user-1',
          currentUserRole: 'member',
        );

        expect(dataSource.addMembersCalled, false);
      });

      test('wraps non-ChatException as network error', () async {
        dataSource.seedChat(
          _makeChat(id: 'chat-1', creatorId: 'user-1', memberIds: ['user-1']),
        );
        dataSource.addMembersError = Exception('batch failed');

        await expectLater(
          service.addMembers(
            chatId: 'chat-1',
            memberIds: ['user-2'],
            currentUserId: 'user-1',
            currentUserRole: 'member',
          ),
          throwsA(
            isA<ChatException>().having((e) => e.code, 'code', ChatException.networkError).having(
              (e) => e.message,
              'message',
              'Failed to add members',
            ),
          ),
        );
      });
    });

    // --- addMembersWithSync ---

    group('addMembersWithSync', () {
      test('throws validation error when chatId is empty', () async {
        await expectLater(
          service.addMembersWithSync(
            chatId: '',
            memberIds: ['user-2'],
            currentUserId: 'user-1',
            currentUserRole: 'admin',
          ),
          throwsA(isA<ChatException>().having((e) => e.code, 'code', ChatException.validationError)),
        );
      });

      test('throws validation error when memberIds is empty', () async {
        await expectLater(
          service.addMembersWithSync(
            chatId: 'chat-1',
            memberIds: [],
            currentUserId: 'user-1',
            currentUserRole: 'admin',
          ),
          throwsA(isA<ChatException>().having((e) => e.code, 'code', ChatException.validationError)),
        );
      });

      test('filters existing members and delegates to sync method', () async {
        dataSource.seedChat(
          _makeChat(
            id: 'chat-1',
            creatorId: 'user-1',
            memberIds: ['user-1'],
          ),
        );

        await service.addMembersWithSync(
          chatId: 'chat-1',
          memberIds: ['user-1', 'user-2'],
          currentUserId: 'user-1',
          currentUserRole: 'member',
        );

        expect(dataSource.lastAddMembersWithSyncIds, ['user-2']);
      });

      test('wraps non-ChatException as network error', () async {
        dataSource.seedChat(
          _makeChat(id: 'chat-1', creatorId: 'user-1', memberIds: ['user-1']),
        );
        dataSource.addMembersWithSyncError = Exception('sync failed');

        await expectLater(
          service.addMembersWithSync(
            chatId: 'chat-1',
            memberIds: ['user-2'],
            currentUserId: 'user-1',
            currentUserRole: 'member',
          ),
          throwsA(
            isA<ChatException>().having((e) => e.code, 'code', ChatException.networkError).having(
              (e) => e.message,
              'message',
              'Failed to add members with sync',
            ),
          ),
        );
      });

      test('throws permission error for non-admin non-creator', () async {
        dataSource.seedChat(
          _makeChat(id: 'chat-1', creatorId: 'user-1', memberIds: ['user-1']),
        );

        await expectLater(
          service.addMembersWithSync(
            chatId: 'chat-1',
            memberIds: ['user-3'],
            currentUserId: 'user-2',
            currentUserRole: 'member',
          ),
          throwsA(isA<ChatException>().having((e) => e.code, 'code', ChatException.permissionDenied)),
        );
      });
    });

    // --- joinPublicChat ---

    group('joinPublicChat', () {
      test('throws validation error when chatId is empty', () async {
        await expectLater(
          service.joinPublicChat(chatId: '', userId: 'user-1'),
          throwsA(
            isA<ChatException>().having((e) => e.code, 'code', ChatException.validationError).having(
              (e) => e.message,
              'message',
              'Chat ID cannot be empty',
            ),
          ),
        );
      });

      test('throws validation error when userId is empty', () async {
        await expectLater(
          service.joinPublicChat(chatId: 'chat-1', userId: ''),
          throwsA(
            isA<ChatException>().having((e) => e.code, 'code', ChatException.validationError).having(
              (e) => e.message,
              'message',
              'User ID cannot be empty',
            ),
          ),
        );
      });

      test('throws permission error for private chat', () async {
        dataSource.seedChat(
          _makeChat(
            id: 'chat-1',
            isPublic: false,
            creatorId: 'user-1',
            memberIds: ['user-1'],
          ),
        );

        await expectLater(
          service.joinPublicChat(chatId: 'chat-1', userId: 'user-2'),
          throwsA(
            isA<ChatException>().having((e) => e.code, 'code', ChatException.permissionDenied).having(
              (e) => e.message,
              'message',
              'Cannot join a private chat without an invitation',
            ),
          ),
        );
      });

      test('skips call when user is already a member', () async {
        dataSource.seedChat(
          _makeChat(
            id: 'chat-1',
            isPublic: true,
            creatorId: 'user-1',
            memberIds: ['user-1', 'user-2'],
          ),
        );

        await service.joinPublicChat(chatId: 'chat-1', userId: 'user-2');

        expect(dataSource.addMembersWithSyncCalled, false);
      });

      test('calls addMembersWithSync for new member on public chat', () async {
        dataSource.seedChat(
          _makeChat(
            id: 'chat-1',
            isPublic: true,
            creatorId: 'user-1',
            memberIds: ['user-1'],
          ),
        );

        await service.joinPublicChat(chatId: 'chat-1', userId: 'user-2');

        expect(dataSource.addMembersWithSyncCalled, true);
        expect(
          dataSource.lastAddMembersWithSyncIds,
          contains('user-2'),
        );
      });

      test('wraps non-ChatException as network error', () async {
        dataSource.getGroupChatByIdError = Exception('network down');

        await expectLater(
          service.joinPublicChat(chatId: 'chat-1', userId: 'user-1'),
          throwsA(
            isA<ChatException>().having((e) => e.code, 'code', ChatException.networkError).having(
              (e) => e.message,
              'message',
              'Failed to join chat',
            ),
          ),
        );
      });
    });

    // --- canEditChat ---

    group('canEditChat', () {
      test('returns true for admin regardless of creator', () {
        final result = service.canEditChat(
          currentUserId: 'user-2',
          currentUserRole: 'admin',
          creatorId: 'user-1',
        );

        expect(result, true);
      });

      test('returns true for creator regardless of role', () {
        final result = service.canEditChat(
          currentUserId: 'user-1',
          currentUserRole: 'member',
          creatorId: 'user-1',
        );

        expect(result, true);
      });

      test('returns false for non-admin non-creator', () {
        final result = service.canEditChat(
          currentUserId: 'user-3',
          currentUserRole: 'member',
          creatorId: 'user-1',
        );

        expect(result, false);
      });
    });

    // --- error wrapping ---

    group('error wrapping', () {
      test('rethrows ChatException subclasses without wrapping', () async {
        dataSource.getUserChatsError = const ChatException(
          code: ChatException.chatNotFound,
          message: 'gone',
        );

        await expectLater(
          service.getUserChats('user-1'),
          throwsA(isA<ChatException>().having((e) => e.code, 'code', ChatException.chatNotFound)),
        );
      });

      test('rethrows validation error without wrapping', () async {
        dataSource.getUserChatsError = const ChatException(
          code: ChatException.validationError,
          message: 'bad data',
        );

        await expectLater(
          service.getUserChats('user-1'),
          throwsA(isA<ChatException>().having((e) => e.code, 'code', ChatException.validationError)),
        );
      });
    });
  });
}

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

GroupChat _makeChat({
  required String id,
  String name = 'Test Chat',
  String? description,
  List<String> memberIds = const ['user-1'],
  String creatorId = 'user-1',
  bool isPublic = true,
  DateTime? createdAt,
  String? avatarUrl,
}) {
  return GroupChat(
    id: id,
    name: name,
    description: description,
    memberIds: List<String>.from(memberIds),
    creatorId: creatorId,
    isPublic: isPublic,
    createdAt: createdAt ?? DateTime(2025, 1, 1),
    avatarUrl: avatarUrl,
  );
}

class _FakeGroupChatDataSource implements GroupChatDataSource {
  final Map<String, GroupChat> _store = {};

  // Injectable errors
  Exception? getUserChatsError;
  Exception? getGroupChatByIdError;
  Exception? createGroupChatError;
  Exception? updateGroupChatError;
  Exception? addMembersError;
  Exception? addMembersWithSyncError;

  // Call tracking
  String? lastAddMembersChatId;
  List<String>? lastAddMembersIds;
  bool addMembersCalled = false;

  String? lastAddMembersWithSyncChatId;
  List<String>? lastAddMembersWithSyncIds;
  bool addMembersWithSyncCalled = false;

  String? lastCreateName;
  String? lastCreateDescription;
  List<String>? lastCreateMemberIds;
  String? lastCreateCreatorId;
  bool? lastCreateIsPublic;
  String? lastCreateAvatarUrl;

  String? lastUpdateChatId;
  String? lastUpdateName;
  String? lastUpdateDescription;
  String? lastUpdateAvatarUrl;
  bool updateGroupChatCalled = false;

  void seedChat(GroupChat chat) {
    _store[chat.id] = chat;
  }

  @override
  Future<List<GroupChat>> getUserChats(String userId) async {
    if (getUserChatsError != null) throw getUserChatsError!;
    return _store.values
        .where((chat) => chat.memberIds.contains(userId))
        .toList();
  }

  @override
  Future<GroupChat> getGroupChatById(String chatId) async {
    if (getGroupChatByIdError != null) throw getGroupChatByIdError!;
    final chat = _store[chatId];
    if (chat == null) {
      throw ChatException(code: ChatException.chatNotFound, message: 'Chat $chatId not found');
    }
    return chat;
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
    if (createGroupChatError != null) throw createGroupChatError!;

    lastCreateName = name;
    lastCreateDescription = description;
    lastCreateMemberIds = List<String>.from(memberIds);
    lastCreateCreatorId = creatorId;
    lastCreateIsPublic = isPublic;
    lastCreateAvatarUrl = avatarUrl;

    final chat = GroupChat(
      id: 'chat-${_store.length + 1}',
      name: name,
      description: description,
      memberIds: List<String>.from(memberIds),
      creatorId: creatorId,
      isPublic: isPublic,
      createdAt: DateTime(2025, 1, 1),
      avatarUrl: avatarUrl,
    );
    _store[chat.id] = chat;
    return chat;
  }

  @override
  Future<void> updateGroupChat({
    required String chatId,
    String? name,
    String? description,
    String? avatarUrl,
  }) async {
    if (updateGroupChatError != null) throw updateGroupChatError!;

    updateGroupChatCalled = true;
    lastUpdateChatId = chatId;
    lastUpdateName = name;
    lastUpdateDescription = description;
    lastUpdateAvatarUrl = avatarUrl;
  }

  @override
  Future<void> addMembers(String chatId, List<String> memberIds) async {
    if (addMembersError != null) throw addMembersError!;

    addMembersCalled = true;
    lastAddMembersChatId = chatId;
    lastAddMembersIds = List<String>.from(memberIds);

    final chat = _store[chatId];
    if (chat != null) {
      _store[chatId] = GroupChat(
        id: chat.id,
        name: chat.name,
        description: chat.description,
        memberIds: [...chat.memberIds, ...memberIds],
        creatorId: chat.creatorId,
        isPublic: chat.isPublic,
        createdAt: chat.createdAt,
        updatedAt: chat.updatedAt,
        lastMessage: chat.lastMessage,
        lastMessageSender: chat.lastMessageSender,
        lastMessageTime: chat.lastMessageTime,
        unreadCount: chat.unreadCount,
        avatarUrl: chat.avatarUrl,
      );
    }
  }

  @override
  Future<void> addMembersWithSync(
    String chatId,
    List<String> memberIds,
  ) async {
    if (addMembersWithSyncError != null) throw addMembersWithSyncError!;

    addMembersWithSyncCalled = true;
    lastAddMembersWithSyncChatId = chatId;
    lastAddMembersWithSyncIds = List<String>.from(memberIds);

    final chat = _store[chatId];
    if (chat != null) {
      _store[chatId] = GroupChat(
        id: chat.id,
        name: chat.name,
        description: chat.description,
        memberIds: [...chat.memberIds, ...memberIds],
        creatorId: chat.creatorId,
        isPublic: chat.isPublic,
        createdAt: chat.createdAt,
        updatedAt: chat.updatedAt,
        lastMessage: chat.lastMessage,
        lastMessageSender: chat.lastMessageSender,
        lastMessageTime: chat.lastMessageTime,
        unreadCount: chat.unreadCount,
        avatarUrl: chat.avatarUrl,
      );
    }
  }
}
