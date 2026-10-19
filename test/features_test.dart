import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tv_maze/blocs/search_bloc.dart';
import 'package:tv_maze/blocs/shows_bloc.dart';
import 'package:tv_maze/blocs/watchlist_bloc.dart';
import 'package:tv_maze/data/show_repository.dart';
import 'package:tv_maze/data/watchlist_repository.dart';
import 'package:tv_maze/models/show.dart';

// Fictional fixtures belong only in tests; the application always uses the API.
Map<String, dynamic> fixture(int id) => {
  'id': id,
  'name': 'Test show $id',
  'summary': '<p>A &amp; B</p>',
};
void main() {
  test('Missing fields are safe and summary HTML is decoded', () {
    final show = Show.fromJson(fixture(1));
    expect(show.summary, 'A & B');
    expect(show.rating, isNull);
    expect(show.genres, isEmpty);
    expect(Show.fromJson(show.toJson()).name, show.name);
  });
  test(
    'Pagination retains shows on failure and retries the same page',
    () async {
      final pages = <String?>[];
      var fail = true;
      final client = MockClient((request) async {
        final page = request.url.queryParameters['page'];
        pages.add(page);
        if (page == '0') return http.Response(jsonEncode([fixture(1)]), 200);
        if (fail) {
          fail = false;
          return http.Response('', 500);
        }
        return http.Response('', 404);
      });
      final bloc = ShowsBloc(ShowRepository(client));
      bloc.add(ShowsRequested());
      await bloc.stream.firstWhere((s) => s.status == LoadStatus.success);
      bloc.add(ShowsRequested());
      final failed = await bloc.stream.firstWhere((s) => s.error != null);
      expect(failed.shows.single.id, 1);
      bloc.add(ShowsRequested());
      await bloc.stream.firstWhere((s) => !s.hasMore);
      expect(pages, ['0', '1', '1']);
      await bloc.close();
      client.close();
    },
  );
  test('Search debounces typing and ignores an older response', () async {
    final queries = <String?>[];
    final client = MockClient((request) async {
      final q = request.url.queryParameters['q'];
      queries.add(q);
      if (q == 'old') {
        await Future<void>.delayed(const Duration(milliseconds: 700));
      }
      return http.Response(
        jsonEncode([
          {'show': fixture(q == 'old' ? 1 : 2)},
        ]),
        200,
      );
    });
    final bloc = SearchBloc(ShowRepository(client));
    bloc.add(SearchChanged('o'));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    bloc.add(SearchChanged('old'));
    await Future<void>.delayed(const Duration(milliseconds: 470));
    bloc.add(SearchChanged('new'));
    await bloc.stream.firstWhere(
      (s) => s.status == LoadStatus.success && s.query == 'new',
    );
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(queries, ['old', 'new']);
    expect(bloc.state.shows.single.id, 2);
    bloc.add(SearchChanged('   '));
    await bloc.stream.firstWhere((s) => s.status == LoadStatus.initial);
    expect(bloc.state.shows, isEmpty);
    await bloc.close();
    client.close();
  });
  test('Watchlist survives a new BLoC and can be removed', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = WatchlistRepository(
      await SharedPreferences.getInstance(),
    );
    final bloc = WatchlistBloc(repository)..add(WatchlistLoaded());
    await bloc.stream.firstWhere((s) => s.status == LoadStatus.empty);
    bloc.add(WatchlistToggled(Show.fromJson(fixture(1))));
    await bloc.stream.firstWhere((s) => s.shows.isNotEmpty);
    await bloc.close();
    final restarted = WatchlistBloc(repository)..add(WatchlistLoaded());
    await restarted.stream.firstWhere((s) => s.status == LoadStatus.success);
    expect(restarted.state.contains(1), isTrue);
    restarted.add(WatchlistToggled(restarted.state.shows.single));
    await restarted.stream.firstWhere((s) => s.status == LoadStatus.empty);
    expect(repository.load(), isEmpty);
    await restarted.close();
  });
}
