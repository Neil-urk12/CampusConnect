import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/widgets.dart';
import '../../providers/register_state_provider.dart';
import '../domain/validators/auth_validator.dart';
import 'login_screen_riverpod.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final Color primaryDarkBlue = const Color(0xFF001e40);
  final Color backgroundSurface = const Color(0xFFf8f9fa);
  final Color textDark = const Color(0xFF191c1d);

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _studentIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState?.validate() ?? false) {
      final success = await ref
          .read(registerProvider.notifier)
          .register(
            fullName: _fullNameController.text.trim(),
            email: _emailController.text.trim(),
            studentId: _studentIdController.text.trim(),
            password: _passwordController.text,
          );

      if (success && mounted) {
        // Pop back to root — auth gate will detect authenticated user
        Navigator.of(context).popUntil((route) => route.isFirst);
      }

    }
  }
  @override
  Widget build(BuildContext context) {
    final registerState = ref.watch(registerProvider);

    return Scaffold(
      backgroundColor: backgroundSurface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const LoginScreenRiverpod()),
            );
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
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
                      'Create Account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign up to access your campus dashboard.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Error Message Display
                    if (registerState.errorMessage != null) ...[
                      ErrorContainer(
                        message: registerState.errorMessage!,
                        type: MessageType.error,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Full Name Field
                    const FormLabel(text: 'Full Name', required: true),
                    const SizedBox(height: 8),
                    FormInputField(
                      controller: _fullNameController,
                      hintText: 'Juan Dela Cruz',
                      prefixIcon: Icons.person_outline,
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                      validator: (value) => AuthValidator.validateRequired(
                        value ?? '',
                        'Full name',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Email Field
                    const FormLabel(text: 'Email Address', required: true),
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

                    const FormLabel(text: 'Student ID', required: true),
                    const SizedBox(height: 8),
                    FormInputField(
                      controller: _studentIdController,
                      hintText: 'ABC123456',
                      prefixIcon: Icons.badge_outlined,
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.characters,
                      validator: (value) =>
                          AuthValidator.validateStudentId(value ?? ''),
                    ),
                    const SizedBox(height: 20),

                    const FormLabel(text: 'Password', required: true),
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

                    PrimaryButton(
                      text: 'Register',
                      onPressed: registerState.isLoading
                          ? null
                          : _handleRegister,
                      isLoading: registerState.isLoading,
                      icon: Icons.arrow_forward,
                    ),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                        SecondaryButton(
                          text: 'Sign in',
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const LoginScreenRiverpod(),
                              ),
                            );
                          },
                          fullWidth: false,
                        ),
                      ],
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
