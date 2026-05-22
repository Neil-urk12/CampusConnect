import '../domain/entities/event_entity.dart';
import '../domain/entities/rsvp_entity.dart';
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

  /// Create an RSVP for a user to attend an event
  ///
  /// Automatically determines status (attending or waitlisted) based on capacity.
  /// If the event is at full capacity, the user will be added to the waitlist.
  ///
  /// Throws [EventValidationException] if eventId or userId is empty.
  /// Throws [EventNotFoundException] if the event doesn't exist.
  /// Throws [EventRsvpException] if user already has an RSVP or if RSVP creation fails.
  Future<RsvpEntity> attendEvent(String eventId, String userId) async {
    if (eventId.isEmpty) {
      throw EventValidationException('Event ID cannot be empty');
    }
    if (userId.isEmpty) {
      throw EventValidationException('User ID cannot be empty');
    }

    // Check if user already has an RSVP
    final existingRsvp = await getUserRsvp(eventId, userId);
    if (existingRsvp != null) {
      throw EventRsvpException('You have already RSVP\'d to this event');
    }

    // Fetch event to check capacity
    final event = await getEventById(eventId);

    // Determine initial status based on capacity
    final status =
        (event.capacity != null && event.attendeeCount >= event.capacity!)
        ? RsvpStatus.waitlisted
        : RsvpStatus.attending;

    return await _repository.createRsvp(
      eventId: eventId,
      userId: userId,
      status: status,
    );
  }

  /// Cancel a user's RSVP for an event
  ///
  /// Removes the RSVP and decrements attendeeCount if the user was attending.
  /// If the user was waitlisted, attendeeCount is not affected.
  ///
  /// Throws [EventValidationException] if eventId or userId is empty.
  /// Throws [EventRsvpException] if cancellation fails.
  Future<void> cancelAttendance(String eventId, String userId) async {
    if (eventId.isEmpty) {
      throw EventValidationException('Event ID cannot be empty');
    }
    if (userId.isEmpty) {
      throw EventValidationException('User ID cannot be empty');
    }

    await _repository.deleteRsvp(eventId: eventId, userId: userId);
  }

  /// Get a user's RSVP status for an event
  ///
  /// Returns the RsvpEntity if the user has RSVP'd, or null if they haven't.
  ///
  /// Throws [EventValidationException] if eventId or userId is empty.
  /// Returns null if user has not RSVP'd
  Future<RsvpEntity?> getUserRsvp(String eventId, String userId) async {
    if (eventId.isEmpty) {
      throw EventValidationException('Event ID cannot be empty');
    }
    if (userId.isEmpty) {
      throw EventValidationException('User ID cannot be empty');
    }

    return await _repository.getRsvp(eventId: eventId, userId: userId);
  }

  /// Upgrade a waitlisted user to attending status
  ///
  /// Changes the user's RSVP status from waitlisted to attending and increments
  /// the event's attendeeCount. This operation uses a Firestore transaction to
  /// ensure the event hasn't reached capacity.
  ///
  /// Throws [EventValidationException] if eventId or userId is empty.
  /// Throws [EventRsvpException] if event is at capacity or upgrade fails.
  Future<RsvpEntity> upgradeFromWaitlist(String eventId, String userId) async {
    if (eventId.isEmpty) {
      throw EventValidationException('Event ID cannot be empty');
    }
    if (userId.isEmpty) {
      throw EventValidationException('User ID cannot be empty');
    }

    // Fetch event to check capacity
    final event = await getEventById(eventId);

    // Check if capacity is available
    if (event.capacity != null && event.attendeeCount >= event.capacity!) {
      throw EventRsvpException('Event is at full capacity');
    }

    return await _repository.updateRsvp(
      eventId: eventId,
      userId: userId,
      newStatus: RsvpStatus.attending,
    );
  }
}
