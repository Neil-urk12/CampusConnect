import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/domain/entities/user_entity.dart';
import '../../auth/domain/exceptions/auth_exception.dart';
import '../../auth/domain/user_display_name.dart';
import '../../auth/domain/validators/auth_validator.dart';
import '../../providers/auth_providers.dart';
import '../../core/widgets/widgets.dart';
import '../../core/theme/design_tokens.dart';

class EditPersonalInfoScreen extends ConsumerStatefulWidget {
  final UserEntity user;

  const EditPersonalInfoScreen({super.key, required this.user});

  @override
  ConsumerState<EditPersonalInfoScreen> createState() =>
      _EditPersonalInfoScreenState();
}

class _EditPersonalInfoScreenState
    extends ConsumerState<EditPersonalInfoScreen> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _studentIdController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _errorMessage;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.user.fullName);
    _studentIdController = TextEditingController(text: widget.user.studentId);

    _fullNameController.addListener(_onFieldChanged);
    _studentIdController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    final hasChanges =
        _fullNameController.text.trim() != widget.user.fullName.trim() ||
        _studentIdController.text.trim() != widget.user.studentId.trim();

    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _studentIdController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasChanges) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);

      await authService.updateProfile(
        userId: widget.user.userId,
        fullName: _fullNameController.text,
        studentId: _studentIdController.text,
      );

      await ref.read(authStateNotifierProvider.notifier).refresh();

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: DesignTokens.secondary,
          ),
        );
      }
    } on AuthException catch (e) {
      _showError(e.message.isNotEmpty ? e.message : 'An unexpected error occurred.');
    } catch (e) {
      _showError('Failed to update profile: ${e.toString()}');
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
          'Personal Information',
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
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacing24, vertical: DesignTokens.spacing16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: DesignTokens.primary.withValues(alpha: 0.1),
                    child: Text(
                      widget.user.displayName[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: DesignTokens.primary,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: DesignTokens.spacing32),

                if (_errorMessage != null) ...[
                  ErrorContainer(
                    message: _errorMessage!,
                    type: MessageType.error,
                  ),
                  const SizedBox(height: DesignTokens.spacing16),
                ],

                FormLabel(text: 'Email Address'),
                const SizedBox(height: DesignTokens.spacing8),
                _buildReadOnlyField(
                  icon: Icons.email_outlined,
                  value: widget.user.email,
                ),
                const SizedBox(height: DesignTokens.spacing4),
                Text(
                  'Email cannot be changed',
                  style: TextStyle(fontSize: 11, color: DesignTokens.onSurfaceVariant),
                ),
                const SizedBox(height: DesignTokens.spacing24),

                FormLabel(text: 'Full Name'),
                const SizedBox(height: DesignTokens.spacing8),
                FormInputField(
                  controller: _fullNameController,
                  hintText: 'Enter your full name',
                  prefixIcon: Icons.person_outline,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    return AuthValidator.validateRequired(
                      value ?? '',
                      'Full name',
                    );
                  },
                ),
                const SizedBox(height: DesignTokens.spacing24),

                FormLabel(text: 'Student ID'),
                const SizedBox(height: DesignTokens.spacing8),
                FormInputField(
                  controller: _studentIdController,
                  hintText: 'Enter your student ID',
                  prefixIcon: Icons.badge_outlined,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.characters,
                  validator: (value) {
                    return AuthValidator.validateStudentId(value ?? '');
                  },
                ),
                const SizedBox(height: 40),

                PrimaryButton(
                  text: _hasChanges ? 'Save Changes' : 'No Changes',
                  onPressed: _isLoading ? null : _handleSave,
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

  Widget _buildReadOnlyField({required IconData icon, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacing16, vertical: DesignTokens.spacing16),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: DesignTokens.onSurfaceVariant, size: 20),
          const SizedBox(width: DesignTokens.spacing12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 15, color: DesignTokens.onSurfaceVariant),
            ),
          ),
          Icon(Icons.lock_outline, color: DesignTokens.outlineVariant, size: 18),
        ],
      ),
    );
  }
}
