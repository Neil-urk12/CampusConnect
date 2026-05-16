import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/categories_provider.dart';
import '../providers/announcement_form_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/design_tokens.dart';

/// Dropdown widget for selecting announcement category
class CategoryDropdown extends ConsumerWidget {
  const CategoryDropdown({super.key});

  Future<void> _showCreateCategoryDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final formNotifier = ref.read(announcementFormProvider.notifier);
    final categoryNameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Category'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter a name for the new category:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: categoryNameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  hintText: 'e.g., Sports, Technology',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Category name is required';
                  }
                  if (value.trim().length < 2) {
                    return 'Category name must be at least 2 characters';
                  }
                  if (value.trim().length > 30) {
                    return 'Category name must be less than 30 characters';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(context).pop(true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.secondary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      final categoryName = categoryNameController.text.trim();

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Creating category...'),
                ],
              ),
            ),
          ),
        ),
      );

      try {
        // Create the category in Firestore
        final docRef = await FirebaseFirestore.instance
            .collection('categories')
            .add({
              'name': categoryName,
              'isActive': true,
              'createdAt': FieldValue.serverTimestamp(),
              'createdBy': 'admin',
            });

        // Close loading dialog
        if (context.mounted) {
          Navigator.of(context).pop();
        }

        // Update the form with the new category
        formNotifier.updateCategory(docRef.id, categoryName);

        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Category "$categoryName" created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        // Close loading dialog
        if (context.mounted) {
          Navigator.of(context).pop();
        }

        // Show error message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating category: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final formState = ref.watch(announcementFormProvider);
    final formNotifier = ref.read(announcementFormProvider.notifier);

    return categoriesAsync.when(
      data: (categories) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (categories.isEmpty)
              Card(
                color: DesignTokens.surfaceContainerHigh,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: DesignTokens.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'No categories available yet.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (categories.isNotEmpty)
              DropdownButtonFormField<String>(
                initialValue: formState.categoryId,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  hintText: 'Select a category',
                  border: OutlineInputBorder(),
                ),
                items: categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category.id,
                    child: Text(category.name),
                  );
                }).toList(),
                onChanged: (categoryId) {
                  if (categoryId != null) {
                    final category = categories.firstWhere(
                      (cat) => cat.id == categoryId,
                    );
                    formNotifier.updateCategory(categoryId, category.name);
                  }
                },
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _showCreateCategoryDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Create New Category'),
              style: OutlinedButton.styleFrom(
                foregroundColor: DesignTokens.secondary,
                side: const BorderSide(color: DesignTokens.secondary),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Card(
        color: DesignTokens.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Error loading categories: $error',
                style: TextStyle(color: DesignTokens.error),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _showCreateCategoryDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Create New Category'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DesignTokens.secondary,
                  side: const BorderSide(color: DesignTokens.secondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
