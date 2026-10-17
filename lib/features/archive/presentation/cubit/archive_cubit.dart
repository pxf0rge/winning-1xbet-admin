import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:w1xbet_admin/features/archive/domain/usecases/get_archive_signals.dart';
import 'package:w1xbet_admin/features/signals/data/models/signal_model.dart';

abstract class ArchiveState {}

class ArchiveLoading extends ArchiveState {}

class ArchiveLoaded extends ArchiveState {
  final List<SignalModel> signals;
  ArchiveLoaded(this.signals);
}

class ArchiveError extends ArchiveState {
  final String message;
  ArchiveError(this.message);
}

class ArchiveCubit extends Cubit<ArchiveState> {
  final GetArchiveSignals getArchive;

  ArchiveCubit(this.getArchive) : super(ArchiveLoading());

  Future<void> load() async {
    emit(ArchiveLoading());
    try {
      final data = await getArchive();
      emit(ArchiveLoaded(data));
    } catch (e) {
      emit(ArchiveError(e.toString()));
    }
  }
}
