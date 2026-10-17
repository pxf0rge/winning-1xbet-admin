import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:w1xbet_admin/features/signals/domain/repositories/signal_repository.dart';

import '../../domain/usecases/get_matches_usecase.dart';
import '../../domain/entities/match.dart';

/// ----------------------------
/// Match States
/// ----------------------------

abstract class MatchState {}

class MatchInitial extends MatchState {}

class MatchLoading extends MatchState {}

class MatchLoaded extends MatchState {
  final List<Match> matches;
  MatchLoaded(this.matches);
}

class MatchError extends MatchState {
  final String message;
  MatchError(this.message);
}

/// ----------------------------
/// Match Cubit
/// ----------------------------
/// Responsible for:
/// - Loading today's matches
/// - Fetching signals of a match
class MatchCubit extends Cubit<MatchState> {
  final GetMatchesUseCase getMatchesUseCase;
  final SignalRepository signalRepository;

  MatchCubit(this.getMatchesUseCase, this.signalRepository)
    : super(MatchInitial());

  /// Load today's matches
  Future<void> loadMatches({String? sport}) async {
    if (!isClosed) emit(MatchLoading());

    try {
      final matches = await getMatchesUseCase(sport: sport);
      if (isClosed) return;
      emit(MatchLoaded(matches));
    } catch (e) {
      if (isClosed) return;
      emit(MatchError(e.toString()));
    }
  }

  /// Get all signals related to a match
  Future<List> getMatchSignals(String matchId) {
    return signalRepository.getMatchSignals(matchId);
  }

  /// Get a specific match by ID
  Match? getMatchById(String matchId) {
    if (state is MatchLoaded) {
      final matches = (state as MatchLoaded).matches;
      try {
        return matches.firstWhere((m) => m.id == matchId);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}
