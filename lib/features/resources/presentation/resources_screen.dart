import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../domain/entities/resource_entity.dart';
import 'providers/resource_provider.dart';
import 'widgets/resource_list.dart';

class ResourcesScreen extends ConsumerStatefulWidget {
  const ResourcesScreen({super.key});

  @override
  ConsumerState<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends ConsumerState<ResourcesScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  ResourceCategory? _category;
  String _sort = 'Recent';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resourcesAsync = ref.watch(resourceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Resources Library')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.uploadResource),
        icon: const Icon(Icons.add),
        label: const Text('Upload'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(resourceProvider.notifier).loadResources(
              category: _category,
              sortBy: _sort,
            ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search resources',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 12),
                  _buildFilters(),
                ],
              ),
            ),
            Expanded(
              child: resourcesAsync.when(
                data: (resources) => ResourceList(
                  resources: _filterAndSort(resources).take(50).toList(),
                  emptyMessage: _query.isEmpty && _category == null
                      ? 'No resources uploaded yet'
                      : 'No matching resources found',
                ),
                error: (error, _) => ListView(
                  children: [
                    const SizedBox(height: 120),
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Could not load resources',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                loading: () => const ResourceList(resources: [], isLoading: true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('All', null),
                const SizedBox(width: 8),
                _filterChip('Study Materials', ResourceCategory.studyMaterials),
                const SizedBox(width: 8),
                _filterChip('Photos', ResourceCategory.photos),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        DropdownButton<String>(
          value: _sort,
          items: const [
            DropdownMenuItem(value: 'Recent', child: Text('Recent')),
            DropdownMenuItem(value: 'Popular', child: Text('Popular')),
            DropdownMenuItem(value: 'A-Z', child: Text('A-Z')),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() => _sort = value);
          },
        ),
      ],
    );
  }

  Widget _filterChip(String label, ResourceCategory? category) {
    return FilterChip(
      label: Text(label),
      selected: _category == category,
      onSelected: (_) => setState(() => _category = category),
    );
  }

  List<ResourceEntity> _filterAndSort(List<ResourceEntity> resources) {
    final query = _query.trim().toLowerCase();
    final filtered = resources.where((resource) {
      final matchesCategory = _category == null || resource.category == _category;
      final matchesQuery = query.isEmpty ||
          resource.title.toLowerCase().contains(query) ||
          (resource.description ?? '').toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();

    switch (_sort) {
      case 'Popular':
        filtered.sort((a, b) => b.downloadCount.compareTo(a.downloadCount));
        break;
      case 'A-Z':
        filtered.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case 'Recent':
      default:
        filtered.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    }

    return filtered;
  }
}
