import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group_chat_model.dart';

/// Firestore data source for group chat operations.
class FirestoreGroupChatDataSource {
  final FirebaseFirestore _firestore;

  FirestoreGroupChatDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Fetches all group chats where the user is a member.
  Future<List<GroupChatModel>> getUserChats(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('groupChats')
          .where('memberIds', arrayContains: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => GroupChatModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user chats: $e');
    }
  }

  /// Creates a new group chat.
  Future<GroupChatModel> createGroupChat({
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
      return GroupChatModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to create group chat: $e');
    }
  }

  /// Fetches a single group chat by ID.
  Future<GroupChatModel> getGroupChatById(String chatId) async {
    try {
      final doc = await _firestore.collection('groupChats').doc(chatId).get();

      if (!doc.exists) {
        throw Exception('Group chat not found');
      }

      return GroupChatModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to fetch group chat: $e');
    }
  }

  /// Adds members to an existing group chat.
  Future<void> addMembers(String chatId, List<String> memberIds) async {
    try {
      await _firestore.collection('groupChats').doc(chatId).update({
        'memberIds': FieldValue.arrayUnion(memberIds),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to add members: $e');
    }
  }

  /// Adds members to a group chat and syncs with UserModel.groupMemberships using batch write.
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
