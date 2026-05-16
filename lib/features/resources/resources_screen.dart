import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/routes.dart';
import '../../core/theme/design_tokens.dart';
import 'domain/entities/resource_entity.dart';
import 'presentation/providers/resource_provider.dart';
import 'presentation/widgets/resource_list.dart';

/// Main resources browse screen with search, filter, sort.
class ResourcesScreen extends ConsumerStatefulWidget {
  const ResourcesScreen({super.key});

  @override
  ConsumerState<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends ConsumerState<ResourcesScreen> {
  String _searchQuery = '';
  ResourceCategory? _selectedCategory;
  String _sortBy = 'recent'; // recent | popular | a-z
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Filtering / sorting ───────────────────────────────────────────

  List<ResourceEntity> _applyFilters(List<ResourceEntity> resources) {
    var filtered = resources;

    // Category filter
    if (_selectedCategory != null) {
      filtered =
          filtered.where((r) => r.category == _selectedCategory).toList();
    }

    // Client-side search
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((r) {
        final titleMatch = r.title.toLowerCase().contains(query);
        final descMatch =
            r.description?.toLowerCase().contains(query) ?? false;
        return titleMatch || descMatch;
      }).toList();
    }

    // Sort
    switch (_sortBy) {
      case 'popular':
        filtered.sort((a, b) => b.downloadCount.compareTo(a.downloadCount));
        break;
      case 'a-z':
        filtered.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case 'recent':
      default:
        filtered.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    }

    return filtered;
  }

  Future<void> _onRefresh() async {
    await ref.read(resourceProvider.notifier).loadResources(
          category: _selectedCategory,
          sortBy: _sortBy,
        );
  }

  // ── UI ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final resourcesAsync = ref.watch(resourceProvider);

    return Scaffold(
      backgroundColor: DesignTokens.surface,
      body: CustomScrollView(
        slivers: [
          // AppBar
          SliverAppBar(
            floating: true,
            snap: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: DesignTokens.surface,
            title: Text(
              'Resources Library',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: DesignTokens.primaryContainer,
              ),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRoutes.uploadResource);
                },
                icon: const Icon(Icons.add_rounded, size: 24),
                color: DesignTokens.primaryContainer,
                tooltip: 'Upload resource',
              ),
              const SizedBox(width: DesignTokens.spacing8),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(110),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacing16,
                ),
                child: Column(
                  children: [
                    // Search bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search resources...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                                icon: const Icon(Icons.close_rounded, size: 18),
                              )
                            : null,
                        isDense: true,
                        filled: true,
                        fillColor: DesignTokens.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radiusMd),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                      },
                    ),
                    const SizedBox(height: DesignTokens.spacing8),
                    // Filter chips + sort dropdown
                    SizedBox(
                      height: 40,
                      child: Row(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildChip(null, 'All'),
                                  _buildChip(
                                      ResourceCategory.studyMaterials, 'Study Materials'),
                                  _buildChip(ResourceCategory.photos, 'Photos'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: DesignTokens.spacing8),
                          // Sort dropdown
                          DropdownButton<String>(
                            value: _sortBy,
                            underline: const SizedBox(),
                            isDense: true,
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: DesignTokens.onSurfaceVariant,
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'recent', child: Text('Recent')),
                              DropdownMenuItem(
                                  value: 'popular', child: Text('Popular')),
                              DropdownMenuItem(
                                  value: 'a-z', child: Text('A-Z')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _sortBy = value);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Resource list
          resourcesAsync.when(
            data: (resources) {
              final filtered = _applyFilters(resources);
              return SliverFillRemaining(
                hasScrollBody: true,
                child: RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ResourceList(resources: filtered),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: ResourceList(resources: [], isLoading: true),
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
                    const SizedBox(height: DesignTokens.spacing16),
                    Text(
                      'Failed to load resources',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: DesignTokens.error,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spacing8),
                    Text(
                      error.toString(),
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: DesignTokens.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: DesignTokens.spacing16),
                    ElevatedButton.icon(
                      onPressed: () => ref.invalidate(resourceProvider),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed(AppRoutes.uploadResource);
        },
        backgroundColor: DesignTokens.primaryContainer,
        foregroundColor: DesignTokens.onPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildChip(ResourceCategory? category, String label) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: DesignTokens.spacing8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            _selectedCategory = isSelected ? null : category;
          });
        },
        showCheckmark: false,
        backgroundColor: DesignTokens.surfaceContainerLowest,
        selectedColor: DesignTokens.primaryContainer,
        labelStyle: TextStyle(
          color: isSelected
              ? DesignTokens.onPrimary
              : DesignTokens.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          fontSize: 12,
          fontFamily: GoogleFonts.manrope().fontFamily,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
          side: BorderSide(
            color: isSelected
                ? DesignTokens.primaryContainer
                : DesignTokens.outlineVariant,
            width: 1,
          ),
        ),
      ),
    );
  }
}
