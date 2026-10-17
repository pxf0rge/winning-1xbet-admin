import 'package:w1xbet_admin/features/matches/domain/entities/create_match.dart';
import 'package:w1xbet_admin/features/matches/domain/repositories/match_repository.dart';

class CreateMatchUseCase {
  final MatchRepository repository;

  CreateMatchUseCase(this.repository);

  Future<void> call(CreateMatch match) {
    return repository.createMatch(match);
  }
}
