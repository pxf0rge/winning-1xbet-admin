import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:w1xbet_admin/core/l10n/admin_l10n.dart';
import 'package:w1xbet_admin/core/theme/admin_theme.dart';
import '../cubit/auth_cubit.dart';
import '../widgets/custom_text_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final userCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  @override
  void dispose() {
    userCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  void _submit(AuthCubit cubit) {
    final raw = userCtrl.text.trim();
    if (raw.isEmpty || passCtrl.text.isEmpty) return;
    final email = raw.contains('@') ? raw : '$raw@w1xbet.info';
    cubit.login(email, passCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AdminTheme.navy,
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: _GlowBlob(
              size: 220,
              color: AdminTheme.primary.withOpacity(0.22),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -40,
            child: _GlowBlob(
              size: 260,
              color: AdminTheme.gold.withOpacity(0.12),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, top > 0 ? 12 : 24, 24, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: BlocConsumer<AuthCubit, AuthState>(
                    listener: (c, state) {
                      if (state is AuthError) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              state.msg.contains('credentials')
                                  ? s.invalidCredentials
                                  : s.loginFailed,
                            ),
                            backgroundColor: Colors.red.shade700,
                          ),
                        );
                      }
                    },
                    builder: (c, state) {
                      final loading = state is AuthLoading;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _BrandMark(),
                          const SizedBox(height: 28),
                          Text(
                            s.welcomeBack,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            s.signInToContinue,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AdminTheme.card,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.06),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                CustomTextField(
                                  controller: userCtrl,
                                  hint: s.username,
                                  icon: Icons.person_outline_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: 14),
                                CustomTextField(
                                  controller: passCtrl,
                                  hint: s.password,
                                  icon: Icons.lock_outline_rounded,
                                  obscure: true,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted:
                                      loading ? null : (_) => _submit(c.read()),
                                ),
                                const SizedBox(height: 22),
                                SizedBox(
                                  height: 54,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AdminTheme.primary,
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor:
                                          AdminTheme.primary.withOpacity(0.45),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed: loading
                                        ? null
                                        : () => _submit(c.read()),
                                    child: loading
                                        ? const SizedBox(
                                            height: 22,
                                            width: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(
                                            s.login,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                  ),
                                ),
                                if (state is AuthError) ...[
                                  const SizedBox(height: 14),
                                  Text(
                                    state.msg.contains('credentials')
                                        ? s.invalidCredentials
                                        : s.loginFailed,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            s.welcomeAdmin,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.28),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: AdminTheme.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: AdminTheme.primary.withOpacity(0.25),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Text(
                'W',
                style: TextStyle(
                  color: AdminTheme.primary,
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              Positioned(
                top: 14,
                child: Icon(
                  Icons.workspace_premium_rounded,
                  size: 16,
                  color: AdminTheme.gold.withOpacity(0.95),
                ),
              ),
              Positioned(
                bottom: 16,
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AdminTheme.gold,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Winning Admin',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowBlob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withOpacity(0)],
          ),
        ),
      ),
    );
  }
}
