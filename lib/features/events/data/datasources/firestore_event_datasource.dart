import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/exceptions/event_exceptions.dart';
import '../models/event_model.dart';

class FirestoreEventDataSource {
  final FirebaseFirestore _firestore;
  static const String _collectionName = 'events';

  FirestoreEventDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get events within a date range (for calendar month filtering)
  Future<List<EventModel>> getEventsForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('isPublished', isEqualTo: true)
          .where('startDateTime', isGreaterThanOrEqualTo: startDate)
          .where('startDateTime', isLessThanOrEqualTo: endDate)
          .orderBy('startDateTime')
          .get();

      return querySnapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw EventNetworkException('Failed to fetch events for date range: $e');
    }
  }

  /// Get a single event by ID
  Future<EventModel> getEventById(String eventId) async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(eventId)
          .get();

      if (!doc.exists) {
        throw EventNotFoundException(eventId);
      }

      return EventModel.fromFirestore(doc);
    } catch (e) {
      if (e is EventNotFoundException) rethrow;
      throw EventNetworkException('Failed to fetch event: $e');
    }
  }

  /// Get all upcoming events (startDateTime >= now)
  Future<List<EventModel>> getAllUpcomingEvents() async {
    try {
      final now = DateTime.now();
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('isPublished', isEqualTo: true)
          .where('startDateTime', isGreaterThanOrEqualTo: now)
          .orderBy('startDateTime')
          .get();

      return querySnapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw EventNetworkException('Failed to fetch upcoming events: $e');
    }
  }

  /// Create a new event
  Future<void> createEvent(EventModel event) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(event.id)
          .set(event.toFirestore());
    } catch (e) {
      throw EventNetworkException('Failed to create event: $e');
    }
  }

  /// Update an existing event
  Future<void> updateEvent(EventModel event) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(event.id)
          .update(event.toFirestore());
    } catch (e) {
      throw EventNetworkException('Failed to update event: $e');
    }
  }

  /// Delete an event
  Future<void> deleteEvent(String eventId) async {
    try {
      // Delete the event document
      await _firestore.collection(_collectionName).doc(eventId).delete();

      // Delete all RSVPs in the subcollection
      final rsvpsSnapshot = await _firestore
          .collection(_collectionName)
          .doc(eventId)
          .collection('rsvps')
          .get();

      final batch = _firestore.batch();
      for (final doc in rsvpsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw EventNetworkException('Failed to delete event: $e');
    }
  }
}
