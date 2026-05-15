import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/event_entity.dart';

class EventModel extends EventEntity {
  const EventModel({
    required super.id,
    required super.title,
    required super.description,
    required super.location,
    required super.startDateTime,
    super.endDateTime,
    required super.category,
    required super.createdAt,
    required super.createdBy,
    required super.createdByName,
    required super.isPublished,
    super.attendeeCount = 0,
    super.capacity,
    super.imageUrl,
    super.tags,
    super.updatedAt,
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      title: data['title'] as String,
      description: data['description'] as String,
      location: data['location'] as String,
      startDateTime: (data['startDateTime'] as Timestamp).toDate(),
      endDateTime: data['endDateTime'] != null
          ? (data['endDateTime'] as Timestamp).toDate()
          : null,
      category: _categoryFromString(data['category'] as String),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] as String,
      createdByName: data['createdByName'] as String,
      isPublished: data['isPublished'] as bool? ?? true,
      attendeeCount: data['attendeeCount'] as int? ?? 0,
      capacity: data['capacity'] as int?,
      imageUrl: data['imageUrl'] as String?,
      tags: data['tags'] != null ? List<String>.from(data['tags']) : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'startDateTime': Timestamp.fromDate(startDateTime),
      'endDateTime': endDateTime != null
          ? Timestamp.fromDate(endDateTime!)
          : null,
      'category': _categoryToString(category),
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'createdByName': createdByName,
      'isPublished': isPublished,
      'attendeeCount': attendeeCount,
      'capacity': capacity,
      'imageUrl': imageUrl,
      'tags': tags,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  static EventCategory _categoryFromString(String category) {
    switch (category.toLowerCase()) {
      case 'academic':
        return EventCategory.academic;
      case 'social':
        return EventCategory.social;
      case 'sports':
        return EventCategory.sports;
      case 'career':
        return EventCategory.career;
      default:
        throw ArgumentError('Invalid category: $category');
    }
  }

  static String _categoryToString(EventCategory category) {
    switch (category) {
      case EventCategory.academic:
        return 'academic';
      case EventCategory.social:
        return 'social';
      case EventCategory.sports:
        return 'sports';
      case EventCategory.career:
        return 'career';
    }
  }

  factory EventModel.fromEntity(EventEntity entity) {
    return EventModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      location: entity.location,
      startDateTime: entity.startDateTime,
      endDateTime: entity.endDateTime,
      category: entity.category,
      createdAt: entity.createdAt,
      createdBy: entity.createdBy,
      createdByName: entity.createdByName,
      isPublished: entity.isPublished,
      attendeeCount: entity.attendeeCount,
      capacity: entity.capacity,
      imageUrl: entity.imageUrl,
      tags: entity.tags,
      updatedAt: entity.updatedAt,
    );
  }
}
