import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../domain/entities/resource_entity.dart';
import 'providers/resource_provider.dart';
import 'utils/file_type_utils.dart';
import 'widgets/upload_form.dart';
import '../../../providers/auth_providers.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/theme/design_tokens.dart';

/// Two-phase upload screen: file selection → metadata form.
class UploadResourceScreen extends ConsumerStatefulWidget {
  const UploadResourceScreen({super.key});

  @override
  ConsumerState<UploadResourceScreen> createState() =>
      _UploadResourceScreenState();
}

class _UploadResourceScreenState extends ConsumerState<UploadResourceScreen> {
  static const int _maxFileSizeBytes = 50 * 1024 * 1024; // 50 MB

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();

  File? _selectedFile;
  String? _fileName;
  String? _mimeType;
  ResourceCategory? _selectedCategory;
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  // ── File selection ────────────────────────────────────────────────

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx'],
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.path == null) return;

      final fileBytes = File(file.path!).lengthSync();
      if (fileBytes > _maxFileSizeBytes) {
        _showError('File size must be 50 MB or less');
        return;
      }

      setState(() {
        _selectedFile = File(file.path!);
        _fileName = file.name;
        _mimeType = _guessMimeType(file.name);
        _selectedCategory = ResourceCategory.studyMaterials;
      });
    } catch (e) {
      AppLogger.error('File picker error', error: e);
      _showError('Failed to pick file');
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final fileBytes = await image.length();
      if (fileBytes > _maxFileSizeBytes) {
        _showError('Image size must be 50 MB or less');
        return;
      }

      final ext = image.name.split('.').last.toLowerCase();
      final mime = 'image/$ext';

      setState(() {
        _selectedFile = File(image.path);
        _fileName = image.name;
        _mimeType = mime;
        _selectedCategory = ResourceCategory.photos;
      });
    } catch (e) {
      AppLogger.error('Image picker error', error: e);
      _showError('Failed to pick image');
    }
  }

  // ── Upload ────────────────────────────────────────────────────────

  Future<void> _upload() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null) {
      _showError('Please select a file first');
      return;
    }
    if (_selectedCategory == null) {
      _showError('Please select a category');
      return;
    }

    setState(() => _isUploading = true);

    try {
      final authState = ref.read(authStateNotifierProvider);
      final user = authState.user;
      if (user == null) {
        _showError('You must be logged in to upload');
        return;
      }

      final tags = _tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      final resource = ResourceEntity(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        fileUrl: '', // will be set by service after upload
        fileName: _fileName ?? 'unknown',
        fileSize: _selectedFile!.lengthSync(),
        mimeType: _mimeType ?? 'application/octet-stream',
        category: _selectedCategory!,
        tags: tags,
        uploadedBy: user.userId,
        uploadedByName: user.fullName,
        uploadedAt: DateTime.now(),
      );

      await ref
          .read(resourceProvider.notifier)
          .uploadResource(resource, _selectedFile!);

      if (!mounted) return;

      // Success dialog with shareable link
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle_rounded,
              color: DesignTokens.success, size: 48),
          title: const Text('Upload Successful'),
          content: const Text(
              'Your resource has been uploaded and is now available for others.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop(); // close dialog
                Navigator.of(context).pop(); // go back to list
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      AppLogger.error('Upload failed', error: e);
      _showError('Upload failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: DesignTokens.error,
      ),
    );
  }

  String _guessMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      default:
        return 'application/octet-stream';
    }
  }

  // ── UI ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hasFile = _selectedFile != null;

    return Scaffold(
      backgroundColor: DesignTokens.surface,
      appBar: AppBar(
        title: const Text('Upload Resource'),
        backgroundColor: DesignTokens.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Phase 1: File selection
            if (!hasFile) ...[
              Text(
                'Select a file to upload',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: DesignTokens.onSurface,
                ),
              ),
              const SizedBox(height: DesignTokens.spacing8),
              Text(
                'Choose study materials or photos to share with the campus.',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: DesignTokens.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: DesignTokens.spacing32),
              // Study Materials button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _pickDocument,
                  icon: const Icon(Icons.description_rounded),
                  label: const Text('Study Materials'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    side: BorderSide(color: DesignTokens.outlineVariant),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.spacing16),
              // Photos button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image_rounded),
                  label: const Text('Photos'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    side: BorderSide(color: DesignTokens.outlineVariant),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.spacing16),
              Center(
                child: Text(
                  'Max file size: 50 MB',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: DesignTokens.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],

            // Phase 2: Metadata form + upload
            if (hasFile) ...[
              // Selected file info
              Container(
                padding: const EdgeInsets.all(DesignTokens.spacing16),
                decoration: BoxDecoration(
                  color: DesignTokens.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
                child: Row(
                  children: [
                    Icon(
                      getFileIcon(_mimeType ?? ''),
                      size: 32,
                      color: DesignTokens.primaryContainer,
                    ),
                    const SizedBox(width: DesignTokens.spacing12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _fileName ?? 'Unknown file',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            formatFileSize(_selectedFile!.lengthSync()),
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: DesignTokens.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _selectedFile = null;
                          _fileName = null;
                          _mimeType = null;
                        });
                      },
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Remove file',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DesignTokens.spacing24),

              // Metadata form
              UploadForm(
                formKey: _formKey,
                initialTitle: _fileName,
                titleController: _titleController,
                descriptionController: _descriptionController,
                tagsController: _tagsController,
                selectedCategory: _selectedCategory,
                onCategoryChanged: (cat) =>
                    setState(() => _selectedCategory = cat),
              ),
              const SizedBox(height: DesignTokens.spacing24),

              // Upload button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isUploading ? null : _upload,
                  icon: _isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: DesignTokens.onPrimary,
                          ),
                        )
                      : const Icon(Icons.cloud_upload_rounded),
                  label: Text(_isUploading ? 'Uploading...' : 'Upload'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.primaryContainer,
                    foregroundColor: DesignTokens.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.spacing16),
            ],
          ],
        ),
      ),
    );
  }
}
