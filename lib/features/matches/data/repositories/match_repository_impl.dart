import 'package:w1xbet_admin/features/matches/domain/entities/create_match.dart';

import '../../domain/repositories/match_repository.dart';
import '../../domain/entities/match.dart';
import '../datasources/match_remote_datasource.dart';

class MatchRepositoryImpl implements MatchRepository {
  final MatchRemoteDatasource remote;

  MatchRepositoryImpl(this.remote);

  @override
  Future<List<Match>> getTodayMatches({String? sport}) {
    return remote.getMatches(sport: sport);
  }

  @override
  Future<void> createMatch(CreateMatch match) {
    return remote.createMatch(match);
  }

  @override
  Future<void> updateManualMatch({
    required int id,
    required CreateMatch match,
  }) {
    return remote.updateManualMatch(id: id, match: match);
  }

  @override
  Future<void> deleteManualMatch(int id) {
    return remote.deleteManualMatch(id);
  }
}
