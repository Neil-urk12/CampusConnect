import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../attachments/domain/attachment_types.dart';
import '../../../../providers/auth_providers.dart';
import '../../../../attachments/providers/attachment_providers.dart';
import '../../domain/exceptions/chat_exceptions.dart';
import '../../providers/message_provider.dart';

/// Widget for composing and sending messages with optional image attachments.
class MessageInputWidget extends ConsumerStatefulWidget {
  final String chatId;

  const MessageInputWidget({super.key, required this.chatId});

  @override
  ConsumerState<MessageInputWidget> createState() => _MessageInputWidgetState();
}

class _MessageInputWidgetState extends ConsumerState<MessageInputWidget> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // 45MB file size limit
  static const int maxFileSizeBytes = 45 * 1024 * 1024;

  XFile? _selectedImage;
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        // Validate file size
        final fileSize = await image.length();
        if (fileSize > maxFileSizeBytes) {
          if (mounted) {
            final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(1);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Image is too large ($fileSizeMB MB). Maximum size is 45 MB.',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedImage = image;
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

  void _clearImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  Future<void> _sendMessage() async {
    final content = _controller.text.trim();
    if (content.isEmpty && _selectedImage == null) return;

    final authState = ref.read(authStateNotifierProvider);
    final user = authState.user;

    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to send messages'),
          ),
        );
      }
      return;
    }

    setState(() {
      _isSending = true;
    });

    AttachmentDraft? attachmentDraft;

    try {
      String? attachmentUrl;

      if (_selectedImage != null) {
        final file = File(_selectedImage!.path);
        final fileSize = await file.length();
        if (fileSize > maxFileSizeBytes) {
          if (mounted) {
            final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(1);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Image is too large ($fileSizeMB MB). Maximum size is 45 MB.',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        final attachmentService = ref.read(attachmentServiceProvider);
        attachmentDraft = await attachmentService.prepareImage(
          owner: AttachmentOwnerRef(
            type: AttachmentOwnerType.message,
            ownerId:
                '${widget.chatId}_${DateTime.now().microsecondsSinceEpoch}',
          ),
          image: AttachmentInput.image(
            bytes: await file.readAsBytes(),
            fileName: _selectedImage!.name,
            mimeType: _selectedImage!.mimeType ?? 'image/jpeg',
            sizeBytes: fileSize,
          ),
        );
        attachmentUrl = attachmentDraft.metadata.url;
      }

      final messageService = ref.read(messageServiceProvider);
      await messageService.sendMessage(
        chatId: widget.chatId,
        senderId: user.userId,
        senderName: user.fullName,
        content: content.isNotEmpty ? content : '📷 Image',
        attachmentUrl: attachmentUrl,
      );

      _controller.clear();
      setState(() {
        _selectedImage = null;
      });
    } catch (e) {
      if (attachmentDraft != null) {
        await attachmentDraft.rollback();
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(
          content: Text(
            e is ChatException ? e.message : 'Failed to send message',
          ),
        ));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image preview
          if (_selectedImage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8.0),
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.file(
                      File(_selectedImage!.path),
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedImage!.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _clearImage,
                  ),
                ],
              ),
            ),
          // Input row
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.image),
                onPressed: _isSending ? null : _pickImage,
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  enabled: !_isSending,
                  maxLength: 5000,
                ),
              ),
              if (_isSending)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
