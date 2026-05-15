import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/entities/rsvp_entity.dart';
import '../../domain/repositories/event_repository.dart';
import '../datasources/firestore_event_datasource.dart';
import '../models/event_model.dart';

class EventRepositoryImpl implements EventRepository {
  final FirestoreEventDataSource _dataSource;

  EventRepositoryImpl({required FirestoreEventDataSource dataSource})
    : _dataSource = dataSource;

  @override
  Future<List<EventEntity>> getEventsForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      AppLogger.debug('Fetching events for date range: $startDate to $endDate');
      final events = await _dataSource.getEventsForDateRange(
        startDate,
        endDate,
      );
      AppLogger.debug('Fetched ${events.length} events');
      return events;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to fetch events for date range',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<EventEntity> getEventById(String eventId) async {
    try {
      AppLogger.debug('Fetching event by ID: $eventId');
      final event = await _dataSource.getEventById(eventId);
      AppLogger.debug('Fetched event: ${event.title}');
      return event;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to fetch event by ID: $eventId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<List<EventEntity>> getAllUpcomingEvents() async {
    try {
      AppLogger.debug('Fetching all upcoming events');
      final events = await _dataSource.getAllUpcomingEvents();
      AppLogger.debug('Fetched ${events.length} upcoming events');
      return events;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to fetch upcoming events',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> createEvent(EventEntity event) async {
    try {
      AppLogger.info('Creating event: ${event.title}');
      final model = EventModel.fromEntity(event);
      await _dataSource.createEvent(model);
      AppLogger.info('Event created successfully: ${event.id}');
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to create event: ${event.title}',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> updateEvent(EventEntity event) async {
    try {
      AppLogger.info('Updating event: ${event.title}');
      final model = EventModel.fromEntity(event);
      await _dataSource.updateEvent(model);
      AppLogger.info('Event updated successfully: ${event.id}');
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to update event: ${event.title}',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteEvent(String eventId) async {
    try {
      AppLogger.info('Deleting event: $eventId');
      await _dataSource.deleteEvent(eventId);
      AppLogger.info('Event deleted successfully: $eventId');
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to delete event: $eventId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<RsvpEntity> createRsvp({
    required String eventId,
    required String userId,
    required RsvpStatus status,
  }) async {
    try {
      AppLogger.info('Creating RSVP for user $userId on event $eventId');
      final rsvp = await _dataSource.createRsvp(
        eventId: eventId,
        userId: userId,
        status: status,
      );
      AppLogger.info('RSVP created successfully: ${rsvp.status.name}');
      return rsvp;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to create RSVP for user $userId on event $eventId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteRsvp({
    required String eventId,
    required String userId,
  }) async {
    try {
      AppLogger.info('Deleting RSVP for user $userId on event $eventId');
      await _dataSource.deleteRsvp(eventId: eventId, userId: userId);
      AppLogger.info('RSVP deleted successfully');
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to delete RSVP for user $userId on event $eventId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<RsvpEntity?> getRsvp({
    required String eventId,
    required String userId,
  }) async {
    try {
      AppLogger.debug('Fetching RSVP for user $userId on event $eventId');
      final rsvp = await _dataSource.getRsvp(eventId: eventId, userId: userId);
      if (rsvp != null) {
        AppLogger.debug('RSVP found: ${rsvp.status.name}');
      } else {
        AppLogger.debug('No RSVP found');
      }
      return rsvp;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to fetch RSVP for user $userId on event $eventId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<RsvpEntity> updateRsvp({
    required String eventId,
    required String userId,
    required RsvpStatus newStatus,
  }) async {
    try {
      AppLogger.info(
        'Updating RSVP for user $userId on event $eventId to ${newStatus.name}',
      );
      final rsvp = await _dataSource.updateRsvp(
        eventId: eventId,
        userId: userId,
        newStatus: newStatus,
      );
      AppLogger.info('RSVP updated successfully');
      return rsvp;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to update RSVP for user $userId on event $eventId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
