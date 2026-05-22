import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth_providers.dart';
import '../application/event_service.dart';
import '../data/datasources/firestore_event_datasource.dart';
import '../data/repositories/event_repository_impl.dart';
import '../domain/entities/event_entity.dart';
import '../domain/entities/rsvp_entity.dart';
import '../domain/repositories/event_repository.dart';

// Datasource provider
final firestoreEventDataSourceProvider = Provider<FirestoreEventDataSource>((
  ref,
) {
  return FirestoreEventDataSource(firestore: FirebaseFirestore.instance);
});

// Repository provider
final eventRepositoryProvider = Provider<EventRepository>((ref) {
  final dataSource = ref.watch(firestoreEventDataSourceProvider);
  return EventRepositoryImpl(dataSource: dataSource);
});

// Service provider
final eventServiceProvider = Provider<EventService>((ref) {
  final repository = ref.watch(eventRepositoryProvider);
  return EventService(repository: repository);
});

// Provider for fetching events by month
final eventsForMonthProvider =
    FutureProvider.family<List<EventEntity>, DateTime>((ref, month) async {
      final service = ref.watch(eventServiceProvider);
      return await service.getEventsForMonth(month);
    });

// Provider for fetching single event by ID
final eventByIdProvider = FutureProvider.family<EventEntity, String>((
  ref,
  eventId,
) async {
  final service = ref.watch(eventServiceProvider);
  return await service.getEventById(eventId);
});

// Provider for streaming single event by ID (real-time updates)
final eventStreamProvider = StreamProvider.family<EventEntity, String>((
  ref,
  eventId,
) {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.streamEventById(eventId);
});

// Provider for fetching all upcoming events
final allUpcomingEventsProvider = FutureProvider<List<EventEntity>>((
  ref,
) async {
  final service = ref.watch(eventServiceProvider);
  return await service.getAllUpcomingEvents();
});

// Provider for streaming all upcoming events (real-time updates)
final upcomingEventsStreamProvider = StreamProvider<List<EventEntity>>((ref) {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.streamAllUpcomingEvents();
});

// Provider for fetching user's RSVP status for an event
final userRsvpProvider = FutureProvider.family<RsvpEntity?, String>((
  ref,
  eventId,
) async {
  final currentUser = ref.watch(currentUserProvider);

  // Return null if user is not authenticated
  if (currentUser == null) {
    return null;
  }

  final service = ref.watch(eventServiceProvider);
  return await service.getUserRsvp(eventId, currentUser.userId);
});

// State class for event screen
class EventScreenState {
  final DateTime? selectedDate;
  final EventCategory? selectedCategory;
  final List<EventEntity> filteredEvents;
  final bool isLoading;
  final String? errorMessage;

  const EventScreenState({
    this.selectedDate,
    this.selectedCategory,
    this.filteredEvents = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  EventScreenState copyWith({
    DateTime? selectedDate,
    EventCategory? selectedCategory,
    List<EventEntity>? filteredEvents,
    bool? isLoading,
    String? errorMessage,
  }) {
    return EventScreenState(
      selectedDate: selectedDate ?? this.selectedDate,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      filteredEvents: filteredEvents ?? this.filteredEvents,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  EventScreenState clearFilters() {
    return const EventScreenState();
  }
}

// EventStateNotifier for managing selected date, category, and filtered events
class EventStateNotifier extends Notifier<EventScreenState> {
  StreamSubscription<List<EventEntity>>? _eventsSubscription;
  List<EventEntity> _allEvents = [];

  @override
  EventScreenState build() {
    // Subscribe to upcoming events stream for real-time updates
    _subscribeToUpcomingEvents();
    ref.onDispose(() {
      _eventsSubscription?.cancel();
    });
    return const EventScreenState();
  }

  void _subscribeToUpcomingEvents() {
    final repository = ref.read(eventRepositoryProvider);
    _eventsSubscription = repository.streamAllUpcomingEvents().listen(
      (events) {
        _allEvents = events;
        // Only update if we're showing all events (no date filter)
        if (state.selectedDate == null) {
          state = state.copyWith(
            filteredEvents: _applyCategoryFilter(events),
            isLoading: false,
          );
        }
      },
      onError: (e) {
        state = state.copyWith(errorMessage: e.toString());
      },
    );
  }

  List<EventEntity> _applyCategoryFilter(List<EventEntity> events) {
    final category = state.selectedCategory;
    if (category == null) return events;
    return events.where((e) => e.category == category).toList();
  }

  void selectDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  void selectCategory(EventCategory? category) {
    state = state.copyWith(selectedCategory: category);
    if (state.selectedDate == null) {
      // Apply category filter to cached events, or reload if we have none
      if (_allEvents.isNotEmpty) {
        state = state.copyWith(
          filteredEvents: _applyCategoryFilter(_allEvents),
        );
      } else {
        loadAllUpcomingEvents();
      }
    } else {
      // Reload events for the selected date with category filter
      loadEventsForDate(state.selectedDate!);
    }
  }

  void clearDateFilter() {
    state = state.copyWith(
      selectedDate: null,
      selectedCategory: null,
      filteredEvents: [],
    );
    loadAllUpcomingEvents();
  }

  Future<void> loadEventsForDate(DateTime date) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repository = ref.read(eventRepositoryProvider);
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      final events = await repository.getEventsForDateRange(
        startOfDay,
        endOfDay,
      );
      state = state.copyWith(
        filteredEvents: _applyCategoryFilter(events),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> loadAllUpcomingEvents() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final service = ref.read(eventServiceProvider);
      final events = await service.getAllUpcomingEvents();
      _allEvents = events;
      state = state.copyWith(
        filteredEvents: _applyCategoryFilter(events),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

// Provider for EventStateNotifier
final eventStateNotifierProvider =
    NotifierProvider<EventStateNotifier, EventScreenState>(() {
      return EventStateNotifier();
    });
