import '../entities/event_entity.dart';

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
}
