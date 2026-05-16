import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../attachments/domain/attachment_types.dart';
import '../../../../attachments/providers/attachment_providers.dart';
import '../../../../core/theme/design_tokens.dart';
import '../providers/announcement_form_provider.dart';

/// Widget for picking and uploading announcement images
class ImagePickerField extends ConsumerStatefulWidget {
  const ImagePickerField({super.key});

  @override
  ConsumerState<ImagePickerField> createState() => _ImagePickerFieldState();
}

class _ImagePickerFieldState extends ConsumerState<ImagePickerField> {
  final ImagePicker _picker = ImagePicker();

  // 45MB file size limit
  static const int maxFileSizeBytes = 45 * 1024 * 1024;

  XFile? _selectedImage;
  bool _isUploading = false;
  String? _uploadError;

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        // Validate file type
        final extension = image.path.split('.').last.toLowerCase();
        if (!['png', 'jpg', 'jpeg'].contains(extension)) {
          if (mounted) {
            setState(() {
              _uploadError = 'Only PNG and JPEG images are allowed';
            });
          }
          return;
        }

        // Validate file size
        final fileSize = await image.length();
        if (fileSize > maxFileSizeBytes) {
          if (mounted) {
            final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(1);
            setState(() {
              _uploadError =
                  'Image is too large ($fileSizeMB MB). Maximum size is 45 MB.';
            });
          }
          return;
        }

        setState(() {
          _selectedImage = image;
          _uploadError = null;
        });

        // Auto-upload
        await _uploadImage();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploadError = 'Failed to pick image: $e';
        });
      }
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploading = true;
      _uploadError = null;
    });

    try {
      final file = File(_selectedImage!.path);

      // Double-check file size before upload
      final fileSize = await file.length();
      if (fileSize > maxFileSizeBytes) {
        if (mounted) {
          final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(1);
          setState(() {
            _uploadError =
                'Image is too large ($fileSizeMB MB). Maximum size is 45 MB.';
            _isUploading = false;
          });
        }
        return;
      }

      final attachmentService = ref.read(attachmentServiceProvider);
      final draft = await attachmentService.prepareImage(
        owner: AttachmentOwnerRef(
          type: AttachmentOwnerType.announcement,
          ownerId: 'announcement_${DateTime.now().microsecondsSinceEpoch}',
        ),
        image: AttachmentInput.image(
          bytes: await file.readAsBytes(),
          fileName: _selectedImage!.name,
          mimeType: _selectedImage!.mimeType ?? 'image/jpeg',
          sizeBytes: fileSize,
        ),
      );
      final attachmentUrl = draft.metadata.url;

      // Update form state with attachment URL
      ref
          .read(announcementFormProvider.notifier)
          .updateAttachmentUrl(attachmentUrl);

      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploadError = 'Failed to upload image: $e';
          _isUploading = false;
        });
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _uploadError = null;
    });
    ref.read(announcementFormProvider.notifier).removeAttachment();
  }

  Future<void> _retryUpload() async {
    await _uploadImage();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(announcementFormProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Image Attachment (optional)',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'PNG or JPEG, max 45MB',
          style: TextStyle(color: DesignTokens.onSurfaceVariant, fontSize: 12),
        ),
        const SizedBox(height: 12),

        // Show existing attachment or upload button
        if (formState.attachmentUrl != null && _selectedImage == null)
          // Existing attachment (from edit mode)
          _buildExistingAttachment(formState.attachmentUrl!)
        else if (_selectedImage != null)
          // Selected image preview
          _buildImagePreview()
        else
          // Upload button
          _buildUploadButton(),

        // Error message
        if (_uploadError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                const Icon(Icons.error, color: DesignTokens.error, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _uploadError!,
                    style: TextStyle(color: DesignTokens.error, fontSize: 12),
                  ),
                ),
                if (_selectedImage != null)
                  TextButton(
                    onPressed: _retryUpload,
                    child: const Text('Retry'),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildUploadButton() {
    return OutlinedButton.icon(
      onPressed: _isUploading ? null : _pickImage,
      icon: _isUploading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.image),
      label: Text(_isUploading ? 'Uploading...' : 'Choose Image'),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DesignTokens.outlineVariant),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.file(
              File(_selectedImage!.path),
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedImage!.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                if (_isUploading)
                  const Text(
                    'Uploading...',
                    style: TextStyle(
                      color: DesignTokens.surfaceTint,
                      fontSize: 12,
                    ),
                  )
                else
                  const Text(
                    'Upload complete',
                    style: TextStyle(color: DesignTokens.success, fontSize: 12),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _isUploading ? null : _removeImage,
          ),
        ],
      ),
    );
  }

  Widget _buildExistingAttachment(String url) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DesignTokens.outlineVariant),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              url,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 80,
                  height: 80,
                  color: DesignTokens.surfaceContainerLow,
                  child: const Icon(Icons.broken_image),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Current attachment',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(onPressed: _pickImage, child: const Text('Replace')),
          IconButton(icon: const Icon(Icons.close), onPressed: _removeImage),
        ],
      ),
    );
  }
}
