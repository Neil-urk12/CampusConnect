import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/announcement_entity.dart';
import '../providers/announcement_form_provider.dart';
import '../widgets/form_steps/step_1_basics.dart';
import '../widgets/form_steps/step_2_targeting.dart';
import '../widgets/form_steps/step_3_extras.dart';
import '../../../../core/theme/design_tokens.dart';

/// Screen for creating or editing announcements with a 3-step stepper
class AnnouncementFormScreen extends ConsumerStatefulWidget {
  final AnnouncementEntity? announcement;
  final bool isEditMode;

  const AnnouncementFormScreen({
    super.key,
    this.announcement,
    this.isEditMode = false,
  });

  @override
  ConsumerState<AnnouncementFormScreen> createState() =>
      _AnnouncementFormScreenState();
}

class _AnnouncementFormScreenState
    extends ConsumerState<AnnouncementFormScreen> {
  bool _hasCheckedDraft = false;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isEditMode && widget.announcement != null) {
        // Initialize for edit mode
        ref
            .read(announcementFormProvider.notifier)
            .initializeForEdit(widget.announcement!);
      } else if (!widget.isEditMode) {
        // Reset form for create mode
        ref.read(announcementFormProvider.notifier).resetForm();
        _checkForDraft();
      }
    });
  }

  Future<void> _checkForDraft() async {
    if (_hasCheckedDraft) return;
    _hasCheckedDraft = true;

    final formNotifier = ref.read(announcementFormProvider.notifier);
    final draft = await formNotifier.checkForDraft();

    if (draft != null && mounted) {
      _showDraftDialog(draft);
    }
  }

  void _showDraftDialog(dynamic draft) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Continue Draft?'),
        content: const Text(
          'You have an unsaved draft. Would you like to continue where you left off?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(announcementFormProvider.notifier).clearDraft();
              Navigator.of(context).pop();
            },
            child: const Text('Start Fresh'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(announcementFormProvider.notifier).restoreDraft(draft);
              Navigator.of(context).pop();
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    // In edit mode, check for unsaved changes
    if (widget.isEditMode && _hasUnsavedChanges) {
      final shouldDiscard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard Changes?'),
          content: const Text(
            'You have unsaved changes. Are you sure you want to discard them?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Continue Editing'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.error,
              ),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
      return shouldDiscard ?? false;
    }

    return true;
  }

  void _onStepContinue() {
    final formNotifier = ref.read(announcementFormProvider.notifier);
    final formState = ref.read(announcementFormProvider);

    // Validate current step
    final error = formNotifier.validateCurrentStep();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: DesignTokens.error,
        ),
      );
      return;
    }

    // Move to next step
    if (formState.currentStep < 2) {
      formNotifier.updateCurrentStep(formState.currentStep + 1);
      _hasUnsavedChanges = true;
    }
  }

  void _onStepCancel() {
    final formNotifier = ref.read(announcementFormProvider.notifier);
    final formState = ref.read(announcementFormProvider);

    if (formState.currentStep > 0) {
      formNotifier.updateCurrentStep(formState.currentStep - 1);
    }
  }

  void _onStepTapped(int step) {
    final formNotifier = ref.read(announcementFormProvider.notifier);
    formNotifier.updateCurrentStep(step);
  }

  Future<void> _submitForm() async {
    final formNotifier = ref.read(announcementFormProvider.notifier);

    // Final validation
    final error = formNotifier.validateCurrentStep();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: DesignTokens.error,
        ),
      );
      return;
    }

    // Submit
    final success = await formNotifier.submitForm();

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditMode
                  ? 'Announcement updated successfully'
                  : 'Announcement created successfully',
            ),
            backgroundColor: DesignTokens.success,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        final errorMessage = ref.read(announcementFormProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage ?? 'Failed to submit'),
            backgroundColor: DesignTokens.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(announcementFormProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.isEditMode ? 'Edit Announcement' : 'Create Announcement',
          ),
        ),
        body: formState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Stepper(
                currentStep: formState.currentStep,
                onStepContinue: _onStepContinue,
                onStepCancel: _onStepCancel,
                onStepTapped: _onStepTapped,
                controlsBuilder: (context, details) {
                  final isLastStep = details.stepIndex == 2;
                  return Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Row(
                      children: [
                        if (isLastStep)
                          ElevatedButton(
                            onPressed: formState.isLoading ? null : _submitForm,
                            child: Text(
                              widget.isEditMode ? 'Update' : 'Create',
                            ),
                          )
                        else
                          ElevatedButton(
                            onPressed: details.onStepContinue,
                            child: const Text('Next'),
                          ),
                        const SizedBox(width: 8),
                        if (details.stepIndex > 0)
                          TextButton(
                            onPressed: details.onStepCancel,
                            child: const Text('Back'),
                          ),
                      ],
                    ),
                  );
                },
                steps: [
                  Step(
                    title: const Text('Basics'),
                    subtitle: const Text('Title, content, and flags'),
                    content: const Step1Basics(),
                    isActive: formState.currentStep >= 0,
                    state: formState.currentStep > 0
                        ? (formState.isStep1Valid
                              ? StepState.complete
                              : StepState.error)
                        : StepState.indexed,
                  ),
                  Step(
                    title: const Text('Targeting'),
                    subtitle: const Text('Category and audience'),
                    content: const Step2Targeting(),
                    isActive: formState.currentStep >= 1,
                    state: formState.currentStep > 1
                        ? (formState.isStep2Valid
                              ? StepState.complete
                              : StepState.error)
                        : StepState.indexed,
                  ),
                  Step(
                    title: const Text('Extras'),
                    subtitle: const Text('Tags, image, and CTA'),
                    content: const Step3Extras(),
                    isActive: formState.currentStep >= 2,
                    state: formState.currentStep > 2
                        ? StepState.complete
                        : StepState.indexed,
                  ),
                ],
              ),
      ),
    );
  }
}
