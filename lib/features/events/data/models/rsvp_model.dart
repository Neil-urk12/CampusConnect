import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/rsvp_entity.dart';

/// Data model for RSVP, extends RsvpEntity for Firestore serialization
class RsvpModel extends RsvpEntity {
  const RsvpModel({
    required super.userId,
    required super.eventId,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Create RsvpModel from Firestore document
  factory RsvpModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RsvpModel(
      userId: data['userId'] as String,
      eventId: data['eventId'] as String,
      status: RsvpStatus.values.firstWhere((e) => e.name == data['status']),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Create RsvpModel from RsvpEntity
  factory RsvpModel.fromEntity(RsvpEntity entity) {
    return RsvpModel(
      userId: entity.userId,
      eventId: entity.eventId,
      status: entity.status,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Convert RsvpModel to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'eventId': eventId,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
