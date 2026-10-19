import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';

import '../data/show_repository.dart';
import '../models/show.dart';

enum LoadStatus { initial, loading, success, empty, error }

class ShowsRequested {
  final bool refresh;
  ShowsRequested({this.refresh = false});
}

class ShowsState {
  final List<Show> shows;
  final LoadStatus status;
  final bool loadingMore, hasMore;
  final String? error;
  const ShowsState({
    this.shows = const [],
    this.status = LoadStatus.initial,
    this.loadingMore = false,
    this.hasMore = true,
    this.error,
  });
}

class ShowsBloc extends Bloc<ShowsRequested, ShowsState> {
  final ShowRepository repository;
  int _page = 0;
  ShowsBloc(this.repository) : super(const ShowsState()) {
    on<ShowsRequested>((event, emit) async {
      if (!event.refresh && !state.hasMore) return;
      final old = event.refresh ? <Show>[] : state.shows;
      final page = event.refresh ? 0 : _page;
      emit(
        ShowsState(
          shows: old,
          status: old.isEmpty ? LoadStatus.loading : LoadStatus.success,
          loadingMore: old.isNotEmpty,
        ),
      );
      try {
        final next = await repository.shows(page);
        final combined = [...old, ...next];
        _page = page + 1;
        emit(
          ShowsState(
            shows: combined,
            status: combined.isEmpty ? LoadStatus.empty : LoadStatus.success,
            hasMore: next.isNotEmpty,
          ),
        );
      } catch (e) {
        emit(
          ShowsState(
            shows: old,
            status: old.isEmpty ? LoadStatus.error : LoadStatus.success,
            error: e.toString(),
          ),
        );
      }
    }, transformer: droppable());
  }
}
