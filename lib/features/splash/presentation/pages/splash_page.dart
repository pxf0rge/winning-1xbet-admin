import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:w1xbet_admin/core/l10n/admin_l10n.dart';
import 'package:w1xbet_admin/core/theme/admin_theme.dart';
import 'package:w1xbet_admin/features/matches/presentation/cubit/match_cubit.dart';
import 'package:w1xbet_admin/features/navigation/presentation/pages/home_page.dart';
import 'package:w1xbet_admin/features/signals/presentation/cubit/signals_cubit.dart';
import 'package:w1xbet_admin/features/splash/presentation/cubit/splash_cubit.dart';

/// Bootstrap splash: internet → Supabase → initial data → build home → HomePage.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SplashCubit(
        matchCubit: context.read<MatchCubit>(),
        signalsCubit: context.read<SignalsCubit>(),
        supabase: Supabase.instance.client,
      )..bootstrap(),
      child: const _SplashView(),
    );
  }
}

class _SplashView extends StatefulWidget {
  const _SplashView();

  @override
  State<_SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<_SplashView>
    with SingleTickerProviderStateMixin {
  bool _ready = false;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  String _stepLabel(S s, SplashStep step) {
    switch (step) {
      case SplashStep.checkingInternet:
        return s.splashCheckingInternet;
      case SplashStep.checkingSupabase:
        return s.splashCheckingSupabase;
      case SplashStep.loadingData:
        return s.splashLoadingData;
      case SplashStep.preparingHome:
        return s.splashPreparingHome;
      case SplashStep.ready:
        return s.splashReady;
      case SplashStep.error:
        return s.error;
    }
  }

  String _errorLabel(S s, SplashErrorKind? kind) {
    switch (kind) {
      case SplashErrorKind.noInternet:
        return s.splashNoInternet;
      case SplashErrorKind.supabaseFailed:
        return s.splashSupabaseFailed;
      case SplashErrorKind.loadFailed:
        return s.splashLoadFailed;
      case null:
        return s.splashNoInternet;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return const HomePage();

    final s = S.of(context);

    return BlocConsumer<SplashCubit, SplashState>(
      listenWhen: (prev, next) =>
          prev.step != next.step && next.step == SplashStep.ready,
      listener: (context, state) {
        setState(() => _ready = true);
      },
      builder: (context, state) {
        final isError = state.step == SplashStep.error;
        final size = MediaQuery.sizeOf(context);

        return Stack(
          children: [
            // Prebuild HomePage off-screen once data is ready.
            if (state.step == SplashStep.preparingHome)
              Positioned(
                left: -size.width * 2,
                top: 0,
                width: size.width,
                height: size.height,
                child: const HomePage(),
              ),
            Scaffold(
              backgroundColor: AdminTheme.navy,
              body: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF102448),
                      AdminTheme.navy,
                      Color(0xFF071226),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        const Spacer(flex: 2),
                        ScaleTransition(
                          scale: Tween<double>(begin: 0.94, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _pulse,
                              curve: Curves.easeInOut,
                            ),
                          ),
                          child: Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AdminTheme.primary,
                                  Color(0xFF1565C0),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AdminTheme.primary.withValues(alpha: 0.35),
                                  blurRadius: 28,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.sports_soccer,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          s.splashAppName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          s.isFa
                              ? 'پنل مدیریت سیگنال‌ها'
                              : 'Signals Admin Panel',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(flex: 2),
                        if (isError) ...[
                          Icon(
                            Icons.wifi_off_rounded,
                            size: 40,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorLabel(s, state.errorKind),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  context.read<SplashCubit>().retry(),
                              icon: const Icon(Icons.refresh),
                              label: Text(s.retry),
                            ),
                          ),
                        ] else ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: state.progress.clamp(0.05, 1),
                              minHeight: 6,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.08),
                              color: AdminTheme.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            child: Text(
                              _stepLabel(s, state.step),
                              key: ValueKey(state.step),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(flex: 1),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
