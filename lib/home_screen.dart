import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'features/profile/profile_screen_riverpod.dart';
import 'features/announcements/presentation/screens/announcements_screen.dart';
import 'features/chat/presentation/screens/chat_screen.dart';
import 'features/events/events_screen.dart';
import 'features/resources/presentation/resources_screen.dart';
import 'features/events/providers/event_providers.dart';
import 'app/routes.dart';
import 'providers/auth_providers.dart';
import 'appwrite_test_helper.dart';
import 'auth/domain/user_display_name.dart';
import 'core/widgets/widgets.dart';
import '../core/theme/design_tokens.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const AnnouncementsScreen(),
    const EventsScreen(),
    const ChatScreen(),
    const ResourcesScreen(),
    const ProfileScreenRiverpod(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.campaign_outlined, "Announce"),
                _buildNavItem(1, Icons.event_outlined, "Events"),
                _buildNavItem(2, Icons.chat_bubble_outline_rounded, "Chats"),
                _buildNavItem(3, Icons.folder_outlined, "Resources"),
                _buildNavItem(4, Icons.person_outline, "Profile"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: const Color(0xFFE0F2F1),
                borderRadius: BorderRadius.circular(16),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? DesignTokens.secondary : Colors.grey.shade400,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? DesignTokens.secondary : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardTab extends ConsumerStatefulWidget {
  const DashboardTab({super.key});

  @override
  ConsumerState<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends ConsumerState<DashboardTab> {
  bool _isPinging = false;
  String _pingStatus = 'Not tested';
  Color _statusColor = Colors.grey;

  final Color textDark = const Color(0xFF1F2937);
  final Color primaryDarkBlue = const Color(0xFF091C31);

  Future<void> _sendPing() async {
    setState(() {
      _isPinging = true;
      _pingStatus = 'Connecting...';
      _statusColor = Colors.orange;
    });

    try {
      // Run the complete test that creates bucket and uploads file
      await AppwriteTestHelper.runCompleteTest();

      setState(() {
        _isPinging = false;
        _pingStatus = 'Connected ✓';
        _statusColor = Colors.green;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '✅ Test file uploaded! Check Appwrite Console → Storage',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isPinging = false;
        _pingStatus = 'Failed ✗';
        _statusColor = Colors.red;
      });
      if (mounted) {
        final errorMsg = e.toString();
        final truncated = errorMsg.length > 100
            ? errorMsg.substring(0, 100)
            : errorMsg;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Test failed: $truncated'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateNotifierProvider);
    final userName = authState.user?.displayName ?? 'Guest';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Text(
              'Welcome back,\n$userName!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: primaryDarkBlue,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Here's what's happening today in your campus circle.",
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),

            // Appwrite Connection Test Card
            CardContainer(
              variant: CardVariant.gradient,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFfd366e), Color(0xFFf02e65)],
              ),
              onTap: _isPinging ? null : _sendPing,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.cloud_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _pingStatus.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Appwrite Storage",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isPinging
                        ? "Creating test bucket and uploading file..."
                        : "Tap to upload test file to Appwrite",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        if (_isPinging)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        else
                          const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        const SizedBox(width: 12),
                        Text(
                          _isPinging ? "Uploading..." : "Send a Ping",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          "Project: campusconnect",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Urgent Announcement Card
            CardContainer(
              variant: CardVariant.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        Icons.campaign_outlined,
                        color: Colors.tealAccent.shade400,
                        size: 28,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error,
                              color: Colors.red.shade700,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "URGENT",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Final Exam Schedule Released",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryDarkBlue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "The official schedule for the Fall 2023 final examinations is now available. Please check your personalized dashboard to see specific dates, times, and hall assignments for each course.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text(
                        "View Schedule",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: DesignTokens.secondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward, color: DesignTokens.secondary, size: 16),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Next Event Card
            Consumer(
              builder: (context, ref, child) {
                final nextEventAsync = ref.watch(allUpcomingEventsProvider);

                return nextEventAsync.when(
                  data: (events) {
                    if (events.isEmpty) {
                      return CardContainer(
                        variant: CardVariant.dark,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.calendar_month,
                                    color: Colors.lightBlueAccent,
                                    size: 24,
                                  ),
                                ),
                                Text(
                                  "NEXT EVENT",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade400,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            const Text(
                              "No Upcoming Events",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Check back later for new events",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final nextEvent = events.first;
                    final dateFormat = DateFormat('d');
                    final monthFormat = DateFormat(
                      'MMM',
                    ).format(nextEvent.startDateTime).toUpperCase();
                    final timeFormat = DateFormat(
                      'h:mm a',
                    ).format(nextEvent.startDateTime);

                    return CardContainer(
                      variant: CardVariant.dark,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.eventDetail,
                          arguments: nextEvent.id,
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.calendar_month,
                                  color: Colors.lightBlueAccent,
                                  size: 24,
                                ),
                              ),
                              Text(
                                "NEXT EVENT",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade400,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          Text(
                            nextEvent.title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            nextEvent.location,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      dateFormat.format(
                                        nextEvent.startDateTime,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      monthFormat,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  height: 30,
                                  width: 1,
                                  color: Colors.grey.shade700,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      timeFormat,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "${nextEvent.attendeeCount} attending",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => CardContainer(
                    variant: CardVariant.dark,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                  error: (error, stack) => CardContainer(
                    variant: CardVariant.dark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 32,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Unable to load events",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Please try again later",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Document Card
            CardContainer(
              variant: CardVariant.white,
              padding: const EdgeInsets.all(20),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Downloading Document...")),
                );
              },
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E4A47),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.description, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Thesis_Guidelines_2024.pdf",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: primaryDarkBlue,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "PDF DOCUMENT • 4.2 MB",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.download_outlined,
                      size: 20,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Spotlight Card
            CardContainer(
              variant: CardVariant.gradient,
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF4B5563), Color(0xFF111827)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "CAMPUS SPOTLIGHT",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: DesignTokens.secondary,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "New Sustainable Energy Center opens on West Campus this Friday.",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Join the Dean for the ribbon-cutting ceremony and a tour of the new facilities.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade400,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
