import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../widgets/social_login_button.dart';
import 'email_auth_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Column(
            children: [
              const Spacer(),

              // ── Logo & headline ──────────────────────────────────
              const Icon(
                Icons.flight_takeoff_rounded,
                size: 64,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.md),
              const Text('Espeon', style: AppTypography.displayLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Plan trips together',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),

              const Spacer(),

              // ── Error message ────────────────────────────────────
              if (auth.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Text(
                    auth.errorMessage!,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // ── Sign-in buttons ──────────────────────────────────
              SocialLoginButton(
                label: 'Continue with Google',
                iconAsset: 'assets/icons/google.svg',
                isLoading: auth.loadingMethod == AuthMethod.google,
                onTap: () => auth.signInWithGoogle(),
              ),
              const SizedBox(height: AppSpacing.sm),

              SocialLoginButton(
                label: 'Continue with Apple',
                iconAsset: 'assets/icons/apple.svg',
                isLoading: auth.loadingMethod == AuthMethod.apple,
                onTap: () => auth.signInWithApple(),
              ),
              const SizedBox(height: AppSpacing.sm),

              // ── Divider ──────────────────────────────────────────
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md),
                    child: Text('or',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textHint,
                        )),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              OutlinedButton(
                onPressed: auth.loadingMethod != AuthMethod.none
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EmailAuthScreen(),
                          ),
                        ),
                child: const Text('Continue with Email'),
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Terms ────────────────────────────────────────────
              Text(
                'By continuing, you agree to our Terms of Service\nand Privacy Policy.',
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
