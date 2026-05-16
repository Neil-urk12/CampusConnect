import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  Widget build(BuildContext context) {
    final groupChatsAsync = ref.watch(userGroupChatsProvider(widget.userId));

    return Scaffold(
      appBar: AppBar(title: const Text('Group Chats')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                prefixIcon: const Icon(Icons.search),
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
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
            child: groupChatsAsync.when(
              data: (groupChats) {
                final filteredChats = _searchQuery.isEmpty
                    ? groupChats
                    : groupChats.where((chat) {
                        final nameLower = chat.name.toLowerCase();
                        final descLower = chat.description?.toLowerCase() ?? '';
                        return nameLower.contains(_searchQuery) ||
                            descLower.contains(_searchQuery);
                      }).toList();

                if (filteredChats.isEmpty) {
                  return Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'No group chats yet.\nJoin or create a group to start chatting!'
                          : 'No conversations match "$_searchQuery"',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredChats.length,
                  itemBuilder: (context, index) {
                    final chat = filteredChats[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          chat.name.isNotEmpty
                              ? chat.name[0].toUpperCase()
                              : '?',
                        ),
                      ),
                      title: Text(chat.name),
                      subtitle: chat.description != null
                          ? Text(
                              chat.description!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : Text('${chat.memberIds.length} members'),
                      trailing: chat.isPublic
                          ? const Icon(Icons.public, size: 16)
                          : const Icon(Icons.lock, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GroupChatDetailScreen(
                              chatId: chat.id,
                              chatName: chat.name,
                            ),
                          ),
                        );
                      },
                    );
                  },
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
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          CreateGroupChatBottomSheet.show(context);
        },
        backgroundColor: Theme.of(context).colorScheme.secondary,
        icon: const Icon(Icons.add),
        label: const Text('New Group'),
      ),
    );
  }
}
