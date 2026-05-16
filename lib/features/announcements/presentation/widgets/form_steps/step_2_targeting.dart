import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/announcement_form_provider.dart';
import '../category_dropdown.dart';
import '../audience_selector.dart';
import '../../../../../core/theme/design_tokens.dart';

/// Step 2: Targeting - Category and Target Audience
class Step2Targeting extends ConsumerWidget {
  const Step2Targeting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(announcementFormProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category dropdown
          const CategoryDropdown(),
          const SizedBox(height: 24),

          // Target audience selector
          const AudienceSelector(),
          const SizedBox(height: 16),

          // Validation messages
          if (formState.currentStep > 1) ...[
            if (formState.categoryId == null || formState.categoryId!.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  'Category is required',
                  style: TextStyle(color: DesignTokens.error, fontSize: 12),
                ),
              ),
            if (formState.targetAudience.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  'Select at least one audience',
                  style: TextStyle(color: DesignTokens.error, fontSize: 12),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
