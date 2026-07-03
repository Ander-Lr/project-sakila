import '../models/rental.dart';
import 'api_service.dart';

class RentalService {
  static Future<Rental> createRentalAndPay({
    int? inventoryId,
    int? filmId,
    required String cardNumber,
    required String cardHolder,
    required String expirationDate,
    required String cvv,
  }) async {
    final response = await ApiService.post('/api/rentals', body: {
      if (inventoryId != null) 'inventoryId': inventoryId,
      if (filmId != null) 'filmId': filmId,
      'cardNumber': cardNumber,
      'cardHolder': cardHolder,
      'expirationDate': expirationDate,
      'cvv': cvv,
    });
    return Rental.fromJson(response);
  }

  static Future<Rental> returnFilm(int rentalId) async {
    final response = await ApiService.post('/api/rentals/$rentalId/return');
    return Rental.fromJson(response);
  }

  static Future<void> deleteRental(int rentalId) async {
    await ApiService.delete('/api/rentals/$rentalId');
  }

  static Future<List<Rental>> getMyRentals() async {
    final response = await ApiService.get('/api/rentals/mine');
    final List data = response is List ? response : (response['content'] ?? []);
    return data.map((json) => Rental.fromJson(json)).toList();
  }

  static Future<List<Rental>> getAllRentals({
    String? q,
    int? customerId,
    int? filmId,
    String? date,
    int page = 0,
    int size = 10,
    String sortBy = 'rentalDate',
    String sortDir = 'desc',
  }) async {
    final queryParams = <String>[];
    if (q != null && q.isNotEmpty) queryParams.add('q=$q');
    if (customerId != null) queryParams.add('customerId=$customerId');
    if (filmId != null) queryParams.add('filmId=$filmId');
    if (date != null) queryParams.add('date=$date');
    queryParams.add('page=$page');
    queryParams.add('size=$size');
    queryParams.add('sortBy=$sortBy');
    queryParams.add('sortDir=$sortDir');

    final queryString = queryParams.join('&');
    final response = await ApiService.get('/api/rentals?$queryString');
    
    final List data = response is List ? response : (response['content'] ?? []);
    return data.map((json) => Rental.fromJson(json)).toList();
  }

  static Future<List<Rental>> getAllReturns({int page = 0, int size = 10}) async {
    final response = await ApiService.get('/api/rentals/returns?page=$page&size=$size');
    final List data = response is List ? response : (response['content'] ?? []);
    return data.map((json) => Rental.fromJson(json)).toList();
  }

  static Future<Rental> getRentalDetail(int rentalId) async {
    final response = await ApiService.get('/api/rentals/$rentalId');
    return Rental.fromJson(response);
  }
}
