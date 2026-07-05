import 'package:flutter/material.dart';
import '../components/app_drawer.dart';
import '../models/rental.dart';
import '../services/rental_service.dart';

class AdminRentalsPage extends StatefulWidget {
  const AdminRentalsPage({super.key});

  @override
  State<AdminRentalsPage> createState() => _AdminRentalsPageState();
}

class _AdminRentalsPageState extends State<AdminRentalsPage> {
  final List<Rental> _rentals = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  bool _isLoading = true;
  bool _isFetchingMore = false;
  String _error = '';
  int _currentPage = 0;
  final int _pageSize = 15;
  bool _hasMore = true;

  String _sortBy = 'rentalDate';
  String _sortDir = 'desc';

  // Filtros
  int? _filterCustomerId;
  String? _filterDate;

  @override
  void initState() {
    super.initState();
    _loadRentals();
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
      _loadMore();
    }
  }

  Future<void> _loadRentals({String? query}) async {
    setState(() {
      _isLoading = true;
      _error = '';
      _currentPage = 0;
      _hasMore = true;
      _rentals.clear();
    });
    
    try {
      final q = query ?? _searchController.text.trim();
      final newRentals = await RentalService.getAllRentals(
        q: q,
        customerId: _filterCustomerId,
        date: _filterDate,
        page: _currentPage,
        size: _pageSize,
        sortBy: _sortBy,
        sortDir: _sortDir,
      );
      _rentals.addAll(newRentals);
      _hasMore = newRentals.length == _pageSize;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isFetchingMore = true);
    _currentPage++;
    
    try {
      final q = _searchController.text.trim();
      final newRentals = await RentalService.getAllRentals(
        q: q,
        customerId: _filterCustomerId,
        date: _filterDate,
        page: _currentPage,
        size: _pageSize,
        sortBy: _sortBy,
        sortDir: _sortDir,
      );
      _rentals.addAll(newRentals);
      _hasMore = newRentals.length == _pageSize;
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
    _loadRentals(query: _searchController.text.trim());
  }

  Future<void> _returnRental(Rental rental) async {
    try {
      await RentalService.returnFilm(rental.rentalId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alquiler devuelto con éxito')));
        Navigator.pop(context); // Close dialog
        _loadRentals(); // Reload list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error devolviendo alquiler: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _deleteRental(Rental rental) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Alquiler'),
        content: Text('¿Estás seguro de que deseas eliminar permanentemente el alquiler #${rental.rentalId}? Esto también eliminará el pago asociado.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await RentalService.deleteRental(rental.rentalId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alquiler eliminado con éxito')));
        Navigator.pop(context); // Close details dialog
        _loadRentals(); // Reload list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error eliminando alquiler: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _showRentalDetails(Rental rental) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Detalle del Alquiler #${rental.rentalId}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow(Icons.movie, 'Película', rental.filmTitle ?? 'N/A'),
                _detailRow(Icons.inventory, 'ID Ejemplar', rental.inventoryId?.toString() ?? 'N/A'),
                const Divider(),
                _detailRow(Icons.person, 'Cliente', rental.customerName ?? 'ID: ${rental.customerId}'),
                _detailRow(Icons.badge, 'Atendido por', rental.staffName ?? 'ID: ${rental.staffId}'),
                const Divider(),
                _detailRow(Icons.calendar_today, 'Fecha Alquiler', rental.rentalDate ?? 'N/A'),
                _detailRow(Icons.event_available, 'Fecha Devolución', rental.returnDate ?? 'Aún no devuelto'),
                const Divider(),
                _detailRow(Icons.attach_money, 'Costo del Alquiler', '\$${rental.amount ?? 0.0}'),
                if (rental.paymentAmount != null) ...[
                  _detailRow(Icons.payment, 'Monto Pagado', '\$${rental.paymentAmount}'),
                  _detailRow(Icons.credit_card, 'Método', '${rental.paymentMethod ?? "N/A"} (Termina en ${rental.cardLast4 ?? "****"})'),
                  _detailRow(Icons.receipt, 'Transacción', rental.transactionRef ?? 'N/A'),
                ],
              ],
            ),
          ),
          actions: [
            if (rental.returnDate == null)
              TextButton(
                onPressed: () => _returnRental(rental),
                child: const Text('Marcar Devuelto', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ),
            TextButton(
              onPressed: () => _deleteRental(rental),
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 14),
                children: [
                  TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    final customerIdController = TextEditingController(text: _filterCustomerId?.toString());
    final dateController = TextEditingController(text: _filterDate);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
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
              TextField(
                controller: customerIdController,
                decoration: const InputDecoration(labelText: 'ID Cliente Exacto', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: dateController,
                decoration: const InputDecoration(
                  labelText: 'Fecha (YYYY-MM-DD)', 
                  border: OutlineInputBorder(),
                  hintText: 'Ej. 2005-05-24',
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _filterCustomerId = null;
                          _filterDate = null;
                        });
                        Navigator.pop(context);
                        _loadRentals();
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
                          _filterCustomerId = int.tryParse(customerIdController.text);
                          _filterDate = dateController.text.isNotEmpty ? dateController.text : null;
                        });
                        Navigator.pop(context);
                        _loadRentals();
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todos los Alquileres'),
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
              _loadRentals();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'rentalDate:desc', child: Text('Más recientes primero')),
              const PopupMenuItem(value: 'rentalDate:asc', child: Text('Más antiguos primero')),
            ],
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadRentals),
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
                      labelText: 'Buscar por cliente o película...',
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
                  color: (_filterCustomerId != null || _filterDate != null) 
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
                        itemCount: _rentals.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _rentals.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          
                          final rental = _rentals[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              onTap: () => _showRentalDetails(rental),
                              leading: const Icon(Icons.receipt, color: Colors.orange),
                              title: Text('Alquiler #${rental.rentalId} - ${rental.customerName ?? "Cliente " + (rental.customerId?.toString() ?? "")}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Película: ${rental.filmTitle ?? rental.inventoryId} \nFecha: ${rental.rentalDate}'),
                              trailing: Text(
                                rental.returnDate != null ? 'Devuelto' : 'Activo',
                                style: TextStyle(
                                  color: rental.returnDate != null ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
