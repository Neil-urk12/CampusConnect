import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/announcement_form_state.dart';
import '../../domain/entities/announcement_entity.dart';
import '../../application/announcement_service.dart';
import '../../providers/announcement_providers.dart';
import '../../../../providers/auth_providers.dart';
import 'draft_provider.dart';

/// Notifier for managing announcement form state
class AnnouncementFormNotifier extends Notifier<AnnouncementFormState> {
  late AnnouncementService _announcementService;
  late DraftService _draftService;
  late bool _isEditMode;
  late AnnouncementEntity? _existingAnnouncement;

  @override
  AnnouncementFormState build() {
    _announcementService = ref.watch(announcementServiceProvider);
    _draftService = ref.watch(draftServiceProvider);
    _isEditMode = false;
    _existingAnnouncement = null;

    return const AnnouncementFormState();
  }

  /// Initialize for edit mode
  void initializeForEdit(AnnouncementEntity announcement) {
    _isEditMode = true;
    _existingAnnouncement = announcement;
    _loadExistingAnnouncement(announcement);
  }

  /// Reset form to blank state (for create mode)
  void resetForm() {
    _isEditMode = false;
    _existingAnnouncement = null;
    state = const AnnouncementFormState();
  }

  /// Load existing announcement data for editing
  void _loadExistingAnnouncement(AnnouncementEntity announcement) {
    state = AnnouncementFormState(
      title: announcement.title,
      body: announcement.body,
      isUrgent: announcement.isUrgent,
      isPinned: announcement.isPinned,
      categoryName: announcement.category,
      targetAudience: List.from(announcement.targetAudience),
      tags: List.from(announcement.tags),
      attachmentUrl: announcement.attachmentUrl,
      ctaLabel: announcement.ctaLabel,
      ctaUrl: announcement.ctaUrl,
    );
  }

  /// Check for existing draft
  Future<AnnouncementFormState?> checkForDraft() async {
    return await _draftService.loadDraft();
  }

  /// Restore draft
  void restoreDraft(AnnouncementFormState draft) {
    state = draft;
  }

  /// Clear draft
  Future<void> clearDraft() async {
    await _draftService.deleteDraft();
  }

  /// Update title
  void updateTitle(String title) {
    state = state.copyWith(title: title);
    _saveDraftIfNeeded();
  }

  /// Update body
  void updateBody(String body) {
    state = state.copyWith(body: body);
    _saveDraftIfNeeded();
  }

  /// Update urgent flag
  void updateIsUrgent(bool isUrgent) {
    state = state.copyWith(isUrgent: isUrgent);
    _saveDraftIfNeeded();
  }

  /// Update pinned flag
  void updateIsPinned(bool isPinned) {
    state = state.copyWith(isPinned: isPinned);
    // Clear CTA if unpinning
    if (!isPinned) {
      state = state.clearCTA();
    }
    _saveDraftIfNeeded();
  }

  /// Update category
  void updateCategory(String categoryId, String categoryName) {
    state = state.copyWith(categoryId: categoryId, categoryName: categoryName);
    _saveDraftIfNeeded();
  }

  /// Update target audience
  void updateTargetAudience(List<String> audience) {
    state = state.copyWith(targetAudience: audience);
    _saveDraftIfNeeded();
  }

  /// Toggle audience role
  void toggleAudience(String role) {
    final currentAudience = List<String>.from(state.targetAudience);
    if (currentAudience.contains(role)) {
      currentAudience.remove(role);
    } else {
      currentAudience.add(role);
    }
    updateTargetAudience(currentAudience);
  }

  /// Update tags
  void updateTags(List<String> tags) {
    state = state.copyWith(tags: tags);
    _saveDraftIfNeeded();
  }

  /// Update attachment URL
  void updateAttachmentUrl(String? url) {
    state = state.copyWith(attachmentUrl: url);
    _saveDraftIfNeeded();
  }

  /// Remove attachment
  void removeAttachment() {
    state = state.clearAttachment();
    _saveDraftIfNeeded();
  }

  /// Update CTA label
  void updateCtaLabel(String? label) {
    state = state.copyWith(ctaLabel: label);
    _saveDraftIfNeeded();
  }

  /// Update CTA URL
  void updateCtaUrl(String? url) {
    state = state.copyWith(ctaUrl: url);
    _saveDraftIfNeeded();
  }

  /// Update current step
  void updateCurrentStep(int step) {
    state = state.copyWith(currentStep: step);
  }

  /// Save draft if in create mode
  Future<void> _saveDraftIfNeeded() async {
    if (!_isEditMode) {
      await _draftService.saveDraft(state);
    }
  }

  /// Validate current step
  String? validateCurrentStep() {
    switch (state.currentStep) {
      case 0:
        if (state.title.trim().isEmpty) {
          return 'Title cannot be empty';
        }
        if (state.body.trim().isEmpty) {
          return 'Body cannot be empty';
        }
        if (state.body.length > 500) {
          return 'Body cannot exceed 500 characters';
        }
        return null;
      case 1:
        if (state.categoryId == null || state.categoryId!.isEmpty) {
          return 'Category is required';
        }
        if (state.targetAudience.isEmpty) {
          return 'Select at least one audience';
        }
        return null;
      case 2:
        // Step 3 is optional, but validate CTA if present
        if (state.isPinned) {
          final hasCtaLabel = state.ctaLabel?.trim().isNotEmpty ?? false;
          final hasCtaUrl = state.ctaUrl?.trim().isNotEmpty ?? false;
          if (hasCtaLabel != hasCtaUrl) {
            return 'Both CTA label and URL are required';
          }
          // Basic URL validation
          if (hasCtaUrl) {
            final url = state.ctaUrl!.trim();
            if (!url.startsWith('http://') && !url.startsWith('https://')) {
              return 'CTA URL must start with http:// or https://';
            }
          }
        }
        return null;
      default:
        return null;
    }
  }

  /// Submit form (create or update)
  Future<bool> submitForm() async {
    // Final validation
    if (!state.isFormValid) {
      state = state.copyWith(
        errorMessage: 'Please complete all required fields',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final authState = ref.read(authStateNotifierProvider);
      final user = authState.user;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      final userRoles = user.role.isNotEmpty ? <String>[user.role] : <String>[];

      if (_isEditMode && _existingAnnouncement != null) {
        // Update existing announcement
        final updatedAnnouncement = AnnouncementEntity(
          id: _existingAnnouncement!.id,
          title: state.title.trim(),
          body: state.body.trim(),
          category: state.categoryName ?? '',
          tags: state.tags,
          createdAt: _existingAnnouncement!.createdAt,
          updatedAt: DateTime.now(),
          authorId: _existingAnnouncement!.authorId,
          authorName: _existingAnnouncement!.authorName,
          authorAvatarUrl: _existingAnnouncement!.authorAvatarUrl,
          authorDepartment: _existingAnnouncement!.authorDepartment,
          isUrgent: state.isUrgent,
          isPinned: state.isPinned,
          targetAudience: state.targetAudience,
          attachmentUrl: state.attachmentUrl,
          attachmentType: state.attachmentUrl != null ? 'image' : null,
          ctaLabel: state.isPinned ? state.ctaLabel : null,
          ctaUrl: state.isPinned ? state.ctaUrl : null,
        );

        await _announcementService.updateAnnouncement(
          announcement: updatedAnnouncement,
          userRoles: userRoles,
        );
      } else {
        // Create new announcement
        final newAnnouncement = AnnouncementEntity(
          id: '', // Firestore will generate
          title: state.title.trim(),
          body: state.body.trim(),
          category: state.categoryName ?? '',
          tags: state.tags,
          createdAt: DateTime.now(),
          authorId: user.userId,
          authorName: user.fullName,
          authorAvatarUrl: null, // UserEntity doesn't have avatarUrl
          authorDepartment: null, // UserEntity doesn't have department
          isUrgent: state.isUrgent,
          isPinned: state.isPinned,
          targetAudience: state.targetAudience,
          attachmentUrl: state.attachmentUrl,
          attachmentType: state.attachmentUrl != null ? 'image' : null,
          ctaLabel: state.isPinned ? state.ctaLabel : null,
          ctaUrl: state.isPinned ? state.ctaUrl : null,
        );

        await _announcementService.createAnnouncement(
          announcement: newAnnouncement,
          userRoles: userRoles,
        );

        // Clear draft on successful creation
        await clearDraft();
      }

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

/// Provider for announcement form notifier (create mode)
final announcementFormProvider =
    NotifierProvider<AnnouncementFormNotifier, AnnouncementFormState>(
      AnnouncementFormNotifier.new,
    );
