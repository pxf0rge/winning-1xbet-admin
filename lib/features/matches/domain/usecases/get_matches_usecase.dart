import '../repositories/match_repository.dart';
import '../entities/match.dart';

class GetMatchesUseCase {
  final MatchRepository repo;

  GetMatchesUseCase(this.repo);

  Future<List<Match>> call({String? sport}) {
    return repo.getTodayMatches(sport: sport);
  }
}
