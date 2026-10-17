import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:w1xbet_admin/core/constants/service_locator.dart';
import 'package:w1xbet_admin/core/l10n/admin_l10n.dart';
import 'package:w1xbet_admin/core/theme/admin_theme.dart';
import 'package:w1xbet_admin/core/widgets/auth_gate.dart';
import 'package:w1xbet_admin/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:w1xbet_admin/features/matches/presentation/cubit/match_cubit.dart';
import 'package:w1xbet_admin/features/signals/presentation/cubit/add_signal_cubit.dart';
import 'package:w1xbet_admin/features/signals/presentation/cubit/signals_cubit.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(create: (_) => sl<AuthCubit>()),
        BlocProvider<MatchCubit>.value(value: sl<MatchCubit>()),
        BlocProvider<AddSignalCubit>(create: (_) => sl<AddSignalCubit>()),
        BlocProvider<SignalsCubit>.value(value: sl<SignalsCubit>()),
        BlocProvider<LocaleCubit>.value(value: sl<LocaleCubit>()),
      ],
      child: BlocBuilder<LocaleCubit, Locale>(
        builder: (context, locale) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AdminTheme.dark,
            locale: locale,
            supportedLocales: const [Locale('fa'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              return Directionality(
                textDirection: locale.languageCode == 'fa'
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: child!,
              );
            },
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}
