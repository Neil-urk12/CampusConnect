import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/event_entity.dart';
import '../../providers/event_providers.dart';

class EventDetailScreen extends ConsumerWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  Color _getCategoryColor(EventCategory category) {
    switch (category) {
      case EventCategory.academic:
        return Colors.blue;
      case EventCategory.social:
        return Colors.purple;
      case EventCategory.sports:
        return Colors.green;
      case EventCategory.career:
        return Colors.orange;
    }
  }

  String _getCategoryLabel(EventCategory category) {
    switch (category) {
      case EventCategory.academic:
        return 'Academic';
      case EventCategory.social:
        return 'Social';
      case EventCategory.sports:
        return 'Sports';
      case EventCategory.career:
        return 'Career';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('EEEE, MMMM d, y • h:mm a').format(dateTime);
  }

  String _formatDateTimeRange(DateTime start, DateTime? end) {
    if (end == null) {
      return 'Starts at ${DateFormat('h:mm a').format(start)}';
    }
    return '${DateFormat('h:mm a').format(start)} - ${DateFormat('h:mm a').format(end)}';
  }

  String _formatAttendance(EventEntity event) {
    if (event.capacity != null) {
      if (event.attendeeCount >= event.capacity!) {
        return 'Full (${event.attendeeCount}/${event.capacity})';
      }
      return '${event.attendeeCount}/${event.capacity} attending';
    }
    return '${event.attendeeCount} attending';
  }

  Widget _buildCategoryPlaceholder(
    BuildContext context,
    EventCategory category,
  ) {
    return Container(
      height: 200,
      color: _getCategoryColor(category).withOpacity(0.2),
      child: Center(
        child: Icon(
          _getCategoryIcon(category),
          size: 80,
          color: _getCategoryColor(category),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(EventCategory category) {
    switch (category) {
      case EventCategory.academic:
        return Icons.school;
      case EventCategory.social:
        return Icons.people;
      case EventCategory.sports:
        return Icons.sports;
      case EventCategory.career:
        return Icons.work;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventByIdProvider(eventId));

    return Scaffold(
      appBar: AppBar(title: const Text('Event Details')),
      body: eventAsync.when(
        data: (event) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event image or placeholder
              if (event.imageUrl != null)
                Image.network(
                  event.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildCategoryPlaceholder(context, event.category);
                  },
                )
              else
                _buildCategoryPlaceholder(context, event.category),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(
                          event.category,
                        ).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _getCategoryLabel(event.category),
                        style: TextStyle(
                          color: _getCategoryColor(event.category),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    Text(
                      event.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Date/Time
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatDateTime(event.startDateTime),
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              Text(
                                _formatDateTimeRange(
                                  event.startDateTime,
                                  event.endDateTime,
                                ),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.color,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            event.location,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Attendance
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatAttendance(event),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Description
                    Text(
                      'About',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),

                    // Creator
                    Text(
                      'Organized by',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.createdByName,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Error loading event: $error')),
      ),
    );
  }
}
