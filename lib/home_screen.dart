import 'package:flutter/material.dart';
import 'features/profile/profile_screen_riverpod.dart';
import 'features/announcements/presentation/screens/announcements_screen.dart';
import 'features/chat/presentation/screens/chat_screen.dart';
import 'features/events/events_screen.dart';
import 'features/resources/presentation/resources_screen.dart';
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
