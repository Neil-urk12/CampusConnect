import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GroupChat architecture', () {
    group('GroupChatDataSource interface', () {
      test('exists in domain layer', () {
        final file = File(
          'lib/features/chat/domain/datasources/group_chat_datasource.dart',
        );
        expect(
          file.existsSync(),
          true,
          reason:
              'GroupChatDataSource must live in domain/datasources, '
              'not data/datasources',
        );
      });

      test('does NOT exist in data layer', () {
        final file = File(
          'lib/features/chat/data/datasources/group_chat_datasource.dart',
        );
        expect(
          file.existsSync(),
          false,
          reason:
              'There should be no group_chat_datasource.dart in the data layer — '
              'the abstract interface belongs in domain.',
        );
      });

      test('domain datasource file exports an abstract class', () {
        final content = File(
          'lib/features/chat/domain/datasources/group_chat_datasource.dart',
        ).readAsStringSync();

        expect(content, contains('abstract class GroupChatDataSource'));
      });

      test('domain datasource imports only domain entities, not Firestore', () {
        final content = File(
          'lib/features/chat/domain/datasources/group_chat_datasource.dart',
        ).readAsStringSync();

        expect(content, contains("import '../entities/group_chat.dart'"));
        expect(content, isNot(contains('cloud_firestore')));
        expect(content, isNot(contains('firebase')));
      });
    });

    group('Firestore serialization extracted to extensions', () {
      test('extension file exists in data layer', () {
        final file = File(
          'lib/features/chat/data/extensions/chat_firestore_extensions.dart',
        );
        expect(
          file.existsSync(),
          true,
          reason:
              'Firestore serialization logic should live in '
              'data/extensions/chat_firestore_extensions.dart',
        );
      });

      test('extension file provides toGroupChat on DocumentSnapshot', () {
        final content = File(
          'lib/features/chat/data/extensions/chat_firestore_extensions.dart',
        ).readAsStringSync();

        expect(content, contains('GroupChat toGroupChat()'));
      });

      test('extension file provides toFirestoreMap on GroupChat', () {
        final content = File(
          'lib/features/chat/data/extensions/chat_firestore_extensions.dart',
        ).readAsStringSync();

        expect(content, contains('toFirestoreMap()'));
      });
    });

    group('GroupChat domain entity is clean', () {
      test('entity does not import cloud_firestore', () {
        final content = File(
          'lib/features/chat/domain/entities/group_chat.dart',
        ).readAsStringSync();

        expect(
          content,
          isNot(contains('cloud_firestore')),
          reason:
              'Domain entities must not depend on Firestore. '
              'Serialization belongs in data/extensions.',
        );
      });

      test('entity has no fromFirestore factory', () {
        final content = File(
          'lib/features/chat/domain/entities/group_chat.dart',
        ).readAsStringSync();

        expect(content, isNot(contains('fromFirestore')));
      });

      test('entity has no toFirestore method', () {
        final content = File(
          'lib/features/chat/domain/entities/group_chat.dart',
        ).readAsStringSync();

        expect(content, isNot(contains('toFirestore')));
      });
    });

    group('Message domain entity is clean', () {
      test('entity does not import cloud_firestore', () {
        final content = File(
          'lib/features/chat/domain/entities/message.dart',
        ).readAsStringSync();

        expect(content, isNot(contains('cloud_firestore')));
      });

      test('entity has no fromFirestore factory', () {
        final content = File(
          'lib/features/chat/domain/entities/message.dart',
        ).readAsStringSync();

        expect(content, isNot(contains('fromFirestore')));
      });

      test('entity has no toFirestore method', () {
        final content = File(
          'lib/features/chat/domain/entities/message.dart',
        ).readAsStringSync();

        expect(content, isNot(contains('toFirestore')));
      });
    });

    group('FirestoreGroupChatDataSource uses domain interface', () {
      test('implements GroupChatDataSource', () {
        final content = File(
          'lib/features/chat/data/datasources/firestore_group_chat_datasource.dart',
        ).readAsStringSync();

        expect(
          content,
          contains('implements GroupChatDataSource'),
          reason:
              'Concrete datasource must implement the domain interface',
        );
      });

      test('imports domain datasource interface', () {
        final content = File(
          'lib/features/chat/data/datasources/firestore_group_chat_datasource.dart',
        ).readAsStringSync();

        expect(
          content,
          contains("import '../../domain/datasources/group_chat_datasource.dart'"),
        );
      });

      test('imports chat_firestore_extensions', () {
        final content = File(
          'lib/features/chat/data/datasources/firestore_group_chat_datasource.dart',
        ).readAsStringSync();

        expect(
          content,
          contains("import '../extensions/chat_firestore_extensions.dart'"),
        );
      });

      test('uses extension method toGroupChat() instead of model factory', () {
        final content = File(
          'lib/features/chat/data/datasources/firestore_group_chat_datasource.dart',
        ).readAsStringSync();

        expect(content, contains('.toGroupChat()'));
        expect(
          content,
          isNot(contains('GroupChatModel.fromFirestore')),
          reason:
              'Should use extension .toGroupChat() instead of '
              'GroupChatModel.fromFirestore()',
        );
      });
    });

    group('provider references domain interface', () {
      test('group_chat_provider imports domain datasource', () {
        final content = File(
          'lib/features/chat/providers/group_chat_provider.dart',
        ).readAsStringSync();

        expect(
          content,
          contains("import '../domain/datasources/group_chat_datasource.dart'"),
        );
      });
    });

    group('GroupChatService references domain layer only', () {
      test('imports domain datasource, not data datasource', () {
        final content = File(
          'lib/features/chat/application/group_chat_service.dart',
        ).readAsStringSync();

        // Should NOT import any data-layer datasource
        expect(
          content,
          isNot(contains('data/datasources/group_chat_datasource')),
        );
      });
    });
  });
}
