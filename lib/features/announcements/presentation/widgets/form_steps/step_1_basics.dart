import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/announcement_form_provider.dart';

/// Step 1: Basics - Title, Body, Urgent, Pinned
class Step1Basics extends ConsumerStatefulWidget {
  const Step1Basics({super.key});

  @override
  ConsumerState<Step1Basics> createState() => _Step1BasicsState();
}

class _Step1BasicsState extends ConsumerState<Step1Basics> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final formState = ref.read(announcementFormProvider);
      _titleController.text = formState.title;
      _bodyController.text = formState.body;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(announcementFormProvider);
    final formNotifier = ref.read(announcementFormProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title field
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Title *',
              hintText: 'Enter announcement title',
              border: const OutlineInputBorder(),
              errorText: formState.title.isEmpty && formState.currentStep > 0
                  ? 'Title is required'
                  : null,
            ),
            maxLength: 100,
            onChanged: formNotifier.updateTitle,
          ),
          const SizedBox(height: 16),

          // Body field
          TextField(
            controller: _bodyController,
            decoration: InputDecoration(
              labelText: 'Body *',
              hintText: 'Enter announcement content',
              border: const OutlineInputBorder(),
              helperText: '${formState.body.length}/500 characters',
              errorText: formState.body.isEmpty && formState.currentStep > 0
                  ? 'Body is required'
                  : formState.body.length > 500
                  ? 'Body cannot exceed 500 characters'
                  : null,
            ),
            maxLines: 6,
            maxLength: 500,
            onChanged: formNotifier.updateBody,
          ),
          const SizedBox(height: 24),

          // Urgent checkbox
          CheckboxListTile(
            title: const Text('Mark as Urgent'),
            subtitle: const Text('Displays with warning styling'),
            value: formState.isUrgent,
            onChanged: (value) {
              if (value != null) {
                formNotifier.updateIsUrgent(value);
              }
            },
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),

          // Pinned checkbox
          CheckboxListTile(
            title: const Text('Pin to Top'),
            subtitle: const Text('Keeps announcement at the top of the list'),
            value: formState.isPinned,
            onChanged: (value) {
              if (value != null) {
                formNotifier.updateIsPinned(value);
              }
            },
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
