import 'package:w1xbet_admin/features/matches/domain/entities/create_match.dart';

import '../entities/match.dart';

abstract class MatchRepository {
  Future<List<Match>> getTodayMatches({String? sport});
  Future<void> createMatch(CreateMatch match);
  Future<void> updateManualMatch({required int id, required CreateMatch match});
  Future<void> deleteManualMatch(int id);
}
