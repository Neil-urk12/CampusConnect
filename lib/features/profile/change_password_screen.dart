import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/domain/exceptions/auth_exception.dart';
import '../../auth/domain/validators/auth_validator.dart';
import '../../providers/auth_providers.dart';
import '../../core/widgets/widgets.dart';
import '../../core/theme/design_tokens.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  late final TextEditingController _currentPasswordController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _errorMessage;
  final Map<String, bool> _obscureFields = {
    'current': true,
    'new': true,
    'confirm': true,
  };

  @override
  void initState() {
    super.initState();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);

      await authService.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password updated successfully!'),
            backgroundColor: DesignTokens.secondary,
          ),
        );
      }
    } on AuthException catch (e) {
      _showError(
        e.message.isNotEmpty ? e.message : 'An unexpected error occurred.',
      );
    } catch (e) {
      _showError('Password change failed: ${e.toString()}');
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(
          'Change Password',
          style: TextStyle(
            color: DesignTokens.primary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: DesignTokens.surfaceContainerLowest,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: DesignTokens.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacing24,
            vertical: DesignTokens.spacing16,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Enter your current password and choose a new password',
                  style: TextStyle(
                    fontSize: 14,
                    color: DesignTokens.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacing32),

                if (_errorMessage != null) ...[
                  ErrorContainer(
                    message: _errorMessage!,
                    type: MessageType.error,
                  ),
                  const SizedBox(height: DesignTokens.spacing16),
                ],

                FormLabel(text: 'Current Password'),
                const SizedBox(height: DesignTokens.spacing8),
                FormInputField(
                  controller: _currentPasswordController,
                  hintText: 'Enter current password',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscureFields['current']!,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureFields['current']!
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: DesignTokens.onSurfaceVariant,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureFields['current'] = !_obscureFields['current']!;
                      });
                    },
                  ),
                  validator: (value) {
                    return AuthValidator.validatePassword(value ?? '');
                  },
                  enabled: !_isLoading,
                ),
                const SizedBox(height: DesignTokens.spacing24),

                FormLabel(text: 'New Password'),
                const SizedBox(height: DesignTokens.spacing8),
                FormInputField(
                  controller: _newPasswordController,
                  hintText: 'Enter new password (min 8 characters)',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscureFields['new']!,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureFields['new']!
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: DesignTokens.onSurfaceVariant,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureFields['new'] = !_obscureFields['new']!;
                      });
                    },
                  ),
                  validator: (value) {
                    return AuthValidator.validatePasswordStrict(value ?? '');
                  },
                  enabled: !_isLoading,
                ),
                const SizedBox(height: DesignTokens.spacing24),

                FormLabel(text: 'Confirm New Password'),
                const SizedBox(height: DesignTokens.spacing8),
                FormInputField(
                  controller: _confirmPasswordController,
                  hintText: 'Re-enter new password',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscureFields['confirm']!,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureFields['confirm']!
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: DesignTokens.onSurfaceVariant,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureFields['confirm'] = !_obscureFields['confirm']!;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your new password';
                    }
                    if (value != _newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 40),

                PrimaryButton(
                  text: 'Change Password',
                  onPressed: _isLoading ? null : _handleChangePassword,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: DesignTokens.spacing16),

                SecondaryButton(
                  text: 'Cancel',
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
