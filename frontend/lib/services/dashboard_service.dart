import 'api_service.dart';
import '../models/dashboard_stats.dart';

class DashboardService {
  static Future<DashboardStats> getStats() async {
    final response = await ApiService.get('/api/admin/stats');
    return DashboardStats.fromJson(response);
  }
}
