import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/auth_providers.dart';
import '../../domain/exceptions/chat_exceptions.dart';
import '../../providers/group_chat_provider.dart';
import '../../providers/message_provider.dart';
import '../widgets/edit_group_chat_bottom_sheet.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input_widget.dart';

/// Screen displaying the message stream for a specific group chat.
class GroupChatDetailScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String chatName;

  const GroupChatDetailScreen({
    super.key,
    required this.chatId,
    required this.chatName,
  });

  @override
  ConsumerState<GroupChatDetailScreen> createState() =>
      _GroupChatDetailScreenState();
}

class _GroupChatDetailScreenState extends ConsumerState<GroupChatDetailScreen> {
  bool _isJoining = false;

  Future<void> _joinGroupChat() async {
    final authState = ref.read(authStateNotifierProvider);
    final user = authState.user;

    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to join a group chat'),
          ),
        );
      }
      return;
    }

    setState(() {
      _isJoining = true;
    });

    try {
      final service = ref.read(groupChatServiceProvider);
      await service.joinPublicChat(
        chatId: widget.chatId,
        userId: user.userId,
      );

      // Refresh the chat data to reflect the new membership
      ref.invalidate(groupChatByIdProvider(widget.chatId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully joined the group chat!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is ChatException ? e.message : 'Failed to join group chat',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesStreamProvider(widget.chatId));
    final chatAsync = ref.watch(groupChatByIdProvider(widget.chatId));
    final authState = ref.watch(authStateNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatName),
        actions: [
          chatAsync.when(
            data: (chat) {
              // Only show menu if user is creator
              if (authState.user?.userId == chat.creatorId) {
                return PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'edit') {
                      EditGroupChatBottomSheet.show(context, chat);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit Group'),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: chatAsync.when(
        data: (chat) {
          final currentUserId = authState.user?.userId;
          final isMember =
              currentUserId != null && chat.memberIds.contains(currentUserId);

          return Column(
            children: [
              // Messages list (reverse chronological)
              Expanded(
                child: messagesAsync.when(
                  data: (messages) {
                    if (messages.isEmpty) {
                      return const Center(
                        child: Text(
                          'No messages yet.\nBe the first to send a message!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                      );
                    }

                    return ListView.builder(
                      reverse: true, // Show newest messages at the bottom
                      padding: const EdgeInsets.all(8.0),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        return MessageBubble(
                          message: message,
                          chatId: widget.chatId,
                          chatCreatorId: chat.creatorId,
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load messages',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Join button or message input
              if (!isMember && chat.isPublic)
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isJoining ? null : _joinGroupChat,
                      icon: _isJoining
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.group_add),
                      label: Text(
                        _isJoining ? 'Joining...' : 'Join Group Chat',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                )
              else if (!isMember && !chat.isPublic)
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'This is a private group. You must be invited to join.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                )
              else
                MessageInputWidget(chatId: widget.chatId),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load chat',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
