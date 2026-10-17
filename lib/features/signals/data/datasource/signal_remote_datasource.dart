import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/signal_model.dart';

class SignalRemoteDatasource {
  final SupabaseClient client;

  SignalRemoteDatasource(this.client);

  Future<List<SignalModel>> getSignalsByMatch(String matchId) async {
    final id = int.tryParse(matchId);
    if (id == null) {
      throw FormatException('Invalid matchId: $matchId');
    }
    final res = await client.from('signals').select().eq('match_id', id);

    return _enrichWithTeams(
      (res as List).map((e) => SignalModel.fromJson(e)).toList(),
    );
  }

  Future<void> upsertSignal({
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
  }) async {
    final id = int.tryParse(matchId);
    if (id == null) {
      throw FormatException('Invalid matchId: $matchId');
    }
    await client.from('signals').upsert({
      'match_id': id,
      'bet_type': betType,
      'bet_value': betValue,
      'signal_type': signalType,
      'status': status,
      'league_name': leagueName,
      'game_date': gameDate,
      'sport': sport,
      'odds': odds,
      'settlement_type': settlementType,
      'is_featured': isFeatured,
      'analysis': analysis,
    }, onConflict: 'match_id,signal_type');
  }

  Future<List<SignalModel>> getPendingSignals() async {
    final res = await client.from('signals').select().eq('status', 'PENDING');

    return _enrichWithTeams(
      (res as List).map((e) => SignalModel.fromJson(e)).toList(),
    );
  }

  Future<List<SignalModel>> getAllSignals() async {
    final res = await client
        .from('signals')
        .select()
        .order('created_at', ascending: false);

    return _enrichWithTeams(
      (res as List).map((e) => SignalModel.fromJson(e)).toList(),
    );
  }

  Future<List<SignalModel>> _enrichWithTeams(List<SignalModel> signals) async {
    if (signals.isEmpty) return signals;

    final ids = signals
        .map((s) => s.matchId.toString())
        .toSet()
        .toList(growable: false);

    final Map<String, ({String home, String away})> teams = {};

    // Chunk to avoid URL length limits on large lists.
    for (var i = 0; i < ids.length; i += 100) {
      final chunk = ids.sublist(i, i + 100 > ids.length ? ids.length : i + 100);
      final res = await client
          .from('v_all_matches')
          .select('game_id, home_team, away_team')
          .inFilter('game_id', chunk);

      for (final row in (res as List)) {
        final id = row['game_id']?.toString();
        if (id == null) continue;
        teams[id] = (
          home: row['home_team']?.toString() ?? '',
          away: row['away_team']?.toString() ?? '',
        );
      }
    }

    return signals.map((s) {
      final t = teams[s.matchId.toString()];
      if (t == null) return s;
      if (t.home.isEmpty && t.away.isEmpty) return s;
      return s.withTeams(homeTeam: t.home, awayTeam: t.away);
    }).toList();
  }
}
