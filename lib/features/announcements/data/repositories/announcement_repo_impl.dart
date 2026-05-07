import '../../domain/entities/announcement_entity.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../datasources/announcement_firestore_ds.dart';
import '../models/announcement_model.dart';

class AnnouncementRepositoryImpl implements AnnouncementRepository {
  final AnnouncementFirestoreDataSource _dataSource;

  AnnouncementRepositoryImpl({
    required AnnouncementFirestoreDataSource dataSource,
  }) : _dataSource = dataSource;

  @override
  Stream<List<AnnouncementEntity>> getAnnouncementsStream({
    required String userId,
    required List<String> userRoles,
    String? category,
    int limit = 50,
  }) {
    return _dataSource
        .getAnnouncementsStream(
          userRoles: userRoles,
          category: category,
          limit: limit,
        )
        .map((models) => models.map((model) => model.toEntity()).toList());
  }

  @override
  Future<AnnouncementEntity> getAnnouncementById(String id) async {
    final model = await _dataSource.getAnnouncementById(id);
    return model.toEntity();
  }

  @override
  Future<String> createAnnouncement(AnnouncementEntity announcement) async {
    final model = AnnouncementModel.fromEntity(announcement);
    return await _dataSource.createAnnouncement(model);
  }

  @override
  Future<void> updateAnnouncement(AnnouncementEntity announcement) async {
    final model = AnnouncementModel.fromEntity(announcement);
    await _dataSource.updateAnnouncement(model);
  }

  @override
  Future<void> deleteAnnouncement(String id) async {
    await _dataSource.deleteAnnouncement(id);
  }
}
