import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/announcement_form_provider.dart';
import '../image_picker_field.dart';
import '../../../../../core/theme/design_tokens.dart';

/// Step 3: Extras - Tags, Image Upload, and Conditional CTA
class Step3Extras extends ConsumerStatefulWidget {
  const Step3Extras({super.key});

  @override
  ConsumerState<Step3Extras> createState() => _Step3ExtrasState();
}

class _Step3ExtrasState extends ConsumerState<Step3Extras> {
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _ctaLabelController = TextEditingController();
  final TextEditingController _ctaUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final formState = ref.read(announcementFormProvider);
      _tagsController.text = formState.tags.join(', ');
      _ctaLabelController.text = formState.ctaLabel ?? '';
      _ctaUrlController.text = formState.ctaUrl ?? '';
    });
  }

  @override
  void dispose() {
    _tagsController.dispose();
    _ctaLabelController.dispose();
    _ctaUrlController.dispose();
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
          // Tags field
          TextField(
            controller: _tagsController,
            decoration: const InputDecoration(
              labelText: 'Tags (optional)',
              hintText: 'Enter tags separated by commas',
              helperText: 'e.g., important, deadline, registration',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              final tags = value
                  .split(',')
                  .map((tag) => tag.trim())
                  .where((tag) => tag.isNotEmpty)
                  .toList();
              formNotifier.updateTags(tags);
            },
          ),
          const SizedBox(height: 24),

          // Image upload
          const ImagePickerField(),
          const SizedBox(height: 24),

          // Conditional CTA fields (only if pinned)
          if (formState.isPinned) ...[
            Text(
              'Call-to-Action',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add a button to your pinned announcement',
              style: TextStyle(color: DesignTokens.onSurfaceVariant, fontSize: 12),
            ),
            const SizedBox(height: 16),

            // CTA Label
            TextField(
              controller: _ctaLabelController,
              decoration: const InputDecoration(
                labelText: 'Button Label',
                hintText: 'e.g., View Details, Register Now',
                border: OutlineInputBorder(),
              ),
              onChanged: formNotifier.updateCtaLabel,
            ),
            const SizedBox(height: 16),

            // CTA URL
            TextField(
              controller: _ctaUrlController,
              decoration: const InputDecoration(
                labelText: 'Button URL',
                hintText: 'https://example.com',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
              onChanged: formNotifier.updateCtaUrl,
            ),
            const SizedBox(height: 8),

            // CTA validation message
            if (formState.currentStep > 2) ...[
              if ((formState.ctaLabel?.isNotEmpty ?? false) !=
                  (formState.ctaUrl?.isNotEmpty ?? false))
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Both CTA label and URL are required',
                    style: TextStyle(color: DesignTokens.error, fontSize: 12),
                  ),
                ),
              if (formState.ctaUrl?.isNotEmpty ?? false)
                if (!formState.ctaUrl!.startsWith('http://') &&
                    !formState.ctaUrl!.startsWith('https://'))
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      'URL must start with http:// or https://',
                      style: TextStyle(color: DesignTokens.error, fontSize: 12),
                    ),
                  ),
            ],
          ],
        ],
      ),
    );
  }
}
