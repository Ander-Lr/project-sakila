import 'package:flutter/material.dart';
import '../components/app_drawer.dart';
import '../models/audit_log.dart';
import '../services/admin_service.dart';

class AdminAuditLogsPage extends StatefulWidget {
  const AdminAuditLogsPage({super.key});

  @override
  State<AdminAuditLogsPage> createState() => _AdminAuditLogsPageState();
}

class _AdminAuditLogsPageState extends State<AdminAuditLogsPage> {
  final List<AuditLog> _logs = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  bool _isFetchingMore = false;
  String _error = '';

  int _currentPage = 0;
  final int _pageSize = 15;
  bool _hasMore = true;

  String _sortBy = 'eventTime';
  String _sortDir = 'desc';

  // Filtros
  String? _filterEventType;
  int? _filterUserId;
  String? _filterDate;

  @override
  void initState() {
    super.initState();
    _loadLogs();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && 
        !_isLoading && !_isFetchingMore && _hasMore) {
      _loadMoreLogs();
    }
  }

  Future<void> _loadLogs({String? query}) async {
    setState(() {
      _isLoading = true;
      _error = '';
      _currentPage = 0;
      _hasMore = true;
      _logs.clear();
    });
    try {
      final q = query ?? _searchController.text.trim();
      final newLogs = await AdminService.getAuditLogs(
        q: q,
        eventType: _filterEventType,
        userId: _filterUserId,
        date: _filterDate,
        page: _currentPage,
        size: _pageSize,
        sortBy: _sortBy,
        sortDir: _sortDir,
      );
      _logs.addAll(newLogs);
      _hasMore = newLogs.length == _pageSize;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreLogs() async {
    setState(() => _isFetchingMore = true);
    _currentPage++;
    
    try {
      final q = _searchController.text.trim();
      final newLogs = await AdminService.getAuditLogs(
        q: q,
        eventType: _filterEventType,
        userId: _filterUserId,
        date: _filterDate,
        page: _currentPage,
        size: _pageSize,
        sortBy: _sortBy,
        sortDir: _sortDir,
      );
      _logs.addAll(newLogs);
      _hasMore = newLogs.length == _pageSize;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando más registros: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingMore = false);
    }
  }

  void _onSearch() {
    _loadLogs(query: _searchController.text.trim());
  }

  void _showFilterDialog() {
    String? tempEventType = _filterEventType;
    final userIdController = TextEditingController(text: _filterUserId?.toString());
    final dateController = TextEditingController(text: _filterDate);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24, left: 24, right: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Filtros Avanzados', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Tipo de Evento', border: OutlineInputBorder()),
                    value: tempEventType,
                    items: ['LOGIN_SUCCESS', 'LOGIN_FAILED', 'RENTAL_CREATED', 'RENTAL_RETURNED', 'RENTAL_DELETED', 'PAYMENT_APPROVED', 'PAYMENT_FAILED']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) => setModalState(() => tempEventType = val),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: userIdController,
                    decoration: const InputDecoration(labelText: 'ID Usuario', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: dateController,
                    decoration: const InputDecoration(
                      labelText: 'Fecha (YYYY-MM-DD)', 
                      border: OutlineInputBorder(),
                      hintText: 'Ej. 2026-07-05',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _filterEventType = null;
                              _filterUserId = null;
                              _filterDate = null;
                            });
                            Navigator.pop(context);
                            _loadLogs();
                          },
                          child: const Text('Limpiar'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                          onPressed: () {
                            setState(() {
                              _filterEventType = tempEventType;
                              _filterUserId = int.tryParse(userIdController.text);
                              _filterDate = dateController.text.isNotEmpty ? dateController.text : null;
                            });
                            Navigator.pop(context);
                            _loadLogs();
                          },
                          child: const Text('Aplicar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registros de Auditoría'),
        backgroundColor: Colors.redAccent,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Ordenar',
            onSelected: (value) {
              final parts = value.split(':');
              setState(() {
                _sortBy = parts[0];
                _sortDir = parts[1];
              });
              _loadLogs();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'eventTime:desc', child: Text('Más recientes primero')),
              const PopupMenuItem(value: 'eventTime:asc', child: Text('Más antiguos primero')),
            ],
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadLogs),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Buscar en detalle o módulo...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    onSubmitted: (_) => _onSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.filter_list, size: 28),
                  color: (_filterEventType != null || _filterUserId != null || _filterDate != null) 
                      ? Colors.redAccent 
                      : Colors.grey[700],
                  tooltip: 'Filtros Avanzados',
                  onPressed: _showFilterDialog,
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _onSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Buscar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error.isNotEmpty
                    ? Center(child: Text(_error, style: const TextStyle(color: Colors.red)))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _logs.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _logs.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          
                          final log = _logs[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: Icon(
                                log.level == 'WARN' ? Icons.warning : (log.level == 'ERROR' ? Icons.error : Icons.security),
                                color: log.level == 'WARN' ? Colors.orange : (log.level == 'ERROR' ? Colors.red : Colors.grey),
                              ),
                              title: Text(log.eventType ?? 'Desconocido', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${log.eventTime?.replaceAll('T', ' ').split('.').first} | Usuario: ${log.userId ?? "N/A"}\nMódulo: ${log.module} | Resultado: ${log.result}\nDetalle: ${log.message}'),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
