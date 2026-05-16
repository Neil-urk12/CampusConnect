import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/rsvp_entity.dart';
import '../../domain/exceptions/event_exceptions.dart';
import '../models/event_model.dart';
import '../models/rsvp_model.dart';

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

  /// Stream all upcoming events (real-time updates)
  Stream<List<EventModel>> streamAllUpcomingEvents() {
    try {
      final now = DateTime.now();
      return _firestore
          .collection(_collectionName)
          .where('isPublished', isEqualTo: true)
          .where('startDateTime', isGreaterThanOrEqualTo: now)
          .orderBy('startDateTime')
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => EventModel.fromFirestore(doc))
                .toList(),
          );
    } catch (e) {
      throw EventNetworkException('Failed to stream upcoming events: $e');
    }
  }

  /// Stream events for a date range (real-time updates)
  Stream<List<EventModel>> streamEventsForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    try {
      return _firestore
          .collection(_collectionName)
          .where('isPublished', isEqualTo: true)
          .where('startDateTime', isGreaterThanOrEqualTo: startDate)
          .where('startDateTime', isLessThanOrEqualTo: endDate)
          .orderBy('startDateTime')
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => EventModel.fromFirestore(doc))
                .toList(),
          );
    } catch (e) {
      throw EventNetworkException('Failed to stream events for date range: $e');
    }
  }

  /// Stream a single event by ID (real-time updates)
  Stream<EventModel> streamEventById(String eventId) {
    try {
      return _firestore
          .collection(_collectionName)
          .doc(eventId)
          .snapshots()
          .map((doc) {
            if (!doc.exists) {
              throw EventNotFoundException(eventId);
            }
            return EventModel.fromFirestore(doc);
          });
    } catch (e) {
      if (e is EventNotFoundException) rethrow;
      throw EventNetworkException('Failed to stream event: $e');
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

  /// Create an RSVP for a user using a Firestore transaction
  /// Atomically checks capacity, creates RSVP, and updates attendeeCount
  ///
  /// Transaction ensures:
  /// - Read event document
  /// - Check capacity and determine status (attending or waitlisted)
  /// - Create RSVP document
  /// - Update attendeeCount only if status is attending
  Future<RsvpEntity> createRsvp({
    required String eventId,
    required String userId,
    required RsvpStatus status,
  }) async {
    try {
      return await _firestore.runTransaction<RsvpEntity>((transaction) async {
        // Read event document
        final eventRef = _firestore.collection(_collectionName).doc(eventId);
        final eventSnapshot = await transaction.get(eventRef);

        if (!eventSnapshot.exists) {
          throw EventNotFoundException(eventId);
        }

        final eventData = eventSnapshot.data()!;
        final capacity = eventData['capacity'] as int?;
        final attendeeCount = eventData['attendeeCount'] as int? ?? 0;

        // Determine RSVP status based on capacity
        RsvpStatus finalStatus = status;
        if (capacity != null && attendeeCount >= capacity) {
          finalStatus = RsvpStatus.waitlisted;
        }

        // Create RSVP document
        final now = DateTime.now();
        final rsvpModel = RsvpModel(
          userId: userId,
          eventId: eventId,
          status: finalStatus,
          createdAt: now,
          updatedAt: now,
        );

        final rsvpRef = eventRef.collection('rsvps').doc(userId);
        transaction.set(rsvpRef, rsvpModel.toFirestore());

        // Update attendeeCount only if status is attending
        if (finalStatus == RsvpStatus.attending) {
          transaction.update(eventRef, {'attendeeCount': attendeeCount + 1});
        }

        return rsvpModel;
      });
    } catch (e) {
      if (e is EventNotFoundException) rethrow;
      throw EventRsvpException('Failed to create RSVP: $e');
    }
  }

  /// Delete an RSVP using a Firestore transaction
  /// Atomically deletes RSVP and decrements attendeeCount if user was attending
  ///
  /// Transaction ensures:
  /// - Read RSVP to check status
  /// - Delete RSVP document
  /// - Decrement attendeeCount only if status was attending
  Future<void> deleteRsvp({
    required String eventId,
    required String userId,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final eventRef = _firestore.collection(_collectionName).doc(eventId);
        final rsvpRef = eventRef.collection('rsvps').doc(userId);

        // Read RSVP to check status
        final rsvpSnapshot = await transaction.get(rsvpRef);
        if (!rsvpSnapshot.exists) {
          return; // RSVP doesn't exist, nothing to delete
        }

        final rsvpData = rsvpSnapshot.data()!;
        final status = RsvpStatus.values.firstWhere(
          (e) => e.name == rsvpData['status'],
        );

        // Delete RSVP document
        transaction.delete(rsvpRef);

        // Decrement attendeeCount only if user was attending
        if (status == RsvpStatus.attending) {
          final eventSnapshot = await transaction.get(eventRef);
          if (eventSnapshot.exists) {
            final attendeeCount =
                eventSnapshot.data()!['attendeeCount'] as int? ?? 0;
            transaction.update(eventRef, {
              'attendeeCount': attendeeCount > 0 ? attendeeCount - 1 : 0,
            });
          }
        }
      });
    } catch (e) {
      throw EventRsvpException('Failed to delete RSVP: $e');
    }
  }

  /// Get a user's RSVP for an event
  Future<RsvpEntity?> getRsvp({
    required String eventId,
    required String userId,
  }) async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(eventId)
          .collection('rsvps')
          .doc(userId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return RsvpModel.fromFirestore(doc);
    } catch (e) {
      throw EventRsvpException('Failed to fetch RSVP: $e');
    }
  }

  /// Update an RSVP status (for waitlist upgrade) using a Firestore transaction
  /// Atomically checks capacity, updates RSVP status, and increments attendeeCount
  ///
  /// Transaction ensures:
  /// - Read event and RSVP documents
  /// - Check capacity if upgrading to attending
  /// - Update RSVP status
  /// - Increment attendeeCount if upgrading from waitlisted to attending
  Future<RsvpEntity> updateRsvp({
    required String eventId,
    required String userId,
    required RsvpStatus newStatus,
  }) async {
    try {
      return await _firestore.runTransaction<RsvpEntity>((transaction) async {
        final eventRef = _firestore.collection(_collectionName).doc(eventId);
        final rsvpRef = eventRef.collection('rsvps').doc(userId);

        // Read event and RSVP
        final eventSnapshot = await transaction.get(eventRef);
        final rsvpSnapshot = await transaction.get(rsvpRef);

        if (!eventSnapshot.exists) {
          throw EventNotFoundException(eventId);
        }

        if (!rsvpSnapshot.exists) {
          throw EventRsvpException('RSVP not found for user $userId');
        }

        final eventData = eventSnapshot.data()!;
        final capacity = eventData['capacity'] as int?;
        final attendeeCount = eventData['attendeeCount'] as int? ?? 0;

        // Check capacity if upgrading to attending
        if (newStatus == RsvpStatus.attending) {
          if (capacity != null && attendeeCount >= capacity) {
            throw EventRsvpException('Event is at full capacity');
          }
        }

        final rsvpData = rsvpSnapshot.data()!;
        final oldStatus = RsvpStatus.values.firstWhere(
          (e) => e.name == rsvpData['status'],
        );

        // Update RSVP document
        final updatedRsvp = RsvpModel(
          userId: userId,
          eventId: eventId,
          status: newStatus,
          createdAt: (rsvpData['createdAt'] as Timestamp).toDate(),
          updatedAt: DateTime.now(),
        );

        transaction.update(rsvpRef, updatedRsvp.toFirestore());

        // Update attendeeCount if status changed from waitlisted to attending
        if (oldStatus == RsvpStatus.waitlisted &&
            newStatus == RsvpStatus.attending) {
          transaction.update(eventRef, {'attendeeCount': attendeeCount + 1});
        }

        return updatedRsvp;
      });
    } catch (e) {
      if (e is EventNotFoundException || e is EventRsvpException) rethrow;
      throw EventRsvpException('Failed to update RSVP: $e');
    }
  }
}
