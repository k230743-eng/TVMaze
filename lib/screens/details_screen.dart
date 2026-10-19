import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/details_bloc.dart';
import '../blocs/shows_bloc.dart';
import '../blocs/watchlist_bloc.dart';
import '../data/show_repository.dart';
import '../widgets/common.dart';

class DetailsScreen extends StatelessWidget {
  final int id;
  const DetailsScreen({super.key, required this.id});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        DetailsBloc(context.read<ShowRepository>())..add(DetailsRequested(id)),
    child: Scaffold(
      appBar: AppBar(title: const Text('Show details')),
      body: BlocBuilder<DetailsBloc, DetailsState>(
        builder: (context, state) {
          void retry() => context.read<DetailsBloc>().add(DetailsRequested(id));
          if (state.status == LoadStatus.initial ||
              state.status == LoadStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == LoadStatus.error) {
            return MessageView(
              title: 'Unable to load details',
              message: state.error!,
              onRetry: retry,
            );
          }
          final show = state.show!;
          return DefaultTabController(
            length: 3,
            child: NestedScrollView(
              headerSliverBuilder: (_, _) => [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Poster(show.image, width: 180, height: 255),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          show.name,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Rating: ${show.rating?.toStringAsFixed(1) ?? 'Not rated'}   •   ${show.status}',
                          style: const TextStyle(color: Color(0xFFFFD76B)),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: show.genres
                              .map(
                                (genre) => Chip(
                                  label: Text(genre),
                                  visualDensity: VisualDensity.compact,
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 12),
                        BlocBuilder<WatchlistBloc, WatchlistState>(
                          builder: (context, watchlist) {
                            final saved = watchlist.contains(show.id);
                            final ready =
                                watchlist.status == LoadStatus.success ||
                                watchlist.status == LoadStatus.empty;
                            return SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: ready
                                    ? () => context.read<WatchlistBloc>().add(
                                        WatchlistToggled(show),
                                      )
                                    : null,
                                icon: Icon(saved ? Icons.favorite : Icons.add),
                                label: Text(
                                  saved
                                      ? 'Remove from Watchlist'
                                      : 'Add to Watchlist',
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPersistentHeader(pinned: true, delegate: _Tabs()),
              ],
              body: TabBarView(
                children: [
                  ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text(
                        'The story',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        show.summary.isEmpty
                            ? 'No summary available for this show.'
                            : show.summary,
                        style: const TextStyle(
                          height: 1.6,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Quick info',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Status'),
                        trailing: Text(show.status),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Language'),
                        trailing: Text(show.language),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Show information provided by TVMaze · CC BY-SA',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                  state.episodesError != null
                      ? MessageView(
                          title: 'Episodes unavailable',
                          message: state.episodesError!,
                          onRetry: retry,
                        )
                      : state.episodes.isEmpty
                      ? const MessageView(
                          title: 'No episodes yet',
                          message: 'TVMaze has no episode information for this show.',
                        )
                      : ListView(
                          padding: const EdgeInsets.all(12),
                          children: [
                            for (final season
                                in (state.episodes
                                    .map((e) => e.season)
                                    .toSet()
                                    .toList()
                                  ..sort()))
                              ExpansionTile(
                                initiallyExpanded:
                                    season == state.episodes.first.season,
                                title: Text('Season $season'),
                                subtitle: Text(
                                  '${state.episodes.where((e) => e.season == season).length} episodes',
                                ),
                                children: [
                                  for (final episode in state.episodes.where(
                                    (e) => e.season == season,
                                  ))
                                    ListTile(
                                      leading: CircleAvatar(
                                        child: Text('${episode.number ?? 'S'}'),
                                      ),
                                      title: Text(episode.name),
                                      subtitle: Text(
                                        episode.airdate.isEmpty
                                            ? 'Air date unavailable'
                                            : episode.airdate,
                                      ),
                                    ),
                                ],
                              ),
                          ],
                        ),
                  state.castError != null
                      ? MessageView(
                          title: 'Cast unavailable',
                          message: state.castError!,
                          onRetry: retry,
                        )
                      : state.cast.isEmpty
                      ? const MessageView(
                          title: 'No cast listed',
                          message:
                              'TVMaze has no cast information for this show.',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          itemCount: state.cast.length,
                          separatorBuilder: (_, _) =>
                              const Divider(indent: 20, endIndent: 20),
                          itemBuilder: (_, index) {
                            final member = state.cast[index];
                            return ListTile(
                              leading: Poster(
                                member.image,
                                width: 48,
                                height: 56,
                              ),
                              title: Text(member.name),
                              subtitle: Text(member.character),
                            );
                          },
                        ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _Tabs extends SliverPersistentHeaderDelegate {
  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => ColoredBox(
    color: Theme.of(context).scaffoldBackgroundColor,
    child: const TabBar(
      tabs: [
        Tab(text: 'Overview'),
        Tab(text: 'Episodes'),
        Tab(text: 'Cast'),
      ],
    ),
  );
  @override
  bool shouldRebuild(covariant _Tabs oldDelegate) => false;
}
