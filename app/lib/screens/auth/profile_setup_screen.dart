import 'package:cricstatz/config/palette.dart';
import 'package:cricstatz/providers/auth_provider.dart';
import 'package:cricstatz/services/profile_service.dart';
import 'package:cricstatz/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  String _selectedRole = 'batter';
  bool _isCheckingUsername = false;
  bool _isUsernameAvailable = true;
  bool _isSubmitting = false;

  final List<String> _roles = [
    'batter',
    'bowler',
    'all-rounder',
    'wicket-keeper',
  ];

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_onUsernameChanged);
  }

  @override
  void dispose() {
    _usernameController.removeListener(_onUsernameChanged);
    _usernameController.dispose();
    super.dispose();
  }

  void _onUsernameChanged() {
    final username = _usernameController.text.trim();
    if (username.length >= 3) {
      _checkUsernameAvailability(username);
    }
  }

  Future<void> _checkUsernameAvailability(String username) async {
    setState(() => _isCheckingUsername = true);
    final available = await ProfileService.isUsernameAvailable(username);
    if (mounted && _usernameController.text.trim() == username) {
      setState(() {
        _isUsernameAvailable = available;
        _isCheckingUsername = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || !_isUsernameAvailable) return;

    setState(() => _isSubmitting = true);

    try {
      final user = SupabaseService.currentUser!;
      final displayName =
          user.userMetadata?['full_name'] as String? ?? _usernameController.text;
      final avatarUrl = user.userMetadata?['avatar_url'] as String?;

      await context.read<AuthProvider>().createProfile(
            username: _usernameController.text.trim(),
            displayName: displayName,
            avatarUrl: avatarUrl,
            role: _selectedRole,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to set up profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppPalette.surfaceGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'Set Up Your Profile',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              color: AppPalette.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Choose a unique username and your playing role',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppPalette.textMuted,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 40),
                    // Username field
                    Text(
                      'Username',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppPalette.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _usernameController,
                      style: TextStyle(color: AppPalette.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'e.g. virat_king',
                        hintStyle:
                            TextStyle(color: AppPalette.textSubtle),
                        filled: true,
                        fillColor: AppPalette.cardPrimary,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: AppPalette.cardStroke),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: AppPalette.cardStroke),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: AppPalette.accent),
                        ),
                        suffixIcon: _isCheckingUsername
                            ? Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppPalette.accent,
                                  ),
                                ),
                              )
                            : _usernameController.text.trim().length >= 3
                                ? Icon(
                                    _isUsernameAvailable
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: _isUsernameAvailable
                                        ? AppPalette.success
                                        : AppPalette.live,
                                  )
                                : null,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Username is required';
                        }
                        if (value.trim().length < 3) {
                          return 'At least 3 characters';
                        }
                        if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
                          return 'Only letters, numbers, and underscores';
                        }
                        if (!_isUsernameAvailable) {
                          return 'Username is taken';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 24),
                    // Role picker
                    Text(
                      'Playing Role',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppPalette.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _roles.map((role) {
                        final isSelected = _selectedRole == role;
                        return ChoiceChip(
                          label: Text(_formatRole(role)),
                          selected: isSelected,
                          onSelected: (_) =>
                              setState(() => _selectedRole = role),
                          selectedColor: AppPalette.accent,
                          backgroundColor: AppPalette.cardPrimary,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppPalette.bgPrimary
                                : AppPalette.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? AppPalette.accent
                                : AppPalette.cardStroke,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 40),
                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppPalette.accent,
                          foregroundColor: AppPalette.bgPrimary,
                          disabledBackgroundColor:
                              AppPalette.accent.withAlpha(128),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmitting
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppPalette.bgPrimary,
                                ),
                              )
                            : const Text(
                                'Continue',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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

  String _formatRole(String role) {
    return role.split('-').map((w) => '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
  }
}
