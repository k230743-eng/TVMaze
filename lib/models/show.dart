import 'package:html/parser.dart' as html;

class Show {
  final int id;
  final String name, summary, status, language;
  final String? image;
  final double? rating;
  final List<String> genres;
  Show({
    required this.id,
    required this.name,
    this.summary = '',
    this.status = 'Unknown',
    this.language = 'Unknown',
    this.image,
    this.rating,
    this.genres = const [],
  });
  factory Show.fromJson(Map<String, dynamic> json) => Show(
    id: json['id'] as int,
    name: json['name'] as String? ?? 'Unknown show',
    summary: html.parse(json['summary'] as String? ?? '').body?.text ?? '',
    status: json['status'] as String? ?? 'Unknown',
    language: json['language'] as String? ?? 'Unknown',
    image: json['image']?['medium'] as String?,
    rating: (json['rating']?['average'] as num?)?.toDouble(),
    genres: (json['genres'] as List? ?? []).cast<String>(),
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'summary': summary,
    'status': status,
    'language': language,
    'image': {'medium': image},
    'rating': {'average': rating},
    'genres': genres,
  };
}

class CastMember {
  final String name, character;
  final String? image;
  CastMember.fromJson(Map<String, dynamic> json)
    : name = json['person']?['name'] as String? ?? 'Unknown actor',
      character = json['character']?['name'] as String? ?? 'Unknown character',
      image = json['person']?['image']?['medium'] as String?;
}

class Episode {
  final int season;
  final int? number;
  final String name, airdate;
  Episode.fromJson(Map<String, dynamic> json)
    : season = json['season'] as int? ?? 0,
      number = json['number'] as int?,
      name = json['name'] as String? ?? 'Untitled episode',
      airdate = json['airdate'] as String? ?? '';
}
