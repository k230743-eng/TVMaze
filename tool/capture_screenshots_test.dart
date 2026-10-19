// Explicit screenshot utility; see docs/screenshots/README.md.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tv_maze/main.dart';
import 'package:tv_maze/data/show_repository.dart';
import 'package:tv_maze/data/watchlist_repository.dart';

// Serve downloaded poster bytes to Image.network within Flutter's test renderer.
class PosterClient implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => PosterRequest(url);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class PosterRequest implements HttpClientRequest {
  final Uri url;
  PosterRequest(this.url);
  @override
  HttpHeaders get headers => PosterHeaders();
  @override
  Future<HttpClientResponse> close() async {
    final file = File('tool/capture_data/images/${url.pathSegments.last}');
    return PosterResponse(file.existsSync() ? file.readAsBytesSync() : []);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class PosterHeaders implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class PosterResponse extends Stream<List<int>> implements HttpClientResponse {
  final List<int> bytes;
  PosterResponse(this.bytes);
  @override
  int get statusCode => bytes.isEmpty ? 404 : 200;
  @override
  int get contentLength => bytes.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.value(bytes).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('Capture actual app with downloaded TVMaze responses', (
    tester,
  ) async {
    await tester.runAsync(() async {
      for (final entry in {
        'Roboto': 'Roboto-Regular.ttf',
        'MaterialIcons': 'MaterialIcons-Regular.otf',
      }.entries) {
        final loader = FontLoader(entry.key);
        loader.addFont(
          Future.value(
            ByteData.sublistView(
              File('tool/capture_data/${entry.value}').readAsBytesSync(),
            ),
          ),
        );
        await loader.load();
      }
    });
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    // Capture utility uses test-only storage without touching real preferences.
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    debugNetworkImageHttpClientProvider = () => PosterClient();
    addTearDown(() => debugNetworkImageHttpClientProvider = null);
    final client = MockClient((request) async {
      final path = request.url.path;
      final name = path == '/shows'
          ? 'catalogue'
          : path == '/search/shows'
          ? 'search'
          : path.endsWith('/cast')
          ? 'cast'
          : path.endsWith('/episodes')
          ? 'episodes'
          : 'details';
      return http.Response(
        File('tool/capture_data/$name.json').readAsStringSync(),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final boundary = GlobalKey();
    Future<void> settleImages() async {
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 800)),
      );
      await tester.pumpAndSettle();
    }

    Future<void> capture(String name) async {
      await settleImages();
      final render =
          boundary.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = (await tester.runAsync(() => render.toImage()))!;
      final bytes = await tester.runAsync(
        () => image.toByteData(format: ui.ImageByteFormat.png),
      );
      await tester.runAsync(
        () =>
            File('docs/screenshots/$name.png')
                .writeAsBytes(bytes!.buffer.asUint8List()),
      );
      image.dispose();
      debugPrint('Captured $name');
    }

    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: TVMazeApp(
          repository: ShowRepository(client),
          watchlistRepository: WatchlistRepository(preferences),
        ),
      ),
    );
    await settleImages();
    expect(find.text('Explore shows'), findsOneWidget);
    await capture('discover');
    await tester.tap(find.text('Search').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'breaking');
    await tester.pump(const Duration(milliseconds: 450));
    await settleImages();
    expect(find.text('Breaking Bad'), findsOneWidget);
    await capture('search');
    await tester.tap(find.text('Breaking Bad'));
    await settleImages();
    expect(find.text('The story'), findsOneWidget);
    await capture('details');
    await tester.tap(find.text('Episodes'));
    await tester.pumpAndSettle();
    await capture('episodes');
    await tester.tap(find.text('Cast'));
    await tester.pumpAndSettle();
    await capture('cast');
    await tester.tap(find.text('Add to Watchlist'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Watchlist').last);
    await tester.pumpAndSettle();
    await capture('watchlist');
    await tester.tap(find.byTooltip('Remove from watchlist'));
    await tester.pumpAndSettle();
    await capture('empty-watchlist');
    await tester.pumpWidget(const SizedBox());
    client.close();
    debugNetworkImageHttpClientProvider = null;
  });
}
