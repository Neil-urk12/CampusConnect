import 'package:equatable/equatable.dart';

enum EventCategory { academic, social, sports, career }

class EventEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime startDateTime;
  final DateTime? endDateTime;
  final EventCategory category;
  final DateTime createdAt;
  final String createdBy;
  final String createdByName;
  final bool isPublished;
  final int attendeeCount;
  final int? capacity;
  final String? imageUrl;
  final List<String>? tags;
  final DateTime? updatedAt;

  const EventEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.startDateTime,
    this.endDateTime,
    required this.category,
    required this.createdAt,
    required this.createdBy,
    required this.createdByName,
    required this.isPublished,
    this.attendeeCount = 0,
    this.capacity,
    this.imageUrl,
    this.tags,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    location,
    startDateTime,
    endDateTime,
    category,
    createdAt,
    createdBy,
    createdByName,
    isPublished,
    attendeeCount,
    capacity,
    imageUrl,
    tags,
    updatedAt,
  ];
}
