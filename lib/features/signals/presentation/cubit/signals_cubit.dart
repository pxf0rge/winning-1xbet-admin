import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:w1xbet_admin/core/utils/debouncer.dart';
import 'package:w1xbet_admin/features/signals/domain/entities/signal.dart';
import 'package:w1xbet_admin/features/signals/domain/repositories/signal_repository.dart';

class SignalsState {
  final List<Signal> signals;
  final bool loading;
  final String? error;
  final String statusFilter; // ALL | PENDING | WIN | LOSE | VOID

  const SignalsState({
    this.signals = const [],
    this.loading = false,
    this.error,
    this.statusFilter = 'PENDING',
  });

  SignalsState copyWith({
    List<Signal>? signals,
    bool? loading,
    String? error,
    String? statusFilter,
    bool clearError = false,
  }) {
    return SignalsState(
      signals: signals ?? this.signals,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}

class SignalsCubit extends Cubit<SignalsState> {
  final SignalRepository repository;
  RealtimeChannel? _channel;
  final _reloadDebounce = Debouncer();
  bool hasLoaded = false;

  SignalsCubit(this.repository) : super(const SignalsState());

  Future<void> load({bool silent = false}) async {
    if (!silent) emit(state.copyWith(loading: true, clearError: true));
    try {
      final data = await repository.getAllSignals();
      if (isClosed) return;
      hasLoaded = true;
      emit(state.copyWith(signals: data, loading: false, clearError: true));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  void setStatusFilter(String filter) {
    if (!isClosed) emit(state.copyWith(statusFilter: filter));
  }

  List<Signal> filtered({required String type}) {
    return state.signals.where((e) {
      final typeOk = e.signalType.toUpperCase() == type.toUpperCase();
      final statusOk = state.statusFilter == 'ALL' ||
          e.status.toUpperCase() == state.statusFilter.toUpperCase();
      return typeOk && statusOk;
    }).toList();
  }

  void startRealtime() {
    stopRealtime();
    _channel = Supabase.instance.client
        .channel('admin_signals')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'signals',
          callback: (_) {
            if (isClosed) return;
            _reloadDebounce.run(() => load(silent: true));
          },
        )
        .subscribe();
  }

  Future<void> stopRealtime() async {
    _reloadDebounce.cancel();
    if (_channel != null) {
      await Supabase.instance.client.removeChannel(_channel!);
      _channel = null;
    }
  }

  @override
  Future<void> close() async {
    _reloadDebounce.dispose();
    await stopRealtime();
    return super.close();
  }
}
