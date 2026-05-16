import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:appwrite/appwrite.dart';
import '../../../../services/appwrite_storage_service.dart';
import '../../domain/entities/group_chat.dart';
import '../../providers/group_chat_provider.dart';

/// Bottom sheet for editing an existing group chat.
class EditGroupChatBottomSheet extends ConsumerStatefulWidget {
  final GroupChat groupChat;

  const EditGroupChatBottomSheet({super.key, required this.groupChat});

  /// Shows the edit group chat bottom sheet.
  static Future<void> show(BuildContext context, GroupChat groupChat) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => EditGroupChatBottomSheet(groupChat: groupChat),
    );
  }

  @override
  ConsumerState<EditGroupChatBottomSheet> createState() =>
      _EditGroupChatBottomSheetState();
}

class _EditGroupChatBottomSheetState
    extends ConsumerState<EditGroupChatBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  final _imagePicker = ImagePicker();
  bool _isLoading = false;
  File? _selectedImage;
  String? _currentAvatarUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.groupChat.name);
    _descriptionController = TextEditingController(
      text: widget.groupChat.description ?? '',
    );
    _currentAvatarUrl = widget.groupChat.avatarUrl;
  }

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
          // Intentionally do NOT clear _currentAvatarUrl here.
          // If the upload fails we keep the existing URL so the avatar is not
          // silently deleted.
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
      final storageService = AppwriteStorageService();
      final fileId = ID.unique();

      final avatarUrl = await storageService.uploadChatImage(
        file: InputFile.fromPath(path: _selectedImage!.path),
        fileId: fileId,
      );

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

  Future<void> _updateGroupChat() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload new avatar if a new image was picked; keep existing URL otherwise.
      String? avatarUrl = _currentAvatarUrl;
      if (_selectedImage != null) {
        final uploadedUrl = await _uploadAvatar();
        // Only swap in the new URL when the upload actually succeeded.
        if (uploadedUrl != null) {
          avatarUrl = uploadedUrl;
        }
        // On upload failure avatarUrl stays as _currentAvatarUrl — the old
        // avatar is preserved.
      }

      final service = ref.read(groupChatServiceProvider);
      await service.updateGroupChat(
        chatId: widget.groupChat.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        avatarUrl: avatarUrl,
      );

      if (mounted) {
        // Invalidate providers to refresh both detail and list views
        ref.invalidate(groupChatByIdProvider(widget.groupChat.id));

        // Invalidate list for all members
        for (final memberId in widget.groupChat.memberIds) {
          ref.invalidate(userGroupChatsProvider(memberId));
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group chat updated successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update group chat: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildAvatarPreview() {
    if (_selectedImage != null) {
      return Image.file(_selectedImage!, fit: BoxFit.cover);
    } else if (_currentAvatarUrl != null) {
      return Image.network(
        _currentAvatarUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) =>
            Icon(Icons.group, size: 40, color: Colors.grey[600]),
      );
    } else {
      return Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey[600]);
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
                  const Icon(Icons.edit, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Edit Group Chat',
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
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _buildAvatarPreview(),
                      ),
                      // Show remove button only when there is an image to remove
                      if (_selectedImage != null || _currentAvatarUrl != null)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImage = null;
                                _currentAvatarUrl = null;
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
                      // Camera overlay — shown when a new image is picked so the
                      // user can swap it without saving first. Hidden when showing
                      // only the existing URL or the empty placeholder, matching
                      // the create-sheet UX.
                      if (_selectedImage != null)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.teal[700],
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: Colors.white,
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
                  'Tap to change group picture',
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
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _updateGroupChat,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isLoading ? 'Updating...' : 'Save Changes'),
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
