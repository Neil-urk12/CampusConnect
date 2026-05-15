import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/event_service.dart';
import '../data/datasources/firestore_event_datasource.dart';
import '../data/repositories/event_repository_impl.dart';
import '../domain/entities/event_entity.dart';
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

// Provider for fetching all upcoming events
final allUpcomingEventsProvider = FutureProvider<List<EventEntity>>((
  ref,
) async {
  final service = ref.watch(eventServiceProvider);
  return await service.getAllUpcomingEvents();
});

// State class for event screen
class EventScreenState {
  final DateTime? selectedDate;
  final List<EventEntity> filteredEvents;
  final bool isLoading;
  final String? errorMessage;

  const EventScreenState({
    this.selectedDate,
    this.filteredEvents = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  EventScreenState copyWith({
    DateTime? selectedDate,
    List<EventEntity>? filteredEvents,
    bool? isLoading,
    String? errorMessage,
  }) {
    return EventScreenState(
      selectedDate: selectedDate ?? this.selectedDate,
      filteredEvents: filteredEvents ?? this.filteredEvents,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// EventStateNotifier for managing selected date and filtered events
class EventStateNotifier extends Notifier<EventScreenState> {
  @override
  EventScreenState build() {
    return const EventScreenState();
  }

  void selectDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  void clearDateFilter() {
    state = state.copyWith(selectedDate: null, filteredEvents: []);
  }

  Future<void> loadEventsForDate(DateTime date) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final service = ref.read(eventServiceProvider);
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      final events = await service.getEventsForDateRange(startOfDay, endOfDay);
      state = state.copyWith(filteredEvents: events, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> loadAllUpcomingEvents() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final service = ref.read(eventServiceProvider);
      final events = await service.getAllUpcomingEvents();
      state = state.copyWith(filteredEvents: events, isLoading: false);
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
