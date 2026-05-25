import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/datasources/group_chat_datasource.dart';
import '../../domain/entities/group_chat.dart';
import '../extensions/chat_firestore_extensions.dart';

/// Firestore data source for group chat operations.
class FirestoreGroupChatDataSource implements GroupChatDataSource {
  final FirebaseFirestore _firestore;

  FirestoreGroupChatDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Fetches all group chats where the user is a member, plus public chats.
  @override
  Future<List<GroupChat>> getUserChats(String userId) async {
    try {
      // 1. Chats where user is a member
      final memberQuery = await _firestore
          .collection('groupChats')
          .where('memberIds', arrayContains: userId)
          .orderBy('createdAt', descending: true)
          .get();

      // 2. Public chats (isPublic == true) that the user may not have joined yet
      final publicQuery = await _firestore
          .collection('groupChats')
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      // Merge, deduplicate by doc id, sort by createdAt descending
      final seenIds = <String>{};
      final results = <GroupChat>[];

      for (final doc in publicQuery.docs) {
        seenIds.add(doc.id);
        results.add(doc.toGroupChat());
      }
      for (final doc in memberQuery.docs) {
        if (seenIds.add(doc.id)) {
          results.add(doc.toGroupChat());
        }
      }

      results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return results;
    } catch (e) {
      throw Exception('Failed to fetch user chats: $e');
    }
  }

  /// Creates a new group chat.
  @override
  Future<GroupChat> createGroupChat({
    required String name,
    String? description,
    required List<String> memberIds,
    required String creatorId,
    required bool isPublic,
    String? avatarUrl,
  }) async {
    try {
      final now = DateTime.now();
      final docRef = await _firestore.collection('groupChats').add({
        'name': name,
        'description': description,
        'memberIds': memberIds,
        'creatorId': creatorId,
        'isPublic': isPublic,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'avatarUrl': avatarUrl,
      });

      final doc = await docRef.get();
      return doc.toGroupChat();
    } catch (e) {
      throw Exception('Failed to create group chat: $e');
    }
  }

  /// Fetches a single group chat by ID.
  @override
  Future<GroupChat> getGroupChatById(String chatId) async {
    try {
      final doc = await _firestore.collection('groupChats').doc(chatId).get();

      if (!doc.exists) {
        throw Exception('Group chat not found');
      }

      return doc.toGroupChat();
    } catch (e) {
      throw Exception('Failed to fetch group chat: $e');
    }
  }

  /// Adds members to an existing group chat.
  @override
  Future<void> addMembers(String chatId, List<String> memberIds) async {
    try {
      // For public chats, read the document first to build the full memberIds array
      // This ensures security rules can validate the update properly
      final chatDoc = await _firestore
          .collection('groupChats')
          .doc(chatId)
          .get();

      if (!chatDoc.exists) {
        throw Exception('Group chat not found');
      }

      final currentMemberIds = List<String>.from(
        chatDoc.data()?['memberIds'] ?? [],
      );
      final newMemberIds = {...currentMemberIds, ...memberIds}.toList();

      await _firestore.collection('groupChats').doc(chatId).update({
        'memberIds': newMemberIds,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to add members: $e');
    }
  }

  /// Adds members to a group chat and syncs with UserModel.groupMemberships using batch write.
  @override
  Future<void> addMembersWithSync(String chatId, List<String> memberIds) async {
    try {
      final batch = _firestore.batch();

      // Update the GroupChat document
      final chatRef = _firestore.collection('groupChats').doc(chatId);
      batch.update(chatRef, {
        'memberIds': FieldValue.arrayUnion(memberIds),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Update each user's groupMemberships
      for (final userId in memberIds) {
        final userRef = _firestore.collection('users').doc(userId);
        batch.update(userRef, {
          'groupMemberships': FieldValue.arrayUnion([chatId]),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to add members with sync: $e');
    }
  }

  /// Updates group chat details (name, description, avatarUrl).
  @override
  Future<void> updateGroupChat({
    required String chatId,
    String? name,
    String? description,
    String? avatarUrl,
  }) async {
    try {
      final Map<String, dynamic> updates = {
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;

      await _firestore.collection('groupChats').doc(chatId).update(updates);
    } catch (e) {
      throw Exception('Failed to update group chat: $e');
    }
  }
}
