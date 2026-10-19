import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';

import '../data/watchlist_repository.dart';
import '../models/show.dart';
import 'shows_bloc.dart';

abstract class WatchlistEvent {}

class WatchlistLoaded extends WatchlistEvent {}

class WatchlistToggled extends WatchlistEvent {
  final Show show;
  WatchlistToggled(this.show);
}

class WatchlistState {
  final List<Show> shows;
  final LoadStatus status;
  final String? error;
  const WatchlistState({
    this.shows = const [],
    this.status = LoadStatus.initial,
    this.error,
  });
  bool contains(int id) => shows.any((s) => s.id == id);
}

class WatchlistBloc extends Bloc<WatchlistEvent, WatchlistState> {
  WatchlistBloc(WatchlistRepository repository)
    : super(const WatchlistState()) {
    on<WatchlistEvent>((event, emit) async {
      if (event is WatchlistLoaded) {
        emit(const WatchlistState(status: LoadStatus.loading));
        try {
          final shows = repository.load();
          emit(
            WatchlistState(
              shows: shows,
              status: shows.isEmpty ? LoadStatus.empty : LoadStatus.success,
            ),
          );
        } catch (_) {
          emit(
            const WatchlistState(
              status: LoadStatus.error,
              error: 'Could not read your saved watchlist. Retry loading it.',
            ),
          );
        }
      } else if (event is WatchlistToggled) {
        if (state.status == LoadStatus.error ||
            state.status == LoadStatus.loading ||
            state.status == LoadStatus.initial) {
          return;
        }
        final updated = [...state.shows];
        if (state.contains(event.show.id)) {
          updated.removeWhere((s) => s.id == event.show.id);
        } else {
          updated.add(event.show);
        }
        try {
          await repository.save(updated);
          emit(
            WatchlistState(
              shows: updated,
              status: updated.isEmpty ? LoadStatus.empty : LoadStatus.success,
            ),
          );
        } catch (_) {
          emit(
            WatchlistState(
              shows: state.shows,
              status: state.status,
              error: 'Could not save the change. Please try again.',
            ),
          );
        }
      }
    }, transformer: sequential());
  }
}
