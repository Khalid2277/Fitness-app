import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';
import 'package:alfanutrition/data/supabase/supabase_providers.dart';

/// Authentication screen with sign-in / sign-up tabs, Apple Sign-In, and
/// forgot-password flow.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isAppleLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
        _formKey.currentState?.reset();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  bool get _isSignUp => _tabController.index == 1;

  // ──────────────────────── Auth actions ──────────────────────────────────

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);

      if (_isSignUp) {
        final response = await authService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim().isNotEmpty
              ? _nameController.text.trim()
              : null,
        );

        if (mounted) {
          // If session is null, email confirmation is required
          if (response.session == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Account created! Check your email to confirm, then sign in.',
                ),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 5),
                shape: RoundedRectangleBorder(
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
              ),
            );
            // Switch to sign-in tab
            _tabController.animateTo(0);
          } else {
            context.go('/onboarding');
          }
        }
      } else {
        await authService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (mounted) context.go('/onboarding');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_friendlyError(e)),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: AppSpacing.borderRadiusSm,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithApple() async {
    setState(() => _isAppleLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final response = await authService.signInWithApple();

      if (mounted && response.session != null) {
        context.go('/onboarding');
      }
    } catch (e) {
      // User cancelled the Apple Sign-In sheet — don't show an error
      if (e.toString().contains('AuthorizationErrorCode.canceled') ||
          e.toString().contains('canceled')) {
        // Silently ignore cancellation
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_friendlyError(e)),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: AppSpacing.borderRadiusSm,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAppleLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Enter your email address first.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusSm,
          ),
        ),
      );
      return;
    }

    try {
      final authService = ref.read(authServiceProvider);
      await authService.resetPassword(email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Password reset email sent. Check your inbox.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: AppSpacing.borderRadiusSm,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_friendlyError(e)),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: AppSpacing.borderRadiusSm,
            ),
          ),
        );
      }
    }
  }

  String _friendlyError(Object error) {
    final msg = error.toString();
    if (msg.contains('Invalid login credentials')) {
      return 'Invalid email or password. Please try again.';
    }
    if (msg.contains('User already registered')) {
      return 'An account with this email already exists.';
    }
    if (msg.contains('Email not confirmed')) {
      return 'Please verify your email before signing in.';
    }
    if (msg.contains('weak_password') || msg.contains('at least')) {
      return 'Password is too weak. Use at least 6 characters.';
    }
    if (msg.contains('invalid_email') || msg.contains('not a valid email')) {
      return 'Please enter a valid email address.';
    }
    if (msg.contains('Apple') || msg.contains('apple')) {
      return 'Apple Sign-In failed. Please try again.';
    }
    if (msg.contains('Email rate limit exceeded')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  // ──────────────────────── Validators ───────────────────────────────────

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required.';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email.';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required.';
    if (value.length < 6) return 'Must be at least 6 characters.';
    return null;
  }

  String? _validateName(String? value) {
    if (_isSignUp && (value == null || value.trim().isEmpty)) {
      return 'Name is required.';
    }
    return null;
  }

  // ──────────────────────── Build ────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    AppColors.primaryDark,
                    AppColors.primaryDarkElevated,
                    AppColors.primaryBlueSurface.withValues(alpha: 0.5),
                  ]
                : [
                    AppColors.backgroundLight,
                    const Color(0xFFEEEFFF),
                    const Color(0xFFE5E3FF),
                  ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: AppSpacing.screenPadding.copyWith(
              top: AppSpacing.xxxxl,
              bottom: AppSpacing.xxxl,
            ),
            child: Column(
              children: [
                // -- Logo / branding --
                _BrandingHeader(isDark: isDark, theme: theme)
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: -0.08, duration: 600.ms,
                        curve: Curves.easeOutCubic),

                const SizedBox(height: AppSpacing.xxxl),

                // -- Glass card with form --
                ClipRRect(
                  borderRadius: AppSpacing.borderRadiusXl,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : Colors.white.withValues(alpha: 0.7),
                        borderRadius: AppSpacing.borderRadiusXl,
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.white.withValues(alpha: 0.9),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.3)
                                : AppColors.primaryBlue.withValues(alpha: 0.06),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        children: [
                          // Tab bar
                          _AuthTabBar(
                            controller: _tabController,
                            isDark: isDark,
                            theme: theme,
                          ),

                          const SizedBox(height: AppSpacing.xxl),

                          // Form
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Name field (sign-up only)
                                AnimatedSize(
                                  duration: 300.ms,
                                  curve: Curves.easeInOut,
                                  child: _isSignUp
                                      ? Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: AppSpacing.lg,
                                          ),
                                          child: _StyledTextField(
                                            controller: _nameController,
                                            label: 'Full Name',
                                            icon: Icons.person_outline_rounded,
                                            validator: _validateName,
                                            isDark: isDark,
                                            theme: theme,
                                            textInputAction:
                                                TextInputAction.next,
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),

                                // Email
                                _StyledTextField(
                                  controller: _emailController,
                                  label: 'Email',
                                  icon: Icons.email_outlined,
                                  validator: _validateEmail,
                                  isDark: isDark,
                                  theme: theme,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                ),

                                const SizedBox(height: AppSpacing.lg),

                                // Password
                                _StyledTextField(
                                  controller: _passwordController,
                                  label: 'Password',
                                  icon: Icons.lock_outline_rounded,
                                  validator: _validatePassword,
                                  isDark: isDark,
                                  theme: theme,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _submit(),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: isDark
                                          ? AppColors.textTertiaryDark
                                          : AppColors.textTertiaryLight,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() => _obscurePassword =
                                          !_obscurePassword);
                                    },
                                  ),
                                ),

                                // Forgot password (sign-in only)
                                if (!_isSignUp) ...[
                                  const SizedBox(height: AppSpacing.sm),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _forgotPassword,
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.sm,
                                          vertical: AppSpacing.xs,
                                        ),
                                      ),
                                      child: Text(
                                        'Forgot Password?',
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: AppColors.primaryBlue,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: AppSpacing.xxl),

                          // Submit button
                          _GradientButton(
                            label: _isSignUp ? 'Create Account' : 'Sign In',
                            isLoading: _isLoading,
                            onPressed: _submit,
                          ),

                          // Apple Sign-In
                          if (Platform.isIOS) ...[
                            const SizedBox(height: AppSpacing.xl),
                            _OrDivider(isDark: isDark, theme: theme),
                            const SizedBox(height: AppSpacing.xl),
                            _AppleSignInButton(
                              isLoading: _isAppleLoading,
                              onPressed: _signInWithApple,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 200.ms)
                    .slideY(begin: 0.06, delay: 200.ms, duration: 500.ms),

                const SizedBox(height: AppSpacing.xxl),

                // Bottom branding
                Text(
                  'Powered by Alfa Tech Labs',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                    letterSpacing: 0.5,
                  ),
                ).animate().fadeIn(delay: 600.ms, duration: 500.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================================================
// Private widgets
// ==========================================================================

class _BrandingHeader extends StatelessWidget {
  const _BrandingHeader({required this.isDark, required this.theme});

  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // App logo with glow
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            borderRadius: AppSpacing.borderRadiusXl,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withValues(alpha: 0.3),
                blurRadius: 30,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: AppSpacing.borderRadiusXl,
            child: Image.asset(
              'assets/images/logo.png',
              width: 90,
              height: 90,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        // Gradient app name
        ShaderMask(
          shaderCallback: (bounds) =>
              AppColors.primaryGradient.createShader(bounds),
          child: Text(
            'AlfaNutrition',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Your AI-Powered Fitness Companion',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _AuthTabBar extends StatelessWidget {
  const _AuthTabBar({
    required this.controller,
    required this.isDark,
    required this.theme,
  });

  final TabController controller;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : AppColors.surfaceLight2,
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      padding: const EdgeInsets.all(4),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: AppSpacing.borderRadiusSm,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight,
        labelStyle: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'Sign In'),
          Tab(text: 'Sign Up'),
        ],
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  const _StyledTextField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.isDark,
    required this.theme,
    this.validator,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isDark;
  final ThemeData theme;
  final String? Function(String?)? validator;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: theme.textTheme.bodyMedium?.copyWith(
          color: isDark
              ? AppColors.textTertiaryDark
              : AppColors.textTertiaryLight,
        ),
        prefixIcon: Icon(
          icon,
          color: isDark
              ? AppColors.textTertiaryDark
              : AppColors.textTertiaryLight,
          size: 20,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : AppColors.surfaceLight1,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppColors.dividerLight,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppColors.dividerLight,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: const BorderSide(
            color: AppColors.primaryBlue,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isLoading ? null : AppColors.primaryGradient,
          color: isLoading
              ? AppColors.primaryBlue.withValues(alpha: 0.3)
              : null,
          borderRadius: AppSpacing.borderRadiusMd,
          boxShadow: isLoading
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: AppSpacing.borderRadiusMd,
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.isDark, required this.theme});

  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : AppColors.dividerLight;
    return Row(
      children: [
        Expanded(child: Divider(color: dividerColor)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            'OR',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Expanded(child: Divider(color: dividerColor)),
      ],
    );
  }
}

class _AppleSignInButton extends StatelessWidget {
  const _AppleSignInButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox.shrink()
            : Icon(
                Icons.apple_rounded,
                size: 24,
                color: isDark ? Colors.black : Colors.white,
              ),
        label: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? Colors.black : Colors.white,
                  ),
                ),
              )
            : Text(
                'Continue with Apple',
                style: TextStyle(
                  color: isDark ? Colors.black : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.white : Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
