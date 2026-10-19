import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';

import '../models/show.dart';
import '../data/show_repository.dart';
import 'shows_bloc.dart';

class DetailsRequested {
  final int id;
  DetailsRequested(this.id);
}

class DetailsState {
  final LoadStatus status;
  final Show? show;
  final List<CastMember> cast;
  final List<Episode> episodes;
  final String? error, castError, episodesError;
  const DetailsState({
    this.status = LoadStatus.initial,
    this.show,
    this.cast = const [],
    this.episodes = const [],
    this.error,
    this.castError,
    this.episodesError,
  });
}

class DetailsBloc extends Bloc<DetailsRequested, DetailsState> {
  DetailsBloc(ShowRepository repository) : super(const DetailsState()) {
    on<DetailsRequested>((event, emit) async {
      emit(const DetailsState(status: LoadStatus.loading));
      try {
        final show = await repository.details(event.id);
        List<CastMember> cast = [];
        List<Episode> episodes = [];
        String? castError, episodesError;
        // Extra information can fail without hiding the show's overview.
        await Future.wait([
          () async {
            try {
              cast = await repository.cast(event.id);
            } catch (e) {
              castError = e.toString();
            }
          }(),
          () async {
            try {
              episodes = await repository.episodes(event.id);
            } catch (e) {
              episodesError = e.toString();
            }
          }(),
        ]);
        emit(
          DetailsState(
            status: LoadStatus.success,
            show: show,
            cast: cast,
            episodes: episodes,
            castError: castError,
            episodesError: episodesError,
          ),
        );
      } catch (e) {
        emit(DetailsState(status: LoadStatus.error, error: e.toString()));
      }
    }, transformer: droppable());
  }
}
