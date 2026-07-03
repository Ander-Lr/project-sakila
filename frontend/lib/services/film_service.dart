import '../models/film.dart';
import 'api_service.dart';

class FilmService {
  static Future<List<Film>> getFilms({int page = 0, int size = 10, String sortBy = 'filmId', String sortDir = 'desc'}) async {
    final response = await ApiService.get('/api/films?page=$page&size=$size&sortBy=$sortBy&sortDir=$sortDir');
    final List data = response is List ? response : (response['content'] ?? []);
    return data.map((json) => Film.fromJson(json)).toList();
  }

  static Future<List<Film>> getAvailableFilms({int page = 0, int size = 10, String sortBy = 'filmId', String sortDir = 'desc'}) async {
    final response = await ApiService.get('/api/films/available?page=$page&size=$size&sortBy=$sortBy&sortDir=$sortDir');
    final List data = response is List ? response : (response['content'] ?? []);
    return data.map((json) => Film.fromJson(json)).toList();
  }

  static Future<List<Film>> searchFilms(String query, {int page = 0, int size = 10, String sortBy = 'filmId', String sortDir = 'desc'}) async {
    final response = await ApiService.get('/api/films/search?q=$query&page=$page&size=$size&sortBy=$sortBy&sortDir=$sortDir');
    final List data = response is List ? response : (response['content'] ?? []);
    return data.map((json) => Film.fromJson(json)).toList();
  }

  static Future<List<Film>> advancedSearch({
    String? title,
    String? category,
    int? year,
    String? rating,
    int page = 0,
    int size = 10,
    String sortBy = 'filmId',
    String sortDir = 'desc',
  }) async {
    List<String> queryParams = [
      'page=$page',
      'size=$size',
      'sortBy=$sortBy',
      'sortDir=$sortDir',
    ];
    if (title != null && title.isNotEmpty) queryParams.add('title=$title');
    if (category != null && category.isNotEmpty) queryParams.add('category=$category');
    if (year != null) queryParams.add('year=$year');
    if (rating != null && rating.isNotEmpty) queryParams.add('rating=$rating');

    final queryString = queryParams.join('&');
    final response = await ApiService.get('/api/films/advanced-search?$queryString');
    final List data = response is List ? response : (response['content'] ?? []);
    return data.map((json) => Film.fromJson(json)).toList();
  }

  static Future<int> checkInventory(int filmId) async {
    final response = await ApiService.get('/api/films/$filmId/inventory');
    // Assuming backend returns an integer or a JSON with a count field.
    if (response is List) return response.length;
    if (response is int) return response;
    if (response is Map) return response['count'] ?? response['available'] ?? 0;
    return 0;
  }

  static Future<Film> createFilm(Film film) async {
    final response = await ApiService.post('/api/films', body: film.toJson());
    return Film.fromJson(response);
  }

  static Future<Film> updateFilm(int id, Film film) async {
    final response = await ApiService.put('/api/films/$id', body: film.toJson());
    return Film.fromJson(response);
  }

  static Future<Film> updateFilmStatus(int id, bool active) async {
    final response = await ApiService.patch(
      '/api/films/$id/status',
      body: {'active': active},
    );
    return Film.fromJson(response);
  }
}
