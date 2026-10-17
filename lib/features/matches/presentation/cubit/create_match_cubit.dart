import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:w1xbet_admin/features/matches/domain/entities/create_match.dart';
import 'package:w1xbet_admin/features/matches/domain/repositories/match_repository.dart';

class CreateMatchCubit extends Cubit<bool> {
  final MatchRepository repository;

  CreateMatchCubit(this.repository) : super(false);

  Future<void> submit(CreateMatch match, {int? editId}) async {
    emit(true);
    try {
      if (editId != null) {
        await repository.updateManualMatch(id: editId, match: match);
      } else {
        await repository.createMatch(match);
      }
    } catch (e) {
      rethrow;
    } finally {
      emit(false);
    }
  }

  Future<void> deleteManual(int id) async {
    emit(true);
    try {
      await repository.deleteManualMatch(id);
    } catch (e) {
      rethrow;
    } finally {
      emit(false);
    }
  }
}
