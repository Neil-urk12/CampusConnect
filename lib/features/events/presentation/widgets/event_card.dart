import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/event_entity.dart';
import '../../../../core/theme/design_tokens.dart';

class EventCard extends StatefulWidget {
  final EventEntity event;
  final VoidCallback? onTap;

  const EventCard({super.key, required this.event, this.onTap});

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  bool _isPressed = false;

  Color _getCategoryColor(EventCategory category) {
    switch (category) {
      case EventCategory.academic:
        return DesignTokens.categoryAcademic;
      case EventCategory.social:
        return DesignTokens.categorySocial;
      case EventCategory.sports:
        return DesignTokens.categorySports;
      case EventCategory.career:
        return DesignTokens.categoryCareer;
    }
  }

  String _getCategoryLabel(EventCategory category) {
    switch (category) {
      case EventCategory.academic:
        return 'ACADEMIC';
      case EventCategory.social:
        return 'SOCIAL';
      case EventCategory.sports:
        return 'SPORTS';
      case EventCategory.career:
        return 'CAREER';
    }
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  String _formatAttendance() {
    if (widget.event.capacity != null) {
      return '${widget.event.attendeeCount}/${widget.event.capacity} attending';
    }
    return '${widget.event.attendeeCount} attending';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0, // "Press-in" haptic effect
        duration: const Duration(milliseconds: 100),
        child: Container(
          margin: const EdgeInsets.only(bottom: DesignTokens.spacing12),
          decoration: BoxDecoration(
            color: DesignTokens.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
            boxShadow: [DesignTokens.ambientShadow()],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image/gradient header with date badge
              Stack(
                children: [
                  // Gradient background (placeholder for image)
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      gradient: DesignTokens.categoryGradient(
                        _getCategoryLabel(widget.event.category).toLowerCase(),
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(DesignTokens.radiusXl),
                        topRight: Radius.circular(DesignTokens.radiusXl),
                      ),
                    ),
                    child: widget.event.imageUrl != null
                        ? ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(DesignTokens.radiusXl),
                              topRight: Radius.circular(DesignTokens.radiusXl),
                            ),
                            child: Image.network(
                              widget.event.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(); // Fallback to gradient
                              },
                            ),
                          )
                        : null,
                  ),
                  // Date badge
                  Positioned(
                    top: DesignTokens.spacing16,
                    left: DesignTokens.spacing16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacing16,
                        vertical: DesignTokens.spacing12,
                      ),
                      decoration: BoxDecoration(
                        color: DesignTokens.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radiusLg,
                        ),
                        boxShadow: [DesignTokens.cardShadow()],
                      ),
                      child: Column(
                        children: [
                          Text(
                            DateFormat(
                              'MMM',
                            ).format(widget.event.startDateTime).toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: DesignTokens.secondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            DateFormat('d').format(widget.event.startDateTime),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: DesignTokens.primary,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Content section - 24px internal padding per DESIGN.md
              Padding(
                padding: const EdgeInsets.all(DesignTokens.spacing24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category badge and attendance with secondary_fixed accent chip
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.spacing12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(widget.event.category),
                            borderRadius: BorderRadius.circular(
                              DesignTokens.radiusMd,
                            ),
                          ),
                          child: Text(
                            _getCategoryLabel(widget.event.category),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: DesignTokens.onPrimary,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(width: DesignTokens.spacing12),
                        // Accent chip using secondary_fixed
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.spacing8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: DesignTokens.secondaryFixed,
                            borderRadius: BorderRadius.circular(
                              DesignTokens.radiusSm,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.people_rounded,
                                size: 14,
                                color: DesignTokens.onSecondaryFixed,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatAttendance(),
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: DesignTokens.onSecondaryFixed,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: DesignTokens.spacing12),
                    // Title - title-lg per DESIGN.md
                    Text(
                      widget.event.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22, // title-lg: 1.375rem
                        fontWeight: FontWeight.w800,
                        color: DesignTokens.onSurface,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spacing12),
                    // Time with surface-tint iconography
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 18,
                          color: DesignTokens.surfaceTint,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatTime(widget.event.startDateTime),
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: DesignTokens.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: DesignTokens.spacing8),
                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 18,
                          color: DesignTokens.surfaceTint,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.event.location,
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: DesignTokens.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: DesignTokens.spacing16),
                    // View Details button - xl rounding (pill shape)
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: DesignTokens.primaryGradient(),
                          borderRadius: BorderRadius.circular(
                            DesignTokens.radiusXl,
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: widget.onTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: DesignTokens.onPrimary,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              vertical: DesignTokens.spacing16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                DesignTokens.radiusXl,
                              ),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'View Details',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(width: DesignTokens.spacing8),
                              const Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
