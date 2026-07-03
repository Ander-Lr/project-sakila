import '../models/inventory.dart';
import 'api_service.dart';

class InventoryService {
  static Future<Map<String, dynamic>> createInventory({
    required int filmId,
    required int storeId,
    bool active = true,
  }) async {
    final response = await ApiService.post('/api/inventory', body: {
      'filmId': filmId,
      'storeId': storeId,
      'active': active,
    });
    return response as Map<String, dynamic>;
  }

  static Future<List<Inventory>> getInventoryByFilmId(int filmId) async {
    final response = await ApiService.get('/api/inventory?filmId=$filmId');
    final List data = response is List ? response : (response['content'] ?? []);
    return data.map((json) => Inventory.fromJson(json)).toList();
  }

  static Future<void> updateInventoryStatus(int id, bool active) async {
    await ApiService.patch('/api/inventory/$id/status', body: {'active': active});
  }
}
