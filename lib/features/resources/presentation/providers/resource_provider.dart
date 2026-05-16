import 'dart:io';

import '../../data/datasources/resource_firestore_datasource.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/appwrite_storage_service.dart';
import '../../application/resource_service.dart';
import '../../data/repositories/resource_repository_impl.dart';
import '../../domain/entities/resource_entity.dart';
import '../../domain/repositories/resource_repository.dart';

class ResourceStateNotifier extends Notifier<AsyncValue<List<ResourceEntity>>> {
  @override
  AsyncValue<List<ResourceEntity>> build() {
    Future.microtask(loadResources);
    return const AsyncValue.loading();
  }

  Future<void> loadResources({
    ResourceCategory? category,
    String? sortBy,
  }) async {
    state = const AsyncValue.loading();

    try {
      final service = ref.read(resourceServiceProvider);
      final resources = await service.getResources(
        category: category,
        sortBy: sortBy,
      );
      state = AsyncValue.data(resources);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> uploadResource(ResourceEntity resource, File file) async {
    final service = ref.read(resourceServiceProvider);
    await service.uploadResource(resource, file);
    await loadResources();
  }

  Future<void> deleteResource(String id, String currentUserId) async {
    final previousState = state;

    state.whenData((resources) {
      state = AsyncValue.data(
        resources.where((resource) => resource.id != id).toList(),
      );
    });

    try {
      final service = ref.read(resourceServiceProvider);
      await service.deleteResource(id, currentUserId);
    } catch (_) {
      state = previousState;
      await loadResources();
      rethrow;
    }
  }

  Future<void> incrementDownloadCount(String id) async {
    final service = ref.read(resourceServiceProvider);
    await service.incrementDownloadCount(id);
  }
}

final resourceRepositoryProvider = Provider<ResourceRepository>((ref) {
  return ResourceRepositoryImpl(
    datasource: ResourceFirestoreDataSource(),
    storageService: AppwriteStorageService(),
  );
});

final resourceServiceProvider = Provider<ResourceService>((ref) {
  final repository = ref.watch(resourceRepositoryProvider);
  return ResourceService(repository: repository);
});

final resourceProvider =
    NotifierProvider<ResourceStateNotifier, AsyncValue<List<ResourceEntity>>>(
      ResourceStateNotifier.new,
    );
