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

    // Academic Pulse Theme Definition
    final academicTheme = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF003366),
        primary: const Color(0xFF003366),
        onPrimary: Colors.white,
        secondary: DesignTokens.secondary,
        onSecondary: DesignTokens.onSecondary,
        tertiary: const Color(0xFF4DB6AC),
        onTertiary: Colors.white,
        surface: DesignTokens.surfaceContainerLowest,
        onSurface: const Color(0xFF1E1E1E),
        surfaceContainerHighest: DesignTokens.surfaceContainerHigh,
        outline: DesignTokens.outlineVariant,
      ),
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.bold,
          color: const Color(0xFF003366),
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.bold,
          color: const Color(0xFF003366),
        ),
        headlineSmall: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.bold,
          color: const Color(0xFF003366),
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1E1E1E),
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1E1E1E),
        ),
        titleSmall: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1E1E1E),
        ),
        bodyLarge: GoogleFonts.manrope(color: const Color(0xFF495057)),
        bodyMedium: GoogleFonts.manrope(color: const Color(0xFF495057)),
        bodySmall: GoogleFonts.manrope(color: const Color(0xFF6C757D)),
        labelLarge: GoogleFonts.manrope(
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1E1E1E),
        ),
        labelMedium: GoogleFonts.manrope(
          fontWeight: FontWeight.w600,
          color: const Color(0xFF495057),
        ),
        labelSmall: GoogleFonts.manrope(
          fontWeight: FontWeight.w600,
          color: const Color(0xFF6C757D),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF8F9FA),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: Color(0xFFE9ECEF), width: 1),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF003366),
        labelStyle: GoogleFonts.manrope(
          fontWeight: FontWeight.w600,
          color: const Color(0xFF495057),
        ),
        secondaryLabelStyle: GoogleFonts.manrope(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFDEE2E6), width: 1),
        ),
      ),
    );

    final theme = academicTheme;

    // Hide filter chips when loading
    final showFilters = announcementsAsync.hasValue;

    return Theme(
      data: academicTheme,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: CustomScrollView(
          slivers: [
            // App Bar with category filter chips
            SliverAppBar(
              floating: true,
              snap: true,
              elevation: 0,
              backgroundColor: theme.scaffoldBackgroundColor,
              title: Text(
                'Announcements',
                style: theme.textTheme.headlineSmall,
              ),
              actions: [
                IconButton(
                  onPressed: () {
                    // TODO: Implement search feature
                  },
                  icon: const Icon(Icons.search_rounded, size: 24),
                  color: const Color(0xFF003366),
                  tooltip: 'Search announcements',
                ),
                IconButton(
                  onPressed: () {
                    // TODO: Implement notifications feature
                  },
                  icon: const Icon(Icons.notifications_none_rounded, size: 24),
                  color: const Color(0xFF003366),
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
                                  backgroundColor: Colors.white,
                                  selectedColor: theme.colorScheme.primary,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF495057),
                                    fontWeight: FontWeight.w600,
                                    fontFamily:
                                        GoogleFonts.manrope().fontFamily,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : const Color(0xFFDEE2E6),
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
                            color: theme.colorScheme.onSurface.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No announcements yet',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Check back later for updates',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.5,
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
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading announcements...',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
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
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load announcements',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
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
                backgroundColor: const Color(0xFF003366),
                child: const Icon(Icons.add, color: Colors.white),
              )
            : null,
      ),
    );
  }
}
