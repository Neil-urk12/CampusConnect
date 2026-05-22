import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../attachments/domain/attachment_types.dart';
import '../../../../attachments/providers/attachment_providers.dart';
import '../../../../providers/auth_providers.dart';
import '../../providers/group_chat_provider.dart';

/// Bottom sheet for creating a new group chat.
class CreateGroupChatBottomSheet extends ConsumerStatefulWidget {
  const CreateGroupChatBottomSheet({super.key});

  /// Shows the create group chat bottom sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const CreateGroupChatBottomSheet(),
    );
  }

  @override
  ConsumerState<CreateGroupChatBottomSheet> createState() =>
      _CreateGroupChatBottomSheetState();
}

class _CreateGroupChatBottomSheetState
    extends ConsumerState<CreateGroupChatBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();
  bool _isPublic = true;
  bool _isLoading = false;
  File? _selectedImage;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  Future<String?> _uploadAvatar() async {
    if (_selectedImage == null) return null;

    try {
      final attachmentService = ref.read(attachmentServiceProvider);
      final file = File(_selectedImage!.path);
      final draft = await attachmentService.prepareImage(
        owner: AttachmentOwnerRef(
          type: AttachmentOwnerType.group,
          ownerId: 'group_${DateTime.now().microsecondsSinceEpoch}',
        ),
        image: AttachmentInput.image(
          bytes: await file.readAsBytes(),
          fileName: _selectedImage!.path.split('/').last,
          mimeType: 'image/jpeg',
          sizeBytes: await file.length(),
        ),
      );
      final avatarUrl = draft.metadata.url;

      return avatarUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to upload avatar: $e')));
      }
      return null;
    }
  }

  Future<void> _createGroupChat() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authState = ref.read(authStateNotifierProvider);
    if (authState.user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to create a group chat'),
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload avatar if selected
      String? avatarUrl;
      if (_selectedImage != null) {
        avatarUrl = await _uploadAvatar();
      }

      final repository = ref.read(groupChatRepositoryProvider);
      await repository.createGroupChat(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        memberIds: [authState.user!.userId],
        creatorId: authState.user!.userId,
        isPublic: _isPublic,
        avatarUrl: avatarUrl,
      );

      if (mounted) {
        ref.invalidate(userGroupChatsProvider(authState.user!.userId));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group chat created successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create group chat: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.group_add, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Create Group Chat',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: _isLoading ? null : _pickImage,
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(16),
                          image: _selectedImage != null
                              ? DecorationImage(
                                  image: FileImage(_selectedImage!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _selectedImage == null
                            ? Icon(
                                Icons.add_photo_alternate,
                                size: 40,
                                color: Colors.grey[600],
                              )
                            : null,
                      ),
                      if (_selectedImage != null)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImage = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Tap to add group picture',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  hintText: 'Enter group name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.group),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a group name';
                  }
                  if (value.trim().length < 3) {
                    return 'Group name must be at least 3 characters';
                  }
                  return null;
                },
                enabled: !_isLoading,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Enter group description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Public Group'),
                subtitle: Text(
                  _isPublic
                      ? 'Anyone can discover and join this group'
                      : 'Only invited members can join',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                value: _isPublic,
                onChanged: _isLoading
                    ? null
                    : (value) {
                        setState(() => _isPublic = value);
                      },
                secondary: Icon(_isPublic ? Icons.public : Icons.lock),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _createGroupChat,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: Text(_isLoading ? 'Creating...' : 'Create Group Chat'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
