import '../entities/event_entity.dart';
import '../entities/rsvp_entity.dart';

abstract class EventRepository {
  /// Get events within a date range (for calendar month view)
  Future<List<EventEntity>> getEventsForDateRange(
    DateTime startDate,
    DateTime endDate,
  );

  /// Get a single event by ID
  Future<EventEntity> getEventById(String eventId);

  /// Get all upcoming events (startDateTime >= now)
  Future<List<EventEntity>> getAllUpcomingEvents();

  /// Create a new event
  Future<void> createEvent(EventEntity event);

  /// Update an existing event
  Future<void> updateEvent(EventEntity event);

  /// Delete an event
  Future<void> deleteEvent(String eventId);

  /// Create an RSVP for a user
  Future<RsvpEntity> createRsvp({
    required String eventId,
    required String userId,
    required RsvpStatus status,
  });

  /// Delete a user's RSVP
  Future<void> deleteRsvp({required String eventId, required String userId});

  /// Get a user's RSVP for an event
  Future<RsvpEntity?> getRsvp({
    required String eventId,
    required String userId,
  });

  /// Update a user's RSVP status
  Future<RsvpEntity> updateRsvp({
    required String eventId,
    required String userId,
    required RsvpStatus newStatus,
  });
}
