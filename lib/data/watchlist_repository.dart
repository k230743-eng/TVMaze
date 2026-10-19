import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/show.dart';

class WatchlistRepository {
  final SharedPreferences preferences;
  WatchlistRepository(this.preferences);
  List<Show> load() {
    final saved = preferences.getString('watchlist');
    if (saved == null) return [];
    return (jsonDecode(saved) as List).map((j) => Show.fromJson(j)).toList();
  }

  Future<void> save(List<Show> shows) async {
    final success = await preferences.setString(
      'watchlist',
      jsonEncode(shows.map((s) => s.toJson()).toList()),
    );
    if (!success) throw Exception('Storage failed');
  }
}
