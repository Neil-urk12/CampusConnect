import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/entities/resource_entity.dart';
import 'providers/resource_provider.dart';
import 'utils/file_type_utils.dart';
import '../../../providers/auth_providers.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/theme/design_tokens.dart';

/// Detail screen for viewing, downloading, sharing, and deleting a resource.
class ResourceDetailScreen extends ConsumerWidget {
  final ResourceEntity resource;

  const ResourceDetailScreen({super.key, required this.resource});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateNotifierProvider);
    final currentUserId = authState.user?.userId;
    final isOwner = currentUserId != null && currentUserId == resource.uploadedBy;

    return Scaffold(
      backgroundColor: DesignTokens.surface,
      appBar: AppBar(
        backgroundColor: DesignTokens.surface,
        elevation: 0,
        title: Text(
          'Resource Details',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: DesignTokens.primaryContainer,
          ),
        ),
        actions: [
          // Copy link
          IconButton(
            onPressed: () => _copyLink(context),
            icon: const Icon(Icons.link_rounded),
            tooltip: 'Copy link',
          ),
          // Share
          IconButton(
            onPressed: () => _share(),
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share',
          ),
          // Delete (owner only)
          if (isOwner)
            IconButton(
              onPressed: () => _confirmDelete(context, ref),
              icon: const Icon(Icons.delete_outline_rounded),
              color: DesignTokens.error,
              tooltip: 'Delete',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview area
            _buildPreview(context),
            const SizedBox(height: DesignTokens.spacing24),

            // Title
            Text(
              resource.title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: DesignTokens.onSurface,
              ),
            ),
            const SizedBox(height: DesignTokens.spacing8),

            // Category badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacing12,
                vertical: DesignTokens.spacing4,
              ),
              decoration: BoxDecoration(
                color: _categoryColor(resource.category).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
              ),
              child: Text(
                _categoryLabel(resource.category),
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _categoryColor(resource.category),
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.spacing16),

            // Description
            if (resource.description != null &&
                resource.description!.isNotEmpty) ...[
              Text(
                resource.description!,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: DesignTokens.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: DesignTokens.spacing16),
            ],

            // Tags
            if (resource.tags.isNotEmpty) ...[
              Wrap(
                spacing: DesignTokens.spacing8,
                runSpacing: DesignTokens.spacing4,
                children: resource.tags
                    .map((tag) => Chip(
                          label: Text(tag),
                          labelStyle: GoogleFonts.manrope(fontSize: 12),
                          backgroundColor: DesignTokens.surfaceContainerLow,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
              const SizedBox(height: DesignTokens.spacing16),
            ],

            // Metadata list
            Container(
              padding: const EdgeInsets.all(DesignTokens.spacing16),
              decoration: BoxDecoration(
                color: DesignTokens.surfaceContainerLow,
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
              child: Column(
                children: [
                  _metadataRow(Icons.person_rounded, 'Uploaded by',
                      resource.uploadedByName),
                  _metadataRow(Icons.calendar_today_rounded, 'Date',
                      DateFormat('MMM d, yyyy · h:mm a').format(resource.uploadedAt)),
                  _metadataRow(Icons.insert_drive_file_rounded, 'File',
                      '${resource.fileName} (${formatFileSize(resource.fileSize)})'),
                  _metadataRow(Icons.category_rounded, 'Type',
                      getFileTypeLabel(resource.mimeType)),
                  _metadataRow(Icons.download_rounded, 'Downloads',
                      '${resource.downloadCount}'),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.spacing24),

            // Action buttons
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _download(context, ref),
                icon: const Icon(Icons.download_rounded),
                label: const Text('Download'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.primaryContainer,
                  foregroundColor: DesignTokens.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  ),
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.spacing12),

            // Open in browser (for previewable types)
            if (shouldPreview(resource.mimeType))
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _openInBrowser(),
                  icon: const Icon(Icons.open_in_browser_rounded),
                  label: const Text('Open in Browser'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: DesignTokens.outlineVariant),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Preview ───────────────────────────────────────────────────────

  Widget _buildPreview(BuildContext context) {
    if (isImage(resource.mimeType) && resource.fileUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        child: GestureDetector(
          onTap: () => _openInBrowser(),
          child: Image.network(
            resource.fileUrl,
            width: double.infinity,
            height: 250,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _previewPlaceholder(),
          ),
        ),
      );
    }
    return _previewPlaceholder();
  }

  Widget _previewPlaceholder() {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: DesignTokens.surfaceContainerLow,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              getFileIcon(resource.mimeType),
              size: 48,
              color: DesignTokens.primaryContainer.withValues(alpha: 0.5),
            ),
            const SizedBox(height: DesignTokens.spacing8),
            Text(
              getFileTypeLabel(resource.mimeType),
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: DesignTokens.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────

  Future<void> _download(BuildContext context, WidgetRef ref) async {
    try {
      // Increment download count
      await ref
          .read(resourceProvider.notifier)
          .incrementDownloadCount(resource.id);

      // Open file URL
      final uri = Uri.parse(resource.fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      AppLogger.error('Download failed', error: e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to download file'),
            backgroundColor: DesignTokens.error,
          ),
        );
      }
    }
  }

  void _share() {
    Share.share(
      'Check out this resource: ${resource.title}\n${resource.fileUrl}',
      subject: resource.title,
    );
  }

  void _copyLink(BuildContext context) {
    Clipboard.setData(ClipboardData(text: resource.fileUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied to clipboard')),
    );
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.parse(resource.fileUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Resource'),
        content: Text(
          'Are you sure you want to delete "${resource.title}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _delete(context, ref);
            },
            style: TextButton.styleFrom(foregroundColor: DesignTokens.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final currentUserId = ref.read(authStateNotifierProvider).user?.userId;
    if (currentUserId == null) return;

    try {
      await ref
          .read(resourceProvider.notifier)
          .deleteResource(resource.id, currentUserId);

      if (context.mounted) {
        Navigator.of(context).pop(); // back to list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resource deleted')),
        );
      }
    } catch (e) {
      AppLogger.error('Delete failed', error: e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: ${e.toString()}'),
            backgroundColor: DesignTokens.error,
          ),
        );
      }
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────

  Widget _metadataRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacing8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: DesignTokens.onSurfaceVariant),
          const SizedBox(width: DesignTokens.spacing12),
          Text(
            '$label:',
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: DesignTokens.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: DesignTokens.spacing8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: DesignTokens.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  static Color _categoryColor(ResourceCategory category) {
    switch (category) {
      case ResourceCategory.studyMaterials:
        return DesignTokens.categoryAcademic;
      case ResourceCategory.photos:
        return DesignTokens.categorySocial;
      case ResourceCategory.other:
        return DesignTokens.onSurfaceVariant;
    }
  }

  static String _categoryLabel(ResourceCategory category) {
    switch (category) {
      case ResourceCategory.studyMaterials:
        return 'Study Materials';
      case ResourceCategory.photos:
        return 'Photos';
      case ResourceCategory.other:
        return 'Other';
    }
  }
}
