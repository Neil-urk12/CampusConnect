import 'package:equatable/equatable.dart';

/// RSVP status for event attendance
enum RsvpStatus {
  /// User is confirmed to attend the event
  attending,

  /// User is on the waitlist for a full event
  waitlisted,
}

/// Entity representing a user's RSVP for an event
class RsvpEntity extends Equatable {
  final String userId;
  final String eventId;
  final RsvpStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RsvpEntity({
    required this.userId,
    required this.eventId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [userId, eventId, status, createdAt, updatedAt];

  RsvpEntity copyWith({
    String? userId,
    String? eventId,
    RsvpStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RsvpEntity(
      userId: userId ?? this.userId,
      eventId: eventId ?? this.eventId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
