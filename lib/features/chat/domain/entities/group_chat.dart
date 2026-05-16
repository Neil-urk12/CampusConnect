import 'package:equatable/equatable.dart';

/// Represents a group chat entity in the domain layer.
class GroupChat extends Equatable {
  final String id;
  final String name;
  final String? description;
  final List<String> memberIds;
  final String creatorId;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? lastMessage;
  final String? lastMessageSender;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final String? avatarUrl;

  const GroupChat({
    required this.id,
    required this.name,
    this.description,
    required this.memberIds,
    required this.creatorId,
    required this.isPublic,
    required this.createdAt,
    this.updatedAt,
    this.lastMessage,
    this.lastMessageSender,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.avatarUrl,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    memberIds,
    creatorId,
    isPublic,
    createdAt,
    updatedAt,
    lastMessage,
    lastMessageSender,
    lastMessageTime,
    unreadCount,
    avatarUrl,
  ];
}
