import '../models/audit_log.dart';
import 'api_service.dart';

class AdminService {
  static Future<List<AuditLog>> getAuditLogs({
    String? q,
    String? eventType,
    int? userId,
    String? date,
    int page = 0,
    int size = 10,
    String sortBy = 'eventTime',
    String sortDir = 'desc',
  }) async {
    final queryParams = <String>[];
    if (q != null && q.isNotEmpty) queryParams.add('q=$q');
    if (eventType != null) queryParams.add('eventType=$eventType');
    if (userId != null) queryParams.add('userId=$userId');
    if (date != null) queryParams.add('date=$date');
    queryParams.add('page=$page');
    queryParams.add('size=$size');
    queryParams.add('sortBy=$sortBy');
    queryParams.add('sortDir=$sortDir');

    final queryString = queryParams.join('&');
    final response = await ApiService.get('/api/admin/logs?$queryString');
    
    final List data = response is List ? response : (response['content'] ?? []);
    return data.map((json) => AuditLog.fromJson(json)).toList();
  }
}
