import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/domain/entities/user_entity.dart';
import '../../auth/domain/user_display_name.dart';
import '../../providers/auth_providers.dart';
import 'edit_personal_info_screen.dart';
import 'security_settings_screen.dart';
import '../../core/theme/design_tokens.dart';

class ProfileScreenRiverpod extends ConsumerWidget {
  const ProfileScreenRiverpod({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(
          "My Profile",
          style: TextStyle(
            color: DesignTokens.primary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: DesignTokens.surfaceContainerLowest,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: DesignTokens.primary),
            onPressed: () => _showSignOutConfirmation(context, ref),
          ),
        ],
      ),
      body: authState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : authState.user == null
          ? const Center(child: Text('Not logged in'))
          : _buildProfileContent(context, ref, authState.user!),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    WidgetRef ref,
    UserEntity user,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Profile Header
          Center(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: DesignTokens.surfaceTint.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    size: 50,
                    color: DesignTokens.surfaceTint,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacing16),
                Text(
                  user.displayName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: DesignTokens.primary,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacing4),
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: DesignTokens.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.spacing32),

          // Profile Options
          _buildProfileOption(
            context,
            icon: Icons.person_outline,
            title: 'Personal Information',
            subtitle: 'Update your personal details',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditPersonalInfoScreen(user: user),
                ),
              );
            },
          ),
          const SizedBox(height: DesignTokens.spacing12),
          _buildProfileOption(
            context,
            icon: Icons.lock_outline,
            title: 'Security',
            subtitle: 'Change password and security settings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SecuritySettingsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: DesignTokens.spacing12),
          _buildProfileOption(
            context,
            icon: Icons.notifications_none,
            title: 'Notifications',
            subtitle: 'Manage notification preferences',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notification settings coming soon'),
                ),
              );
            },
          ),
          const SizedBox(height: DesignTokens.spacing12),
          _buildProfileOption(
            context,
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help and contact support',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Help & Support coming soon')),
              );
            },
          ),
          const SizedBox(height: DesignTokens.spacing12),
          _buildProfileOption(
            context,
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'App version and information',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'CampusConnect',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2024 ACLC College of Mandaue',
              );
            },
          ),
          const SizedBox(height: DesignTokens.spacing32),
        ],
      ),
    );
  }

  void _showSignOutConfirmation(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(DesignTokens.spacing24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: DesignTokens.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: DesignTokens.spacing24),
            Icon(Icons.logout, size: 48, color: DesignTokens.error),
            const SizedBox(height: DesignTokens.spacing16),
            Text(
              'Sign Out',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: DesignTokens.primary,
              ),
            ),
            const SizedBox(height: DesignTokens.spacing8),
            Text(
              'Are you sure you want to sign out?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: DesignTokens.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: DesignTokens.spacing24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: DesignTokens.spacing16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: DesignTokens.outlineVariant),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: DesignTokens.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: DesignTokens.spacing12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      final authService = ref.read(authServiceProvider);
                      await authService.signOut();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignTokens.error,
                      foregroundColor: DesignTokens.onError,
                      padding: const EdgeInsets.symmetric(
                        vertical: DesignTokens.spacing16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Sign Out',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.spacing8),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.spacing16),
        decoration: BoxDecoration(
          color: DesignTokens.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: DesignTokens.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: DesignTokens.surfaceTint, size: 24),
            ),
            const SizedBox(width: DesignTokens.spacing16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: DesignTokens.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: DesignTokens.outlineVariant,
            ),
          ],
        ),
      ),
    );
  }
}
