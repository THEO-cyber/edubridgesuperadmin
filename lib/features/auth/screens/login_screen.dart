import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/edubridge_logo.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending2FA = ref.watch(authProvider.select((s) => s.pending2FA));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Left decorative panel — always visible
          const Expanded(child: _BrandPanel()),

          // Right panel switches between credential step and 2FA step
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: pending2FA
                ? const _TwoFactorPanel(key: ValueKey('2fa'))
                : const _CredentialPanel(key: ValueKey('cred')),
          ),
        ],
      ),
    );
  }
}

// ─── Left brand panel ─────────────────────────────────────────────────────────

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: Stack(
        children: [
          CustomPaint(painter: _GridPainter(), size: Size.infinite),
          Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const EduBridgeLogo(
                  markSize: 40,
                  fontSize: 22,
                  baseColor: Colors.white,
                ),
                const Spacer(),
                const Text(
                  'Manage your\nlearning platform.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Full control over users, courses, instructors,\nrevenue, and platform settings.',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 48),
                _FeatureRow(
                    icon: Icons.people_rounded,
                    label: 'User & instructor management'),
                const SizedBox(height: 12),
                _FeatureRow(
                    icon: Icons.school_rounded,
                    label: 'Course approval & moderation'),
                const SizedBox(height: 12),
                _FeatureRow(
                    icon: Icons.bar_chart_rounded,
                    label: 'Revenue analytics & payouts'),
                const SizedBox(height: 12),
                _FeatureRow(
                    icon: Icons.tune_rounded,
                    label: 'System-wide settings control'),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step 1 — credentials ─────────────────────────────────────────────────────

class _CredentialPanel extends ConsumerStatefulWidget {
  const _CredentialPanel({super.key});

  @override
  ConsumerState<_CredentialPanel> createState() => _CredentialPanelState();
}

class _CredentialPanelState extends ConsumerState<_CredentialPanel> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authProvider.notifier)
        .login(_emailCtrl.text.trim(), _passCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return _RightPanel(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Sign in to Admin',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Access the EduBridge administration panel',
              style:
                  TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 40),
            _FieldLabel('Email address'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'admin@edubridge.com',
                prefixIcon: Icon(Icons.mail_outline_rounded,
                    size: 16, color: AppColors.textMuted),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Email is required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            _FieldLabel('Password'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscure,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: '••••••••',
                prefixIcon: const Icon(Icons.lock_outline_rounded,
                    size: 16, color: AppColors.textMuted),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            if (authState.error != null) ...[
              const SizedBox(height: 16),
              _ErrorBox(authState.error!),
            ],
            const SizedBox(height: 28),
            SizedBox(
              height: 46,
              child: ElevatedButton(
                onPressed: authState.isLoading ? null : _submit,
                child: authState.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Sign In'),
              ),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Access restricted to ADMIN and SUPER_ADMIN roles.',
              style: TextStyle(
                  color: AppColors.textMuted, fontSize: 11, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step 2 — 2FA / TOTP ─────────────────────────────────────────────────────

class _TwoFactorPanel extends ConsumerStatefulWidget {
  const _TwoFactorPanel({super.key});

  @override
  ConsumerState<_TwoFactorPanel> createState() => _TwoFactorPanelState();
}

class _TwoFactorPanelState extends ConsumerState<_TwoFactorPanel> {
  final _codeCtrl = TextEditingController();

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) return;
    await ref.read(authProvider.notifier).verify2FA(code);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return _RightPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Back button
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: authState.isLoading
                  ? null
                  : () => ref.read(authProvider.notifier).cancelTwoFactor(),
              icon: const Icon(Icons.arrow_back_rounded, size: 15),
              label: const Text('Back'),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 20),

          // Lock icon
          Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.security_rounded,
                  color: AppColors.primary, size: 30),
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Two-factor authentication',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Open your authenticator app and enter the\n6-digit code for EduBridge.',
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 13, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),

          // 6-digit code input
          _FieldLabel('Verification code'),
          const SizedBox(height: 8),
          TextField(
            controller: _codeCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: 12,
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              counterText: '',
              hintText: '000000',
              hintStyle: TextStyle(
                color: AppColors.textMuted,
                fontSize: 28,
                letterSpacing: 12,
              ),
            ),
            onChanged: (v) {
              if (v.length == 6) _verify();
            },
          ),

          if (authState.error != null) ...[
            const SizedBox(height: 16),
            _ErrorBox(authState.error!),
          ],
          const SizedBox(height: 28),

          SizedBox(
            height: 46,
            child: ElevatedButton(
              onPressed: authState.isLoading ? null : _verify,
              child: authState.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Verify'),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Code changes every 30 seconds. Make sure your device clock is synced.',
            style: TextStyle(
                color: AppColors.textMuted, fontSize: 11, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Shared right-panel wrapper ───────────────────────────────────────────────

class _RightPanel extends StatelessWidget {
  const _RightPanel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 460,
      color: AppColors.surface,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
          child: child,
        ),
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _ErrorBox extends StatelessWidget {
  const _ErrorBox(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style:
                    const TextStyle(color: AppColors.error, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: AppColors.primaryLight),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFCBD5E1),
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x0DFFFFFF)
      ..strokeWidth = 0.5;
    const gap = 40.0;
    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
