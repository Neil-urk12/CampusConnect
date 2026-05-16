import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/announcement_form_provider.dart';
import '../../../../core/theme/design_tokens.dart';

/// Widget for selecting target audience roles
class AudienceSelector extends ConsumerWidget {
  const AudienceSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(announcementFormProvider);
    final formNotifier = ref.read(announcementFormProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target Audience *',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Select who should see this announcement',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: DesignTokens.secondaryContainer,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: DesignTokens.secondary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: DesignTokens.secondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Note: Administrators and moderators always see all announcements',
                  style: TextStyle(
                    fontSize: 11,
                    color: DesignTokens.onSecondaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Student checkbox
        CheckboxListTile(
          title: const Text('Students'),
          subtitle: const Text('All students will see this announcement'),
          value: formState.targetAudience.contains('student'),
          onChanged: (value) {
            formNotifier.toggleAudience('student');
          },
          contentPadding: EdgeInsets.zero,
        ),

        // Faculty checkbox
        CheckboxListTile(
          title: const Text('Faculty'),
          subtitle: const Text(
            'All faculty members will see this announcement',
          ),
          value: formState.targetAudience.contains('faculty'),
          onChanged: (value) {
            formNotifier.toggleAudience('faculty');
          },
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}
