import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/group_chat_provider.dart';
import '../widgets/create_group_chat_bottom_sheet.dart';
import 'group_chat_detail_screen.dart';

/// Screen displaying the list of group chats for the current user.
class GroupChatsListScreen extends ConsumerStatefulWidget {
  final String userId;

  const GroupChatsListScreen({super.key, required this.userId});

  @override
  ConsumerState<GroupChatsListScreen> createState() =>
      _GroupChatsListScreenState();
}

class _GroupChatsListScreenState extends ConsumerState<GroupChatsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 60) {
      return DateFormat('h:mm a').format(timestamp);
    } else if (diff.inHours < 24 && now.day == timestamp.day) {
      return DateFormat('h:mm a').format(timestamp);
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return DateFormat('EEEE').format(timestamp);
    } else {
      return '${diff.inDays} days ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupChatsAsync = ref.watch(userGroupChatsProvider(widget.userId));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        elevation: 0,
        title: const Text('Chats', style: TextStyle(color: Colors.black)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(userGroupChatsProvider(widget.userId));
                await ref.read(userGroupChatsProvider(widget.userId).future);
              },
              child: groupChatsAsync.when(
                data: (groupChats) {
                  final filteredChats = _searchQuery.isEmpty
                      ? groupChats
                      : groupChats.where((chat) {
                          final nameLower = chat.name.toLowerCase();
                          final descLower =
                              chat.description?.toLowerCase() ?? '';
                          final lastMsgLower =
                              chat.lastMessage?.toLowerCase() ?? '';
                          return nameLower.contains(_searchQuery) ||
                              descLower.contains(_searchQuery) ||
                              lastMsgLower.contains(_searchQuery);
                        }).toList();

                  final unreadCount = filteredChats
                      .where((c) => c.unreadCount > 0)
                      .length;

                  if (filteredChats.isEmpty) {
                    return Center(
                      child: Text(
                        _searchQuery.isEmpty
                            ? 'No group chats yet.\nJoin or create a group to start chatting!'
                            : 'No conversations match "$_searchQuery"',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'RECENT CONVERSATIONS',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                                letterSpacing: 0.5,
                              ),
                            ),
                            if (unreadCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.teal[300],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$unreadCount New',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemCount: filteredChats.length,
                          itemBuilder: (context, index) {
                            final chat = filteredChats[index];
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                leading: Stack(
                                  children: [
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: Colors.teal[700],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: chat.avatarUrl != null
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Image.network(
                                                chat.avatarUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stack,
                                                    ) => Center(
                                                      child: Text(
                                                        chat.name.isNotEmpty
                                                            ? chat.name[0]
                                                                  .toUpperCase()
                                                            : '?',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 20,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                              ),
                                            )
                                          : Center(
                                              child: Text(
                                                chat.name.isNotEmpty
                                                    ? chat.name[0].toUpperCase()
                                                    : '?',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                    ),
                                    if (chat.isPublic)
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          width: 16,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        chat.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatTimestamp(chat.lastMessageTime),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          chat.lastMessage != null &&
                                                  chat.lastMessageSender != null
                                              ? '${chat.lastMessageSender}: ${chat.lastMessage}'
                                              : chat.description ??
                                                    '${chat.memberIds.length} members',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (chat.unreadCount > 0) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: const BoxDecoration(
                                            color: Colors.teal,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            chat.unreadCount > 9
                                                ? '9+'
                                                : '${chat.unreadCount}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          GroupChatDetailScreen(
                                            chatId: chat.id,
                                            chatName: chat.name,
                                          ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
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
                        'Failed to load chats',
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          CreateGroupChatBottomSheet.show(context);
        },
        backgroundColor: Colors.teal[700],
        icon: const Icon(Icons.group_add, color: Colors.white),
        label: const Text('New Group', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
