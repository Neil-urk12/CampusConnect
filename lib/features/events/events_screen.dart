import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/event_providers.dart';
import 'presentation/widgets/event_card.dart';
import 'domain/entities/event_entity.dart';
import '../../core/theme/design_tokens.dart';

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<dynamic>> _events = {};
  EventCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadEventsForMonth(_focusedDay);
  }

  Future<void> _loadEventsForMonth(DateTime month) async {
    try {
      final service = ref.read(eventServiceProvider);
      final events = await service.getEventsForMonth(month);

      final Map<DateTime, List<dynamic>> eventMap = {};
      for (final event in events) {
        final date = DateTime(
          event.startDateTime.year,
          event.startDateTime.month,
          event.startDateTime.day,
        );
        if (eventMap[date] == null) {
          eventMap[date] = [];
        }
        eventMap[date]!.add(event);
      }

      setState(() {
        _events = eventMap;
      });
    } catch (e) {
      // Handle error silently for now
    }
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  void _onCategorySelected(EventCategory? category) {
    setState(() {
      _selectedCategory = category;
    });
    if (category == null) {
      ref.read(eventStateNotifierProvider.notifier).loadAllUpcomingEvents();
    } else {
      // Filter by category - would need to add this to provider
      ref.read(eventStateNotifierProvider.notifier).loadAllUpcomingEvents();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Calendar section - Surface hierarchy: surface-container-lowest on surface-container-low
              Container(
                margin: const EdgeInsets.all(DesignTokens.spacing16),
                decoration: BoxDecoration(
                  color: DesignTokens.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
                ),
                child: Container(
                  margin: const EdgeInsets.all(DesignTokens.spacing8),
                  padding: const EdgeInsets.all(DesignTokens.spacing24),
                  decoration: BoxDecoration(
                    color: DesignTokens.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                    boxShadow: [DesignTokens.ambientShadow()],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with month/year and nav arrows
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ACADEMIC YEAR ${_focusedDay.year}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                    color: DesignTokens.secondary,
                                  ),
                                ),
                                const SizedBox(height: DesignTokens.spacing4),
                                Text(
                                  DateFormat('MMMM').format(_focusedDay),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 44, // display-md: 2.75rem
                                    fontWeight: FontWeight.w800,
                                    color: DesignTokens.primary,
                                    height: 1.1,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              _buildNavButton(Icons.chevron_left, () {
                                setState(() {
                                  _focusedDay = DateTime(
                                    _focusedDay.year,
                                    _focusedDay.month - 1,
                                  );
                                });
                                _loadEventsForMonth(_focusedDay);
                              }),
                              const SizedBox(width: DesignTokens.spacing8),
                              _buildNavButton(Icons.chevron_right, () {
                                setState(() {
                                  _focusedDay = DateTime(
                                    _focusedDay.year,
                                    _focusedDay.month + 1,
                                  );
                                });
                                _loadEventsForMonth(_focusedDay);
                              }),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: DesignTokens.spacing20),
                      // Calendar
                      TableCalendar(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        calendarFormat: CalendarFormat.month,
                        selectedDayPredicate: (day) {
                          return isSameDay(_selectedDay, day);
                        },
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                          ref
                              .read(eventStateNotifierProvider.notifier)
                              .selectDate(selectedDay);
                          ref
                              .read(eventStateNotifierProvider.notifier)
                              .loadEventsForDate(selectedDay);
                        },
                        onPageChanged: (focusedDay) {
                          setState(() {
                            _focusedDay = focusedDay;
                          });
                          _loadEventsForMonth(focusedDay);
                        },
                        eventLoader: _getEventsForDay,
                        headerVisible: false,
                        daysOfWeekHeight: 40,
                        rowHeight: 48,
                        daysOfWeekStyle: DaysOfWeekStyle(
                          weekdayStyle: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: DesignTokens.onSurfaceVariant,
                            letterSpacing: 0.5,
                          ),
                          weekendStyle: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: DesignTokens.onSurfaceVariant,
                            letterSpacing: 0.5,
                          ),
                        ),
                        calendarStyle: CalendarStyle(
                          cellMargin: const EdgeInsets.all(
                            DesignTokens.spacing4,
                          ),
                          defaultTextStyle: GoogleFonts.manrope(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: DesignTokens.onSurface,
                          ),
                          weekendTextStyle: GoogleFonts.manrope(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: DesignTokens.onSurface,
                          ),
                          outsideTextStyle: GoogleFonts.manrope(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: DesignTokens.onSurface.withValues(
                              alpha: 0.3,
                            ),
                          ),
                          todayDecoration: BoxDecoration(
                            color: DesignTokens.secondaryContainer.withValues(
                              alpha: 0.3,
                            ),
                            shape: BoxShape.circle,
                          ),
                          todayTextStyle: GoogleFonts.manrope(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: DesignTokens.onSecondaryContainer,
                          ),
                          selectedDecoration: BoxDecoration(
                            gradient: DesignTokens.primaryGradient(),
                            shape: BoxShape.circle,
                          ),
                          selectedTextStyle: GoogleFonts.manrope(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: DesignTokens.onPrimary,
                          ),
                          markerDecoration: const BoxDecoration(
                            color: DesignTokens.secondary,
                            shape: BoxShape.circle,
                          ),
                          markerSize: 6,
                          markersMaxCount: 1,
                          markersAlignment: Alignment.bottomCenter,
                          markerMargin: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Filter chips
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacing16,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        'All Events',
                        _selectedCategory == null,
                        () {
                          _onCategorySelected(null);
                        },
                      ),
                      const SizedBox(width: DesignTokens.spacing8),
                      _buildFilterChip(
                        'Academic',
                        _selectedCategory == EventCategory.academic,
                        () => _onCategorySelected(EventCategory.academic),
                      ),
                      const SizedBox(width: DesignTokens.spacing8),
                      _buildFilterChip(
                        'Social',
                        _selectedCategory == EventCategory.social,
                        () => _onCategorySelected(EventCategory.social),
                      ),
                      const SizedBox(width: DesignTokens.spacing8),
                      _buildFilterChip(
                        'Sports',
                        _selectedCategory == EventCategory.sports,
                        () => _onCategorySelected(EventCategory.sports),
                      ),
                      const SizedBox(width: DesignTokens.spacing8),
                      _buildFilterChip(
                        'Career',
                        _selectedCategory == EventCategory.career,
                        () => _onCategorySelected(EventCategory.career),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.spacing20),
              // Upcoming Events header - Asymmetrical margins (editorial rhythm)
              Padding(
                padding: const EdgeInsets.only(
                  left: DesignTokens.spacing24,
                  right: DesignTokens.spacing16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Upcoming Events',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22, // title-lg: 1.375rem
                        fontWeight: FontWeight.w800,
                        color: DesignTokens.primary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedDay = null;
                          _selectedCategory = null;
                        });
                        ref
                            .read(eventStateNotifierProvider.notifier)
                            .clearDateFilter();
                        ref
                            .read(eventStateNotifierProvider.notifier)
                            .loadAllUpcomingEvents();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.spacing12,
                          vertical: DesignTokens.spacing8,
                        ),
                      ),
                      child: Text(
                        'See Schedule',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: DesignTokens.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DesignTokens.spacing12),
              // Events list - shrinkWrap + NeverScrollableScrollPhysics
              Consumer(
                builder: (context, ref, child) {
                  final state = ref.watch(eventStateNotifierProvider);

                  if (state.isLoading) {
                    return const Padding(
                      padding: EdgeInsets.all(DesignTokens.spacing32),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: DesignTokens.secondary,
                        ),
                      ),
                    );
                  }

                  if (state.errorMessage != null) {
                    return Padding(
                      padding: const EdgeInsets.all(DesignTokens.spacing32),
                      child: Center(
                        child: Text(
                          'Error: ${state.errorMessage}',
                          style: GoogleFonts.manrope(color: DesignTokens.error),
                        ),
                      ),
                    );
                  }

                  if (state.filteredEvents.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(DesignTokens.spacing32),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_busy_rounded,
                              size: 64,
                              color: DesignTokens.onSurface.withValues(
                                alpha: 0.2,
                              ),
                            ),
                            const SizedBox(height: DesignTokens.spacing16),
                            Text(
                              'No events for selected date',
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                color: DesignTokens.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(
                      left: DesignTokens.spacing16,
                      right: DesignTokens.spacing16,
                      bottom: DesignTokens.spacing24,
                    ),
                    itemCount: state.filteredEvents.length,
                    itemBuilder: (context, index) {
                      final event = state.filteredEvents[index];
                      return EventCard(
                        event: event,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/events/detail',
                            arguments: event.id,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      ),
      child: IconButton(
        icon: Icon(icon, color: DesignTokens.surfaceTint, size: 20),
        onPressed: onPressed,
        padding: const EdgeInsets.all(DesignTokens.spacing8),
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacing20,
          vertical: DesignTokens.spacing12,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? DesignTokens.secondaryContainer
              : DesignTokens.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? DesignTokens.onSecondaryContainer
                : DesignTokens.onSurface,
          ),
        ),
      ),
    );
  }
}
