import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:w1xbet_admin/features/matches/presentation/cubit/match_cubit.dart';
import 'package:w1xbet_admin/features/signals/presentation/cubit/signals_cubit.dart';

enum SplashStep {
  checkingInternet,
  checkingSupabase,
  loadingData,
  preparingHome,
  ready,
  error,
}

enum SplashErrorKind { noInternet, supabaseFailed, loadFailed }

class SplashState {
  final SplashStep step;
  final SplashErrorKind? errorKind;
  final double progress;

  const SplashState({
    this.step = SplashStep.checkingInternet,
    this.errorKind,
    this.progress = 0,
  });

  SplashState copyWith({
    SplashStep? step,
    SplashErrorKind? errorKind,
    double? progress,
    bool clearError = false,
  }) {
    return SplashState(
      step: step ?? this.step,
      errorKind: clearError ? null : (errorKind ?? this.errorKind),
      progress: progress ?? this.progress,
    );
  }
}

class SplashCubit extends Cubit<SplashState> {
  final MatchCubit matchCubit;
  final SignalsCubit signalsCubit;
  final SupabaseClient supabase;
  final Dio _dio;

  /// Project origin used for a real reachability probe.
  static const _supabaseOrigin = 'https://luhrfxruyybhjygbjvqa.supabase.co';

  SplashCubit({
    required this.matchCubit,
    required this.signalsCubit,
    required this.supabase,
    Dio? dio,
  })  : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 8),
                // Any status means the network path works.
                validateStatus: (_) => true,
              ),
            ),
        super(const SplashState());

  Future<void> bootstrap() async {
    emit(const SplashState(
      step: SplashStep.checkingInternet,
      progress: 0.1,
    ));

    try {
      await _ensureInternet();
      if (isClosed) return;

      emit(state.copyWith(
        step: SplashStep.checkingSupabase,
        progress: 0.35,
        clearError: true,
      ));
      await _ensureSupabase();
      if (isClosed) return;

      emit(state.copyWith(
        step: SplashStep.loadingData,
        progress: 0.55,
      ));
      await _loadInitialData();
      if (isClosed) return;

      emit(state.copyWith(
        step: SplashStep.preparingHome,
        progress: 0.9,
      ));
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (isClosed) return;

      emit(state.copyWith(
        step: SplashStep.ready,
        progress: 1,
      ));
    } on SplashException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        step: SplashStep.error,
        errorKind: e.kind,
        progress: state.progress,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        step: SplashStep.error,
        errorKind: _isNetworkError(e)
            ? SplashErrorKind.noInternet
            : SplashErrorKind.loadFailed,
        progress: state.progress,
      ));
    }
  }

  Future<void> retry() => bootstrap();

  /// Fast reachability check with a hard wall-clock timeout.
  /// Avoids hanging on DNS / Cloudflare when probing the API origin alone.
  Future<void> _ensureInternet() async {
    final probeOptions = Options(
      method: 'GET',
      sendTimeout: const Duration(seconds: 3),
      receiveTimeout: const Duration(seconds: 3),
      followRedirects: false,
      validateStatus: (_) => true,
    );

    const urls = <String>[
      // Designed for connectivity checks — usually fastest.
      'https://clients3.google.com/generate_204',
      'https://www.gstatic.com/generate_204',
      // Project host as last resort (may be slower behind Cloudflare).
      _supabaseOrigin,
    ];

    Object? lastError;
    for (final url in urls) {
      try {
        await _dio
            .get<void>(url, options: probeOptions)
            .timeout(const Duration(seconds: 4));
        return; // online
      } catch (e) {
        lastError = e;
      }
    }

    // All probes failed within their timeouts.
    if (lastError != null) {
      throw const SplashException(SplashErrorKind.noInternet);
    }
    throw const SplashException(SplashErrorKind.noInternet);
  }

  Future<void> _ensureSupabase() async {
    try {
      await supabase
          .from('signals')
          .select('id')
          .limit(1)
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw const SplashException(SplashErrorKind.supabaseFailed);
    } catch (e) {
      if (_isNetworkError(e)) {
        throw const SplashException(SplashErrorKind.noInternet);
      }
      throw const SplashException(SplashErrorKind.supabaseFailed);
    }
  }

  Future<void> _loadInitialData() async {
    try {
      await Future.wait([
        matchCubit.loadMatches(),
        signalsCubit.load(),
      ]).timeout(const Duration(seconds: 25));
      if (matchCubit.state is MatchError) {
        final msg = (matchCubit.state as MatchError).message;
        if (_isNetworkError(msg)) {
          throw const SplashException(SplashErrorKind.noInternet);
        }
        throw const SplashException(SplashErrorKind.loadFailed);
      }
      if (signalsCubit.state.error != null) {
        if (_isNetworkError(signalsCubit.state.error)) {
          throw const SplashException(SplashErrorKind.noInternet);
        }
        throw const SplashException(SplashErrorKind.loadFailed);
      }
      signalsCubit.startRealtime();
    } on SplashException {
      rethrow;
    } on TimeoutException {
      throw const SplashException(SplashErrorKind.loadFailed);
    } catch (e) {
      if (_isNetworkError(e)) {
        throw const SplashException(SplashErrorKind.noInternet);
      }
      throw const SplashException(SplashErrorKind.loadFailed);
    }
  }

  bool _isNetworkError(Object? error) {
    if (error == null) return false;
    if (error is DioException) {
      return error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError;
    }
    if (error is TimeoutException) return true;
    final text = error.toString().toLowerCase();
    return text.contains('socket') ||
        text.contains('network') ||
        text.contains('failed host lookup') ||
        text.contains('connection refused') ||
        text.contains('connection reset') ||
        text.contains('timed out') ||
        text.contains('timeout') ||
        text.contains('offline') ||
        text.contains('unreachable') ||
        text.contains('connection error');
  }
}

class SplashException implements Exception {
  final SplashErrorKind kind;
  const SplashException(this.kind);
}
