import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/login_state_provider.dart';
import '../domain/validators/auth_validator.dart';
import '../../core/widgets/widgets.dart';
import 'register_screen.dart';
import 'reset_password_screen_riverpod.dart';
import 'login_status_banner.dart';
import '../../providers/auth_providers.dart';

class LoginScreenRiverpod extends ConsumerStatefulWidget {
  const LoginScreenRiverpod({super.key});

  @override
  ConsumerState<LoginScreenRiverpod> createState() =>
      _LoginScreenRiverpodState();
}

class _LoginScreenRiverpodState extends ConsumerState<LoginScreenRiverpod> {
  final Color primaryDarkBlue = const Color(0xFF001e40);
  final Color primaryContainer = const Color(0xFF003366);
  final Color backgroundSurface = const Color(0xFFf8f9fa);
  final Color surfaceHighest = const Color(0xFFffffff);
  final Color secondaryContainer = const Color(0xFF90efef);
  final Color textDark = const Color(0xFF191c1d);
  final Color errorColor = const Color(0xFFba1a1a);
  final Color fieldBackground = const Color(0xFFF3F4F6);

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? _statusMessage;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (_formKey.currentState?.validate() ?? false) {
      await ref
          .read(loginProvider.notifier)
          .signIn(_emailController.text.trim(), _passwordController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateNotifierProvider, (prev, next) {
      if (prev?.isUnauthenticated == true && next.isAuthenticated && mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
    ref.listen(loginProvider, (prev, next) {
      if (prev?.isSuccess == false && next.isSuccess && mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Signed in successfully'),
              duration: Duration(seconds: 1),
            ),
          );
      }
    });
    final loginState = ref.watch(loginProvider);

    return Scaffold(
      backgroundColor: backgroundSurface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 32.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: primaryDarkBlue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.school_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ACLC College of Mandaue',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: primaryDarkBlue,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    Text(
                      'Welcome Back',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Log in to your campus dashboard.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 32),

                    if (_statusMessage != null)
                      LoginStatusBanner(
                        message: _statusMessage!,
                        onDismiss: () => setState(() => _statusMessage = null),
                      ),

                    if (loginState.errorMessage != null) ...[
                      ErrorContainer(
                        message: loginState.errorMessage!,
                        type: MessageType.error,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Email Field
                    const FormLabel(text: 'Email Address'),
                    const SizedBox(height: 8),
                    FormInputField(
                      controller: _emailController,
                      hintText: 'student@aclc.edu',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) =>
                          AuthValidator.validateEmail(value ?? ''),
                    ),
                    const SizedBox(height: 20),

                    // Password Field Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const FormLabel(text: 'Password'),
                        SecondaryButton(
                          text: 'Forgot password?',
                          fullWidth: false,
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const ResetPasswordScreenRiverpod(),
                              ),
                            );
                            if (result is String && result.isNotEmpty) {
                              setState(() => _statusMessage = result);
                              ref.read(loginProvider.notifier).clearError();
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    FormInputField(
                      controller: _passwordController,
                      hintText: '••••••••',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.grey.shade500,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      validator: (value) =>
                          AuthValidator.validatePassword(value ?? ''),
                    ),

                    const SizedBox(height: 32),

                    // Sign In Button
                    PrimaryButton(
                      text: 'Sign In',
                      onPressed: _handleSignIn,
                      isLoading: loginState.isLoading,
                      icon: Icons.arrow_forward,
                    ),

                    const SizedBox(height: 32),

                    // Or Continue With Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.grey.shade300,
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR CONTINUE WITH',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade400,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.grey.shade300,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Social Logins (Student Number)
                    ElevatedButton(
                      onPressed: () {
                        // Handle Student Number login
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFAFAFA),
                        foregroundColor: textDark,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.person,
                                size: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Login with Student Number',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Sign up',
                              style: TextStyle(
                                color: const Color(0xFF006a6a),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    Text(
                      '© 2024 ACLC COLLEGE OF MANDAUE • CSO VERIFIED',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade400,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
