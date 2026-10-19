import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tv_maze/main.dart';
import 'package:tv_maze/data/show_repository.dart';
import 'package:tv_maze/data/watchlist_repository.dart';

void main() {
  testWidgets('Navigate to search and empty watchlist', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final client = MockClient((_) async => http.Response('[]', 200));
    await tester.pumpWidget(
      TVMazeApp(
        repository: ShowRepository(client),
        watchlistRepository: WatchlistRepository(
          await SharedPreferences.getInstance(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Search').last);
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    await tester.tap(find.text('Watchlist').last);
    await tester.pumpAndSettle();
    expect(find.text('Your watchlist is empty'), findsOneWidget);
    await tester.tap(find.text('Explore shows'));
    await tester.pumpAndSettle();
    expect(find.text('No shows available'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    client.close();
  });
}
