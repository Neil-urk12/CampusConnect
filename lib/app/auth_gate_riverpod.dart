import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_providers.dart';
import '../auth/presentation/login_screen_riverpod.dart';
import '../home_screen.dart';

/// AuthGate widget that controls access to protected routes
/// Redirects to login if unauthenticated, shows protected content if authenticated
class AuthGateRiverpod extends ConsumerWidget {
  const AuthGateRiverpod({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateNotifierProvider);

    // Show loading indicator while checking authentication state
    if (authState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Show error state with retry option
    if (authState.error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: ${authState.error}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Retry by refreshing the auth state
                  ref.read(authStateNotifierProvider.notifier).refresh();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Redirect to login if unauthenticated
    if (authState.isUnauthenticated) {
      return const LoginScreenRiverpod();
    }

    // User is authenticated - show protected content
    return const HomeScreen();
  }
}
