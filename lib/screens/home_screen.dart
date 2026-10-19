import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/shows_bloc.dart';
import '../blocs/search_bloc.dart';
import '../blocs/watchlist_bloc.dart';
import '../widgets/common.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: IndexedStack(
        index: _tab,
        children: [
          const DiscoverScreen(),
          const SearchScreen(),
          WatchlistScreen(onExplore: () => setState(() => _tab = 0)),
        ],
      ),
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _tab,
      onDestinationSelected: (value) => setState(() => _tab = value),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Discover',
        ),
        NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
        NavigationDestination(
          icon: Icon(Icons.favorite_border),
          selectedIcon: Icon(Icons.favorite),
          label: 'Watchlist',
        ),
      ],
    ),
  );
}

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});
  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _scroll = ScrollController();
  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 600) {
        final bloc = context.read<ShowsBloc>();
        if (!bloc.state.loadingMore &&
            bloc.state.error == null &&
            bloc.state.status == LoadStatus.success) {
          bloc.add(ShowsRequested());
        }
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<ShowsBloc, ShowsState>(
    builder: (context, state) {
      void retry() => context.read<ShowsBloc>().add(ShowsRequested());
      if (state.status == LoadStatus.loading ||
          state.status == LoadStatus.initial) {
        return const Center(child: CircularProgressIndicator());
      }
      if (state.status == LoadStatus.error) {
        return MessageView(
          title: 'Unable to load shows',
          message: state.error!,
          onRetry: retry,
        );
      }
      if (state.status == LoadStatus.empty) {
        return MessageView(
          title: 'No shows available',
          message: 'Please try again later.',
          onRetry: () =>
              context.read<ShowsBloc>().add(ShowsRequested(refresh: true)),
        );
      }
      return RefreshIndicator(
        onRefresh: () async {
          final bloc = context.read<ShowsBloc>();
          bloc.add(ShowsRequested(refresh: true));
          await bloc.stream.firstWhere((s) => s.status != LoadStatus.loading);
        },
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.live_tv_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'TVMaze',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 26,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Hello, TV Explorer!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Find your next favourite story.',
                      style: TextStyle(color: Colors.white60),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Explore shows',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Browse the TVMaze catalogue',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final columns = (constraints.crossAxisExtent / 160)
                      .floor()
                      .clamp(2, 6);
                  return SliverGrid(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final show = state.shows[index];
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => openShow(context, show),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Poster(show.image),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black87,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${show.rating?.toStringAsFixed(1) ?? '—'}/10',
                                        style: const TextStyle(
                                          color: Color(0xFFFFD76B),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              show.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              show.genres.isEmpty
                                  ? 'Genres unavailable'
                                  : show.genres.join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    }, childCount: state.shows.length),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      childAspectRatio: .57,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 20,
                    ),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: state.loadingMore
                      ? const CircularProgressIndicator()
                      : state.error != null
                      ? Column(
                          children: [
                            Text(state.error!, textAlign: TextAlign.center),
                            TextButton(
                              onPressed: retry,
                              child: const Text('Retry loading more'),
                            ),
                          ],
                        )
                      : Text(
                          state.hasMore
                              ? 'Scroll to discover more'
                              : 'You have reached the end',
                          style: const TextStyle(color: Colors.white54),
                        ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
        child: Text(
          'Find a show',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: TextField(
          controller: _controller,
          onChanged: (value) =>
              context.read<SearchBloc>().add(SearchChanged(value)),
          decoration: InputDecoration(
            hintText: 'Search TV shows...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              tooltip: 'Clear search',
              icon: const Icon(Icons.close),
              onPressed: () {
                _controller.clear();
                context.read<SearchBloc>().add(SearchChanged(''));
              },
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      Expanded(
        child: BlocBuilder<SearchBloc, SearchState>(
          builder: (context, state) {
            switch (state.status) {
              case LoadStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case LoadStatus.error:
                return MessageView(
                  title: 'Search failed',
                  message: state.error!,
                  onRetry: () => context.read<SearchBloc>().add(
                    SearchChanged(_controller.text),
                  ),
                );
              case LoadStatus.empty:
                return MessageView(
                  title: 'No shows found',
                  message: 'No matches for “${state.query}”. Try another name.',
                );
              case LoadStatus.success:
                return ListView.separated(
                  itemCount: state.shows.length,
                  separatorBuilder: (_, _) =>
                      const Divider(indent: 20, endIndent: 20),
                  itemBuilder: (_, index) => ShowTile(show: state.shows[index]),
                );
              default:
                return const MessageView(
                  title: 'What are you looking for?',
                  message: 'Search by show name to find your next watch.',
                  icon: Icons.search_rounded,
                );
            }
          },
        ),
      ),
    ],
  );
}

class WatchlistScreen extends StatelessWidget {
  final VoidCallback onExplore;
  const WatchlistScreen({super.key, required this.onExplore});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(20, 24, 20, 6),
        child: Text(
          'My Watchlist',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
      ),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          'A little list of your next great watches.',
          style: TextStyle(color: Colors.white60),
        ),
      ),
      const SizedBox(height: 16),
      Expanded(
        child: BlocBuilder<WatchlistBloc, WatchlistState>(
          builder: (context, state) {
            if (state.status == LoadStatus.initial ||
                state.status == LoadStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == LoadStatus.error) {
              return MessageView(
                title: 'Watchlist unavailable',
                message: state.error!,
                onRetry: () =>
                    context.read<WatchlistBloc>().add(WatchlistLoaded()),
              );
            }
            if (state.shows.isEmpty) {
              return MessageView(
                title: 'Your watchlist is empty',
                message: 'Save shows you want to come back to. They will be here next time.',
                icon: Icons.favorite_border_rounded,
                onRetry: onExplore,
                buttonLabel: 'Explore shows',
              );
            }
            return ListView.separated(
              itemCount: state.shows.length,
              separatorBuilder: (_, _) =>
                  const Divider(indent: 20, endIndent: 20),
              itemBuilder: (_, index) {
                final show = state.shows[index];
                return ShowTile(
                  show: show,
                  trailing: IconButton(
                    tooltip: 'Remove from watchlist',
                    icon: const Icon(Icons.favorite, color: Color(0xFFFF707D)),
                    onPressed: () => context.read<WatchlistBloc>().add(
                      WatchlistToggled(show),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    ],
  );
}
