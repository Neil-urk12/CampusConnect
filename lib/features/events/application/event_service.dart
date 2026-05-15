import '../domain/entities/event_entity.dart';
import '../domain/exceptions/event_exceptions.dart';
import '../domain/repositories/event_repository.dart';

class EventService {
  final EventRepository _repository;

  EventService({required EventRepository repository})
    : _repository = repository;

  /// Get events for a specific month
  Future<List<EventEntity>> getEventsForMonth(DateTime month) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    return await _repository.getEventsForDateRange(startOfMonth, endOfMonth);
  }

  /// Get a single event by ID
  Future<EventEntity> getEventById(String eventId) async {
    if (eventId.isEmpty) {
      throw EventValidationException('Event ID cannot be empty');
    }
    return await _repository.getEventById(eventId);
  }

  /// Get all upcoming events
  Future<List<EventEntity>> getAllUpcomingEvents() async {
    return await _repository.getAllUpcomingEvents();
  }

  /// Create a new event with validation
  Future<void> createEvent(EventEntity event) async {
    _validateEvent(event);
    await _repository.createEvent(event);
  }

  /// Update an existing event with validation
  Future<void> updateEvent(EventEntity event) async {
    _validateEvent(event);
    await _repository.updateEvent(event);
  }

  /// Delete an event
  Future<void> deleteEvent(String eventId) async {
    if (eventId.isEmpty) {
      throw EventValidationException('Event ID cannot be empty');
    }
    await _repository.deleteEvent(eventId);
  }

  /// Validate event fields
  void _validateEvent(EventEntity event) {
    if (event.title.trim().isEmpty) {
      throw EventValidationException('Event title is required');
    }

    if (event.description.trim().isEmpty) {
      throw EventValidationException('Event description is required');
    }

    if (event.location.trim().isEmpty) {
      throw EventValidationException('Event location is required');
    }

    if (event.createdBy.trim().isEmpty) {
      throw EventValidationException('Event creator ID is required');
    }

    if (event.createdByName.trim().isEmpty) {
      throw EventValidationException('Event creator name is required');
    }

    // Validate end date is after start date if provided
    if (event.endDateTime != null &&
        event.endDateTime!.isBefore(event.startDateTime)) {
      throw EventValidationException(
        'Event end date/time must be after start date/time',
      );
    }

    // Validate capacity is positive if provided
    if (event.capacity != null && event.capacity! <= 0) {
      throw EventValidationException('Event capacity must be greater than 0');
    }

    // Validate attendee count doesn't exceed capacity
    if (event.capacity != null && event.attendeeCount > event.capacity!) {
      throw EventValidationException(
        'Attendee count cannot exceed event capacity',
      );
    }
  }
}
