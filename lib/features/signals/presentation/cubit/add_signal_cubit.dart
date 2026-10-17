import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/signal_repository.dart';

class AddSignalCubit extends Cubit<bool> {
  final SignalRepository repo;

  AddSignalCubit(this.repo) : super(false);

  Future<bool> submit({
    required String matchId,
    required String betType,
    required String betValue,
    required String signalType,
    required String status,
    required String leagueName,
    required String gameDate,
    required String sport,
    double? odds,
    String? settlementType,
    bool isFeatured = true,
    String? analysis,
    bool isNew = false,
  }) async {
    if (!isClosed) emit(true);
    try {
      await repo.upsertSignal(
        matchId: matchId,
        betType: betType,
        betValue: betValue,
        signalType: signalType,
        status: status,
        leagueName: leagueName,
        gameDate: gameDate,
        sport: sport,
        odds: odds,
        settlementType: settlementType,
        isFeatured: isFeatured,
        analysis: analysis,
      );

      if (isNew && status.toUpperCase() == 'PENDING') {
        await _autoNotifyNewSignal(
          signalType: signalType,
          betValue: betValue,
          leagueName: leagueName,
          odds: odds,
        );
      }

      if (signalType.toUpperCase() == 'VIP' &&
          status.toUpperCase() == 'WIN') {
        await _maybeNotifyVipPerfectDay(gameDate);
      }

      return true;
    } catch (_) {
      rethrow;
    } finally {
      if (!isClosed) emit(false);
    }
  }

  Future<void> _autoNotifyNewSignal({
    required String signalType,
    required String betValue,
    required String leagueName,
    double? odds,
  }) async {
    final audience = signalType.toUpperCase() == 'VIP' ? 'vip' : 'free';
    final title = signalType.toUpperCase() == 'VIP'
        ? 'New VIP Signal'
        : 'New Free Signal';
    final oddsText = odds != null ? ' @ $odds' : '';
    final body = '$leagueName · $betValue$oddsText';

    await Supabase.instance.client.from('admin_notifications').insert({
      'title': title,
      'body': body,
      'audience': audience,
      'created_by': Supabase.instance.client.auth.currentUser?.id,
    });
  }

  Future<void> _maybeNotifyVipPerfectDay(String gameDate) async {
    final res = await Supabase.instance.client
        .from('signals')
        .select('status, odds')
        .eq('signal_type', 'VIP')
        .eq('game_date', gameDate);

    final list = List<Map<String, dynamic>>.from(res as List);
    if (list.isEmpty) return;

    final allSettled = list.every((e) {
      final s = (e['status']?.toString() ?? '').toUpperCase();
      return s == 'WIN' || s == 'LOSE' || s == 'VOID';
    });
    if (!allSettled) return;

    final wins = list.where((e) => (e['status']?.toString() ?? '').toUpperCase() == 'WIN');
    final loses = list.where((e) => (e['status']?.toString() ?? '').toUpperCase() == 'LOSE');
    if (loses.isNotEmpty) return;
    if (wins.isEmpty) return;

    double oddsSum = 1;
    for (final w in wins) {
      final o = w['odds'];
      if (o is num) oddsSum *= o.toDouble();
    }

    await Supabase.instance.client.from('admin_notifications').insert({
      'title': 'VIP Perfect Day!',
      'body':
          '${wins.length} wins · Accumulated odds ${oddsSum.toStringAsFixed(2)}',
      'audience': 'vip',
      'created_by': Supabase.instance.client.auth.currentUser?.id,
    });
  }
}
