import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/group_chat.dart';

/// Data model for GroupChat with Firestore serialization.
class GroupChatModel extends GroupChat {
  const GroupChatModel({
    required super.id,
    required super.name,
    super.description,
    required super.memberIds,
    required super.creatorId,
    required super.isPublic,
    required super.createdAt,
    super.updatedAt,
    super.lastMessage,
    super.lastMessageSender,
    super.lastMessageTime,
    super.unreadCount = 0,
    super.avatarUrl,
  });

  /// Creates a GroupChatModel from a Firestore document snapshot.
  factory GroupChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupChatModel(
      id: doc.id,
      name: data['name'] as String,
      description: data['description'] as String?,
      memberIds: List<String>.from(data['memberIds'] as List),
      creatorId: data['creatorId'] as String,
      isPublic: data['isPublic'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      lastMessage: data['lastMessage'] as String?,
      lastMessageSender: data['lastMessageSender'] as String?,
      lastMessageTime: data['lastMessageTime'] != null
          ? (data['lastMessageTime'] as Timestamp).toDate()
          : null,
      unreadCount: data['unreadCount'] as int? ?? 0,
      avatarUrl: data['avatarUrl'] as String?,
    );
  }

  /// Converts the GroupChatModel to a Firestore-compatible map.
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'memberIds': memberIds,
      'creatorId': creatorId,
      'isPublic': isPublic,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'lastMessage': lastMessage,
      'lastMessageSender': lastMessageSender,
      'lastMessageTime': lastMessageTime != null
          ? Timestamp.fromDate(lastMessageTime!)
          : null,
      'unreadCount': unreadCount,
      'avatarUrl': avatarUrl,
    };
  }

  /// Creates a GroupChatModel from a domain entity.
  factory GroupChatModel.fromEntity(GroupChat entity) {
    return GroupChatModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      memberIds: entity.memberIds,
      creatorId: entity.creatorId,
      isPublic: entity.isPublic,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      lastMessage: entity.lastMessage,
      lastMessageSender: entity.lastMessageSender,
      lastMessageTime: entity.lastMessageTime,
      unreadCount: entity.unreadCount,
      avatarUrl: entity.avatarUrl,
    );
  }
}
