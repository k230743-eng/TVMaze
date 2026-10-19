import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/show.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ShowRepository {
  final http.Client client;
  ShowRepository(this.client);
  Future<dynamic> _get(
    String path, {
    Map<String, String>? query,
    bool index = false,
  }) async {
    try {
      final response = await client
          .get(Uri.https('api.tvmaze.com', path, query))
          .timeout(const Duration(seconds: 20));
      if (index && response.statusCode == 404) return <dynamic>[];
      if (response.statusCode != 200) {
        throw ApiException(
          response.statusCode == 429
              ? 'Too many requests. Please wait a moment and retry.'
              : 'Could not load data (${response.statusCode}). Please retry.',
        );
      }
      return jsonDecode(response.body);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('The request took too long. Please retry.');
    } catch (_) {
      throw ApiException(
        'Unable to load TVMaze data. Check your connection and retry.',
      );
    }
  }

  Future<List<Show>> shows(int page) async =>
      (await _get('/shows', query: {'page': '$page'}, index: true) as List)
          .map((j) => Show.fromJson(j))
          .toList();
  Future<List<Show>> search(String query) async =>
      (await _get('/search/shows', query: {'q': query}) as List)
          .map((j) => Show.fromJson(j['show']))
          .toList();
  Future<Show> details(int id) async => Show.fromJson(await _get('/shows/$id'));
  Future<List<CastMember>> cast(int id) async =>
      (await _get('/shows/$id/cast') as List)
          .map((j) => CastMember.fromJson(j))
          .toList();
  Future<List<Episode>> episodes(int id) async =>
      (await _get('/shows/$id/episodes') as List)
          .map((j) => Episode.fromJson(j))
          .toList();
}
