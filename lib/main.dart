import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'blocs/shows_bloc.dart';
import 'blocs/search_bloc.dart';
import 'blocs/watchlist_bloc.dart';
import 'data/show_repository.dart';
import 'data/watchlist_repository.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final preferences = await SharedPreferences.getInstance();
    runApp(
      TVMazeApp(
        repository: ShowRepository(http.Client()),
        watchlistRepository: WatchlistRepository(preferences),
      ),
    );
  } catch (_) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Could not open local storage.'),
                FilledButton(onPressed: main, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TVMazeApp extends StatelessWidget {
  final ShowRepository repository;
  final WatchlistRepository watchlistRepository;
  const TVMazeApp({
    super.key,
    required this.repository,
    required this.watchlistRepository,
  });
  @override
  Widget build(BuildContext context) => RepositoryProvider.value(
    value: repository,
    child: MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ShowsBloc(repository)..add(ShowsRequested()),
        ),
        BlocProvider(create: (_) => SearchBloc(repository)),
        BlocProvider(
          create: (_) =>
              WatchlistBloc(watchlistRepository)..add(WatchlistLoaded()),
        ),
      ],
      child: MaterialApp(
        title: 'TVMaze',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF10111B),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF8055FF),
            brightness: Brightness.dark,
            primary: const Color(0xFF9875FF),
            surface: const Color(0xFF1C1D2C),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF10111B),
            centerTitle: false,
          ),
          navigationBarTheme: const NavigationBarThemeData(
            backgroundColor: Color(0xFF171824),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF232437),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        home: BlocListener<WatchlistBloc, WatchlistState>(
          listenWhen: (_, current) => current.error != null,
          listener: (context, state) =>
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(state.error!))),
          child: const HomeScreen(),
        ),
      ),
    ),
  );
}
