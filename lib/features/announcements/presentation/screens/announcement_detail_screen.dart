import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/announcement_entity.dart';
import '../../providers/announcement_providers.dart';
import '../../../../providers/auth_providers.dart';
import '../../../../core/theme/app_theme.dart';

/// Detail screen for viewing a single announcement with admin actions
class AnnouncementDetailScreen extends ConsumerStatefulWidget {
  final AnnouncementEntity announcement;

  const AnnouncementDetailScreen({super.key, required this.announcement});

  @override
  ConsumerState<AnnouncementDetailScreen> createState() =>
      _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState
    extends ConsumerState<AnnouncementDetailScreen> {
  late AnnouncementEntity _currentAnnouncement;

  @override
  void initState() {
    super.initState();
    _currentAnnouncement = widget.announcement;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateNotifierProvider);
    final user = authState.user;
    final userRole = user?.role ?? '';
    final isAdmin = userRole == 'admin' || userRole == 'moderator';

    // Use app theme colors
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final secondaryColor = theme.colorScheme.secondary;

    return Scaffold(
      backgroundColor: AppTheme.neutral,
      appBar: AppBar(
        backgroundColor: AppTheme.neutral,
        elevation: 0,
        title: Text(
          'Announcement',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        actions: [
          if (isAdmin)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: primaryColor),
              onSelected: (value) {
                if (value == 'edit') {
                  _navigateToEdit(context, _currentAnnouncement);
                } else if (value == 'delete') {
                  _showDeleteDialog(context, ref, _currentAnnouncement);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20, color: primaryColor),
                      const SizedBox(width: 12),
                      const Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete,
                        size: 20,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Delete',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badges (Pinned/Urgent)
            if (_currentAnnouncement.isPinned || _currentAnnouncement.isUrgent)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    if (_currentAnnouncement.isPinned)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.push_pin,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'PINNED',
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_currentAnnouncement.isPinned &&
                        _currentAnnouncement.isUrgent)
                      const SizedBox(width: 8),
                    if (_currentAnnouncement.isUrgent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC3545),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.warning_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'URGENT',
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

            // Main content card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE9ECEF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    _currentAnnouncement.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Metadata row
                  Row(
                    children: [
                      // Category badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: secondaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: secondaryColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          _currentAnnouncement.category,
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: secondaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Timestamp
                      Text(
                        DateFormat(
                          'MMM d, yyyy • h:mm a',
                        ).format(_currentAnnouncement.createdAt),
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          color: const Color(0xFF6C757D),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Body
                  Text(
                    _currentAnnouncement.body,
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      height: 1.6,
                      color: const Color(0xFF495057),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tags
                  if (_currentAnnouncement.tags.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _currentAnnouncement.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFDEE2E6)),
                          ),
                          child: Text(
                            '#$tag',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF495057),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Image attachment
                  if (_currentAnnouncement.attachmentUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _currentAnnouncement.attachmentUrl!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            color: const Color(0xFFF8F9FA),
                            child: const Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 48,
                                color: Color(0xFFDEE2E6),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // CTA button
                  if (_currentAnnouncement.isPinned &&
                      _currentAnnouncement.ctaLabel != null &&
                      _currentAnnouncement.ctaUrl != null) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () =>
                            _launchUrl(_currentAnnouncement.ctaUrl!),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: secondaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          _currentAnnouncement.ctaLabel!,
                          style: GoogleFonts.manrope(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Divider
                  const Divider(height: 32),

                  // Author info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: primaryColor.withValues(alpha: 0.1),
                        backgroundImage:
                            _currentAnnouncement.authorAvatarUrl != null
                            ? NetworkImage(
                                _currentAnnouncement.authorAvatarUrl!,
                              )
                            : null,
                        child: _currentAnnouncement.authorAvatarUrl == null
                            ? Text(
                                _currentAnnouncement.authorName[0]
                                    .toUpperCase(),
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentAnnouncement.authorName,
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E1E1E),
                              ),
                            ),
                            if (_currentAnnouncement.authorDepartment != null)
                              Text(
                                _currentAnnouncement.authorDepartment!,
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  color: const Color(0xFF6C757D),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Target audience
                  const SizedBox(height: 16),
                  Text(
                    'Visible to: ${_currentAnnouncement.targetAudience.map((a) => a[0].toUpperCase() + a.substring(1)).join(', ')}',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: const Color(0xFF6C757D),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToEdit(
    BuildContext context,
    AnnouncementEntity announcement,
  ) async {
    final result = await Navigator.of(
      context,
    ).pushNamed('/announcements/edit', arguments: announcement);

    // If edit succeeded, refresh announcement data
    if (result == true && mounted) {
      try {
        final announcementService = ref.read(announcementServiceProvider);
        final freshAnnouncement = await announcementService.getAnnouncementById(
          announcement.id,
        );
        setState(() {
          _currentAnnouncement = freshAnnouncement;
        });
      } catch (e) {
        // Silently fail - user can refresh by navigating back and forth
      }
    }
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    AnnouncementEntity announcement,
  ) {
    final theme = Theme.of(context);
    // Capture screen context before dialog builder
    final screenContext = context;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Announcement?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentAnnouncement.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'This action cannot be undone. The announcement will be permanently deleted.',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _deleteAnnouncement(screenContext, ref, announcement);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAnnouncement(
    BuildContext context,
    WidgetRef ref,
    AnnouncementEntity announcement,
  ) async {
    try {
      final announcementService = ref.read(announcementServiceProvider);
      final authState = ref.read(authStateNotifierProvider);
      final userRole = authState.user?.role ?? '';
      final userRoles = userRole.isNotEmpty ? <String>[userRole] : <String>[];

      await announcementService.deleteAnnouncement(
        id: _currentAnnouncement.id,
        userRoles: userRoles,
      );

      if (context.mounted) {
        Navigator.of(context).pop(); // Go back to list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Announcement deleted successfully'),
            backgroundColor:
                Theme.of(
                  context,
                ).extension<ThemeData>()?.colorScheme.tertiary ??
                Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete announcement: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
