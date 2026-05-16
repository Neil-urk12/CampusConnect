import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/announcement_providers.dart';
import '../widgets/standard_announcement_card.dart';
import '../widgets/urgent_announcement_card.dart';
import '../widgets/pinned_announcement_card.dart';
import '../../../../app/routes.dart';
import '../../../../providers/auth_providers.dart';
import '../../../../core/theme/design_tokens.dart';

class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(announcementsStreamProvider);
    final selectedCategory = ref.watch(announcementCategoryProvider);
    final availableCategories = ref.watch(availableCategoriesProvider);

    // Check if user is admin/moderator for FAB visibility
    final authState = ref.watch(authStateNotifierProvider);
    final user = authState.user;
    final userRole = user?.role ?? '';
    final isAdmin = userRole == 'admin' || userRole == 'moderator';

    // Hide filter chips when loading
    final showFilters = announcementsAsync.hasValue;

    return Scaffold(
      backgroundColor: DesignTokens.surface,
      body: CustomScrollView(
        slivers: [
          // App Bar with category filter chips
          SliverAppBar(
            floating: true,
            snap: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: DesignTokens.surface,
            title: Text(
              'Announcements',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: DesignTokens.primaryContainer,
              ),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  // TODO: Implement search feature
                },
                icon: const Icon(Icons.search_rounded, size: 24),
                color: DesignTokens.primaryContainer,
                tooltip: 'Search announcements',
              ),
              IconButton(
                onPressed: () {
                  // TODO: Implement notifications feature
                },
                icon: const Icon(Icons.notifications_none_rounded, size: 24),
                color: DesignTokens.primaryContainer,
                tooltip: 'Notifications',
              ),
              const SizedBox(width: 8),
            ],
            bottom: showFilters
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(60),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: availableCategories.map((category) {
                            final isSelected = category == selectedCategory;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(category),
                                selected: isSelected,
                                onSelected: (_) {
                                  ref
                                      .read(
                                        announcementCategoryProvider.notifier,
                                      )
                                      .setCategory(category);
                                },
                                showCheckmark: false,
                                backgroundColor:
                                    DesignTokens.surfaceContainerLowest,
                                selectedColor: DesignTokens.primaryContainer,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? DesignTokens.onPrimary
                                      : DesignTokens.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: GoogleFonts.manrope().fontFamily,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: isSelected
                                        ? DesignTokens.primaryContainer
                                        : DesignTokens.outlineVariant,
                                    width: 1,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  )
                : null,
          ),
          // Announcements list
          announcementsAsync.when(
            data: (announcements) {
              if (announcements.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none_rounded,
                          size: 64,
                          color: DesignTokens.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No announcements yet',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: DesignTokens.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Check back later for updates',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            color: DesignTokens.onSurface.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Separate announcements by type
              final pinnedAnnouncements = announcements
                  .where((a) => a.isPinned)
                  .toList();
              final urgentAnnouncements = announcements
                  .where((a) => a.isUrgent && !a.isPinned)
                  .toList();
              final standardAnnouncements = announcements
                  .where((a) => !a.isUrgent && !a.isPinned)
                  .toList();

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    // Calculate which announcement to show based on index
                    if (index < pinnedAnnouncements.length) {
                      return PinnedAnnouncementCard(
                        announcement: pinnedAnnouncements[index],
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            AppRoutes.announcementDetail,
                            arguments: pinnedAnnouncements[index],
                          );
                        },
                      );
                    }

                    final urgentIndex = index - pinnedAnnouncements.length;
                    if (urgentIndex < urgentAnnouncements.length) {
                      return UrgentAnnouncementCard(
                        announcement: urgentAnnouncements[urgentIndex],
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            AppRoutes.announcementDetail,
                            arguments: urgentAnnouncements[urgentIndex],
                          );
                        },
                      );
                    }

                    final standardIndex =
                        urgentIndex - urgentAnnouncements.length;
                    if (standardIndex < standardAnnouncements.length) {
                      return StandardAnnouncementCard(
                        announcement: standardAnnouncements[standardIndex],
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            AppRoutes.announcementDetail,
                            arguments: standardAnnouncements[standardIndex],
                          );
                        },
                      );
                    }

                    // Add bottom padding after last item
                    return const SizedBox(height: 16);
                  },
                  childCount:
                      pinnedAnnouncements.length +
                      urgentAnnouncements.length +
                      standardAnnouncements.length +
                      1, // +1 for bottom padding
                ),
              );
            },
            loading: () => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: DesignTokens.primaryContainer,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading announcements...',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        color: DesignTokens.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            error: (error, stack) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: DesignTokens.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load announcements',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: DesignTokens.error,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: DesignTokens.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        ref.invalidate(announcementsStreamProvider);
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.announcementCreate);
              },
              backgroundColor: DesignTokens.primaryContainer,
              foregroundColor: DesignTokens.onPrimary,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
