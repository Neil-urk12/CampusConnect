import 'package:flutter/material.dart';
import '../../domain/entities/resource_entity.dart';
import '../../../../core/theme/design_tokens.dart';

/// Metadata form for resource upload with title, description, category, tags.
class UploadForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final String? initialTitle;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController tagsController;
  final ResourceCategory? selectedCategory;
  final ValueChanged<ResourceCategory?> onCategoryChanged;

  const UploadForm({
    super.key,
    required this.formKey,
    this.initialTitle,
    required this.titleController,
    required this.descriptionController,
    required this.tagsController,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  State<UploadForm> createState() => _UploadFormState();
}

class _UploadFormState extends State<UploadForm> {
  @override
  void initState() {
    super.initState();
    // Auto-populate title from filename
    if (widget.initialTitle != null && widget.titleController.text.isEmpty) {
      widget.titleController.text = widget.initialTitle!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          TextFormField(
            controller: widget.titleController,
            decoration: InputDecoration(
              labelText: 'Title *',
              hintText: 'Enter resource title',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Title is required';
              }
              return null;
            },
          ),
          const SizedBox(height: DesignTokens.spacing16),

          // Description
          TextFormField(
            controller: widget.descriptionController,
            decoration: InputDecoration(
              labelText: 'Description',
              hintText: 'Enter resource description (optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: DesignTokens.spacing16),

          // Category dropdown
          DropdownButtonFormField<ResourceCategory>(
            value: widget.selectedCategory,
            decoration: InputDecoration(
              labelText: 'Category *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: ResourceCategory.studyMaterials,
                child: Text('Study Materials'),
              ),
              DropdownMenuItem(
                value: ResourceCategory.photos,
                child: Text('Photos'),
              ),
              DropdownMenuItem(
                value: ResourceCategory.other,
                child: Text('Other'),
              ),
            ],
            onChanged: widget.onCategoryChanged,
            validator: (value) {
              if (value == null) {
                return 'Category is required';
              }
              return null;
            },
          ),
          const SizedBox(height: DesignTokens.spacing16),

          // Tags
          TextFormField(
            controller: widget.tagsController,
            decoration: InputDecoration(
              labelText: 'Tags',
              hintText: 'e.g. cs101, midterm, notes',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
              helperText: 'Separate tags with commas',
            ),
          ),
        ],
      ),
    );
  }
}
