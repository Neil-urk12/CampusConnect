import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../providers/auth_providers.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/entities/rsvp_entity.dart';
import '../../domain/exceptions/event_exceptions.dart';
import '../../providers/event_providers.dart';
import 'event_form_screen.dart';

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
      color: _getCategoryColor(category).withValues(alpha: 0.2),
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

  /// Build action button based on user's RSVP status and event capacity
  Widget _buildActionButton(
    BuildContext context,
    WidgetRef ref,
    EventEntity event,
    RsvpEntity? userRsvp,
    bool isAuthenticated,
  ) {
    // Unauthenticated users
    if (!isAuthenticated) {
      return _buildButton(
        context,
        label: 'Sign in to RSVP',
        onPressed: () {
          Navigator.pushNamed(context, '/login');
        },
        style: _ButtonStyle.outlined,
      );
    }

    final isFull =
        event.capacity != null && event.attendeeCount >= event.capacity!;

    // User has no RSVP
    if (userRsvp == null) {
      if (isFull) {
        // No RSVP + full capacity -> Join Waitlist
        return _buildButton(
          context,
          label: 'Join Waitlist',
          onPressed: () => _attendEvent(context, ref, event.id),
          style: _ButtonStyle.secondary,
        );
      } else {
        // No RSVP + capacity available -> Attend Event
        return _buildButton(
          context,
          label: 'Attend Event',
          onPressed: () => _attendEvent(context, ref, event.id),
          style: _ButtonStyle.primary,
        );
      }
    }

    // User has RSVP
    if (userRsvp.status == RsvpStatus.attending) {
      // Attending -> Cancel Attendance
      return _buildButton(
        context,
        label: 'Cancel Attendance',
        onPressed: () => _cancelAttendance(context, ref, event.id),
        style: _ButtonStyle.outlined,
      );
    } else {
      // Waitlisted
      if (isFull) {
        // Waitlisted + full capacity -> Leave Waitlist
        return _buildButton(
          context,
          label: 'Leave Waitlist',
          onPressed: () => _cancelAttendance(context, ref, event.id),
          style: _ButtonStyle.outlined,
        );
      } else {
        // Waitlisted + capacity available -> Attend Now
        return _buildButton(
          context,
          label: 'Attend Now',
          onPressed: () => _upgradeFromWaitlist(context, ref, event.id),
          style: _ButtonStyle.primary,
        );
      }
    }
  }

  /// Attend event handler
  Future<void> _attendEvent(
    BuildContext context,
    WidgetRef ref,
    String eventId,
  ) async {
    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) return;

      final service = ref.read(eventServiceProvider);
      final rsvp = await service.attendEvent(eventId, currentUser.userId);

      if (context.mounted) {
        final message = rsvp.status == RsvpStatus.attending
            ? 'You\'re attending this event!'
            : 'You\'ve been added to the waitlist';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        // Invalidate the RSVP provider to refresh the button state
        ref.invalidate(userRsvpProvider(eventId));
      }
    } on EventRsvpException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to RSVP. Please try again.')),
        );
      }
    }
  }

  /// Cancel attendance handler
  Future<void> _cancelAttendance(
    BuildContext context,
    WidgetRef ref,
    String eventId,
  ) async {
    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) return;

      final service = ref.read(eventServiceProvider);
      await service.cancelAttendance(eventId, currentUser.userId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your RSVP has been cancelled')),
        );
        // Invalidate the RSVP provider to refresh the button state
        ref.invalidate(userRsvpProvider(eventId));
      }
    } on EventRsvpException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to cancel RSVP. Please try again.'),
          ),
        );
      }
    }
  }

  /// Upgrade from waitlist handler
  Future<void> _upgradeFromWaitlist(
    BuildContext context,
    WidgetRef ref,
    String eventId,
  ) async {
    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) return;

      final service = ref.read(eventServiceProvider);
      await service.upgradeFromWaitlist(eventId, currentUser.userId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You\'re now attending this event!')),
        );
        // Invalidate the RSVP provider to refresh the button state
        ref.invalidate(userRsvpProvider(eventId));
      }
    } on EventRsvpException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to upgrade from waitlist. Please try again.'),
          ),
        );
      }
    }
  }

  /// Delete event handler (admin only)
  Future<void> _deleteEvent(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text(
          'Are you sure you want to delete this event? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final service = ref.read(eventServiceProvider);
      await service.deleteEvent(eventId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event deleted successfully')),
        );
        Navigator.pop(context); // Go back to events list
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete event: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use stream provider for real-time updates
    final eventAsync = ref.watch(eventStreamProvider(eventId));
    final userRsvpAsync = ref.watch(userRsvpProvider(eventId));
    final currentUser = ref.watch(currentUserProvider);

    final isAdmin = ref.watch(isAdminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
        actions: isAdmin
            ? [
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      final event = eventAsync.value;
                      if (event != null) {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EventFormScreen(event: event),
                          ),
                        );
                        if (result == true) {
                          // Refresh event data
                          ref.invalidate(eventByIdProvider(eventId));
                        }
                      }
                    } else if (value == 'delete') {
                      _deleteEvent(context, ref);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit Event'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Delete Event',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ]
            : null,
      ),
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
                        ).withValues(alpha: 0.2),
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

                    // RSVP Action Button
                    userRsvpAsync.when(
                      data: (userRsvp) => _buildActionButton(
                        context,
                        ref,
                        event,
                        userRsvp,
                        currentUser != null,
                      ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => _buildActionButton(
                        context,
                        ref,
                        event,
                        null,
                        currentUser != null,
                      ),
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

  /// Build styled button with design tokens
  Widget _buildButton(
    BuildContext context, {
    required String label,
    required VoidCallback onPressed,
    required _ButtonStyle style,
  }) {
    return SizedBox(
      width: double.infinity,
      child: AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 100),
        child: ElevatedButton(
          onPressed: onPressed,
          style: _getButtonStyle(context, style),
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.spacing16),
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  ButtonStyle _getButtonStyle(BuildContext context, _ButtonStyle style) {
    switch (style) {
      case _ButtonStyle.primary:
        return ElevatedButton.styleFrom(
          backgroundColor: DesignTokens.primary,
          foregroundColor: DesignTokens.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
          ),
          elevation: 0,
        );
      case _ButtonStyle.secondary:
        return ElevatedButton.styleFrom(
          backgroundColor: DesignTokens.secondaryContainer,
          foregroundColor: DesignTokens.onSecondaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
          ),
          elevation: 0,
        );
      case _ButtonStyle.outlined:
        return OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: DesignTokens.primary,
          side: const BorderSide(color: DesignTokens.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
          ),
        );
    }
  }
}

enum _ButtonStyle { primary, secondary, outlined }
