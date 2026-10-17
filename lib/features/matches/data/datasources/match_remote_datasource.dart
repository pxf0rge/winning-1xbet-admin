import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:w1xbet_admin/core/constants/match_create_status.dart';
import 'package:w1xbet_admin/features/matches/domain/entities/create_match.dart';
import 'package:w1xbet_admin/features/matches/domain/exceptions/duplicate_match_exception.dart';
import '../models/match_model.dart';

class MatchRemoteDatasource {
  final SupabaseClient client;

  MatchRemoteDatasource(this.client);

  Future<List<MatchModel>> getMatches({String? sport}) async {
    var query = client.from('v_all_matches').select();

    if (sport != null && sport.isNotEmpty) {
      query = query.eq('sport', sport);
    }

    final res = await query.order('game_date', ascending: false);

    return (res as List)
        .map((e) => MatchModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> createMatch(CreateMatch match) async {
    await _assertNotDuplicate(match);
    try {
      await client.from('manual_matches').insert({
        'sport': match.sport,
        'league_name': match.leagueName,
        'home_team': match.homeTeam,
        'away_team': match.awayTeam,
        'status': match.status.label,
        'home_score': match.homeScore,
        'away_score': match.awayScore,
        'start_time': _buildStartTime(match),
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw DuplicateMatchException(
          'A match with the same teams and date already exists',
        );
      }
      rethrow;
    }
  }

  Future<void> updateManualMatch({
    required int id,
    required CreateMatch match,
  }) async {
    await _assertNotDuplicate(match, excludeId: id);
    try {
      await client.from('manual_matches').update({
        'sport': match.sport,
        'league_name': match.leagueName,
        'home_team': match.homeTeam,
        'away_team': match.awayTeam,
        'status': match.status.label,
        'home_score': match.homeScore,
        'away_score': match.awayScore,
        'start_time': _buildStartTime(match),
      }).eq('id', id);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw DuplicateMatchException(
          'A match with the same teams and date already exists',
        );
      }
      rethrow;
    }
  }

  /// Deletes a manual match and voids linked PENDING signals (DB RPC + trigger).
  Future<void> deleteManualMatch(int id) async {
    await client.rpc('delete_manual_match', params: {'p_id': id});
  }

  /// Soft cleanup via RPC (finished manual matches older than [daysOld]).
  Future<int> cleanupOldMatches({int daysOld = 7}) async {
    final res = await client.rpc(
      'cleanup_old_manual_matches',
      params: {'days_old': daysOld},
    );
    if (res is int) return res;
    return int.tryParse(res?.toString() ?? '') ?? 0;
  }

  Future<void> _assertNotDuplicate(
    CreateMatch match, {
    int? excludeId,
  }) async {
    final date = (match.date ?? '').trim();
    final home = match.homeTeam.trim().toLowerCase();
    final away = match.awayTeam.trim().toLowerCase();
    final sport = match.sport.trim().toLowerCase();

    // Check unified view first (API + manual)
    final existing = await client
        .from('v_all_matches')
        .select('game_id, home_team, away_team, sport, game_date, is_manual')
        .eq('game_date', date);

    for (final row in (existing as List)) {
      final m = Map<String, dynamic>.from(row as Map);
      final h = (m['home_team']?.toString() ?? '').trim().toLowerCase();
      final a = (m['away_team']?.toString() ?? '').trim().toLowerCase();
      final s = (m['sport']?.toString() ?? '').trim().toLowerCase();
      final id = m['game_id']?.toString();

      final sameTeams =
          (h == home && a == away) || (h == away && a == home);
      if (!sameTeams) continue;
      if (s.isNotEmpty && sport.isNotEmpty && s != sport) continue;

      if (excludeId != null &&
          m['is_manual'] == true &&
          id == excludeId.toString()) {
        continue;
      }

      throw DuplicateMatchException(
        'Match already exists: ${m['home_team']} vs ${m['away_team']} on $date',
      );
    }
  }

  String _buildStartTime(CreateMatch match) {
    if (match.status == CreateMatchStatus.upcoming) {
      final time = (match.time == null || match.time!.isEmpty)
          ? '00:00'
          : match.time!;
      return '${match.date} $time:00';
    }
    return DateTime.now().toUtc().toIso8601String();
  }
}
