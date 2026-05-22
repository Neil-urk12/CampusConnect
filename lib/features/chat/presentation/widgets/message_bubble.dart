import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../providers/auth_providers.dart';
import '../../domain/entities/message.dart';
import '../../providers/message_provider.dart';

/// Widget displaying a single message bubble.
class MessageBubble extends ConsumerWidget {
  final Message message;
  final String chatId;
  final String chatCreatorId;

  const MessageBubble({
    super.key,
    required this.message,
    required this.chatId,
    required this.chatCreatorId,
  });

  bool _canModerate(
    String? currentUserId,
    String? currentUserRole,
    String chatCreatorId,
  ) {
    if (currentUserId == null || currentUserRole == null) return false;

    // Admins can always moderate
    if (currentUserRole == 'admin') return true;

    // Chat creator with organization_leader or admin role can moderate
    if (currentUserId == chatCreatorId &&
        (currentUserRole == 'organization_leader' ||
            currentUserRole == 'admin')) {
      return true;
    }

    return false;
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text(
          'Are you sure you want to delete this message? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final messageRepository = ref.read(messageRepositoryProvider);
        await messageRepository.deleteMessage(chatId, message.id);

        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Message deleted')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete message: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateNotifierProvider);
    final currentUser = authState.user;
    final isOwnMessage = currentUser?.userId == message.senderId;

    // Check moderation permissions using passed chatCreatorId
    final canModerate = _canModerate(
      currentUser?.userId,
      currentUser?.role,
      chatCreatorId,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: isOwnMessage
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isOwnMessage) ...[
            CircleAvatar(
              radius: 16,
              child: Text(
                message.senderName.isNotEmpty
                    ? message.senderName[0].toUpperCase()
                    : '?',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isOwnMessage
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isOwnMessage)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 2.0),
                    child: Text(
                      message.senderName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                GestureDetector(
                  onLongPress: () {
                    // Show delete confirmation if user can moderate
                    if (!message.isDeleted && canModerate) {
                      _showDeleteConfirmation(context, ref);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 8.0,
                    ),
                    decoration: BoxDecoration(
                      color: message.isDeleted
                          ? Colors.grey[300]
                          : isOwnMessage
                          ? Theme.of(context).primaryColor
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image preview
                        if (message.attachmentUrl != null &&
                            message.attachmentUrl!.isNotEmpty &&
                            !message.isDeleted)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                message.attachmentUrl!,
                                width: 200,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        width: 200,
                                        height: 150,
                                        color: Colors.grey[300],
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 200,
                                    height: 150,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.broken_image),
                                  );
                                },
                              ),
                            ),
                          ),
                        // Message content
                        Text(
                          message.isDeleted
                              ? 'Message deleted'
                              : message.content,
                          style: TextStyle(
                            color: message.isDeleted
                                ? Colors.grey[600]
                                : isOwnMessage
                                ? Colors.white
                                : Colors.black87,
                            fontStyle: message.isDeleted
                                ? FontStyle.italic
                                : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Timestamp
                        Text(
                          DateFormat('HH:mm').format(message.createdAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: message.isDeleted
                                ? Colors.grey[600]
                                : isOwnMessage
                                ? Colors.white70
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isOwnMessage) const SizedBox(width: 8),
        ],
      ),
    );
  }
}
