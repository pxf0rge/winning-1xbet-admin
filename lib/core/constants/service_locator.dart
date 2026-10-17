import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:w1xbet_admin/features/matches/domain/usecases/create_match_usecase.dart';
import 'package:w1xbet_admin/features/matches/presentation/cubit/create_match_cubit.dart';

// ================= CORE =================

import '../network/api_client.dart';

// ================= AUTH FEATURE =================

import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';

// ================= MATCHES FEATURE =================

import '../../features/matches/data/datasources/match_remote_datasource.dart';
import '../../features/matches/data/repositories/match_repository_impl.dart';
import '../../features/matches/domain/repositories/match_repository.dart';
import '../../features/matches/domain/usecases/get_matches_usecase.dart';
import '../../features/matches/presentation/cubit/match_cubit.dart';

// ================= SIGNALS FEATURE =================

import '../../features/signals/data/datasource/signal_remote_datasource.dart';
import '../../features/signals/data/repositories/signal_repository_impl.dart';
import '../../features/signals/domain/repositories/signal_repository.dart';
import '../../features/signals/domain/usecases/get_pending_signals_usecase.dart';
import '../../features/signals/presentation/cubit/add_signal_cubit.dart';
import '../../features/signals/presentation/cubit/signals_cubit.dart';
import '../l10n/admin_l10n.dart';

// ================= ARCHIVE FEATURE =================

import 'package:w1xbet_admin/features/archive/data/datasource/archive_remote_datasource.dart';
import 'package:w1xbet_admin/features/archive/data/repositories/archive_repository_impl.dart';
import 'package:w1xbet_admin/features/archive/domain/repositories/archive_repository.dart';
import 'package:w1xbet_admin/features/archive/domain/usecases/get_archive_signals.dart';
import 'package:w1xbet_admin/features/archive/presentation/cubit/archive_cubit.dart';

// ==================================================

final sl = GetIt.instance;

/// Initializes all dependencies for the application
Future<void> init() async {
  // ================= CORE =================

  /// Dio HTTP client
  sl.registerLazySingleton<Dio>(() => Dio());

  /// API Client wrapper
  sl.registerLazySingleton<ApiClient>(() => ApiClient());

  /// Supabase Client
  sl.registerLazySingleton(() => Supabase.instance.client);

  // ================= AUTH =================

  sl.registerLazySingleton(() => AuthRemoteDataSource(sl()));
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerFactory(() => AuthCubit(sl()));

  // ================= MATCHES =================

  sl.registerLazySingleton(() => MatchRemoteDatasource(sl()));
  sl.registerLazySingleton<MatchRepository>(() => MatchRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetMatchesUseCase(sl()));
  sl.registerLazySingleton(() => MatchCubit(sl(), sl()));

  // ================= SIGNALS =================

  sl.registerLazySingleton(() => SignalRemoteDatasource(sl()));
  sl.registerLazySingleton<SignalRepository>(() => SignalRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetPendingSignalsUsecase(sl()));
  sl.registerFactory(() => AddSignalCubit(sl()));
  sl.registerLazySingleton(() => SignalsCubit(sl())..startRealtime());

  // ================= LOCALE =================
  sl.registerLazySingleton(() => LocaleCubit());

  // ================= ARCHIVE =================

  sl.registerLazySingleton(() => ArchiveSupabaseDatasource(sl()));
  sl.registerLazySingleton<ArchiveRepository>(
    () => ArchiveRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetArchiveSignals(sl()));
  sl.registerFactory(() => ArchiveCubit(sl()));

  sl.registerLazySingleton(() => CreateMatchUseCase(sl()));
  sl.registerFactory(() => CreateMatchCubit(sl<MatchRepository>()));
}
