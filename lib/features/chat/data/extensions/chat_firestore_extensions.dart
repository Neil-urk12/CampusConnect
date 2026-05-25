import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/group_chat.dart';
import '../../domain/entities/message.dart';

/// Firestore deserialization extensions for domain entities.
extension ChatDocSnapshot on DocumentSnapshot<Map<String, dynamic>> {
  /// Converts a Firestore document snapshot to a [GroupChat] domain entity.
  GroupChat toGroupChat() {
    final data = this.data()!;
    return GroupChat(
      id: id,
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

  /// Converts a Firestore document snapshot to a [Message] domain entity.
  Message toMessage(String chatId) {
    final data = this.data()!;
    return Message(
      id: id,
      chatId: chatId,
      senderId: data['senderId'] as String,
      senderName: data['senderName'] as String,
      content: data['content'] as String,
      attachmentUrl: data['attachmentUrl'] as String?,
      isDeleted: data['isDeleted'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}

/// Firestore serialization extension for [GroupChat].
extension GroupChatFirestore on GroupChat {
  /// Converts a [GroupChat] domain entity to a Firestore-compatible map.
  Map<String, dynamic> toFirestoreMap() {
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
}

/// Firestore serialization extension for [Message].
extension MessageFirestore on Message {
  /// Converts a [Message] domain entity to a Firestore-compatible map.
  Map<String, dynamic> toFirestoreMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'attachmentUrl': attachmentUrl,
      'isDeleted': isDeleted,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
