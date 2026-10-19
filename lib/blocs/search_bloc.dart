import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/show_repository.dart';
import '../models/show.dart';
import 'shows_bloc.dart';

class SearchChanged {
  final String query;
  SearchChanged(this.query);
}

class SearchState {
  final String query;
  final List<Show> shows;
  final LoadStatus status;
  final String? error;
  const SearchState({
    this.query = '',
    this.shows = const [],
    this.status = LoadStatus.initial,
    this.error,
  });
}

class SearchBloc extends Bloc<SearchChanged, SearchState> {
  final ShowRepository repository;
  Timer? _timer;
  int _revision = 0;
  SearchBloc(this.repository) : super(const SearchState()) {
    on<SearchChanged>((event, emit) async {
      _timer?.cancel();
      final revision = ++_revision;
      final query = event.query.trim();
      if (query.isEmpty) {
        emit(const SearchState());
        return;
      }
      emit(SearchState(query: query, status: LoadStatus.loading));
      // Wait for a pause in typing before making the request.
      final pause = Completer<void>();
      _timer = Timer(const Duration(milliseconds: 400), pause.complete);
      // An old timer is cancelled, so old handlers must also be allowed to end.
      await Future.any([
        pause.future,
        Future<void>.delayed(const Duration(milliseconds: 410)),
      ]);
      if (revision != _revision || emit.isDone) return;
      try {
        final results = await repository.search(query);
        if (revision != _revision || emit.isDone) return;
        emit(
          SearchState(
            query: query,
            shows: results,
            status: results.isEmpty ? LoadStatus.empty : LoadStatus.success,
          ),
        );
      } catch (e) {
        if (revision == _revision && !emit.isDone) {
          emit(
            SearchState(
              query: query,
              status: LoadStatus.error,
              error: e.toString(),
            ),
          );
        }
      }
    });
  }
  @override
  Future<void> close() {
    _timer?.cancel();
    _revision++;
    return super.close();
  }
}
