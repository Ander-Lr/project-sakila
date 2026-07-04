import 'package:flutter/material.dart';
import '../models/rental.dart';
import '../models/api_error.dart';
import '../services/rental_service.dart';
import '../components/app_drawer.dart';

class MyRentalsPage extends StatefulWidget {
  const MyRentalsPage({super.key});

  @override
  State<MyRentalsPage> createState() => _MyRentalsPageState();
}

class _MyRentalsPageState extends State<MyRentalsPage> {
  List<Rental> _rentals = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadRentals();
  }

  Future<void> _loadRentals() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      _rentals = await RentalService.getMyRentals();
    } on ApiError catch (e) {
      _error = e.message ?? 'Error cargando alquileres';
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _returnFilm(Rental rental) async {
    if (rental.rentalId == null) return;
    
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Devolución'),
        content: Text('¿Deseas devolver ${rental.filmTitle ?? "esta película"}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Devolver')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await RentalService.returnFilm(rental.rentalId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Devolución registrada con éxito'), backgroundColor: Colors.green),
        );
        _loadRentals(); // Reload list
      }
    } on ApiError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Error en la devolución'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Alquileres'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadRentals),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error, style: const TextStyle(color: Colors.red)))
              : _rentals.isEmpty
                  ? const Center(child: Text('No tienes alquileres registrados.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _rentals.length,
                      itemBuilder: (context, index) {
                        final rental = _rentals[index];
                        final bool isReturned = rental.returnDate != null;
                        
                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ListTile(
                            leading: Icon(
                              isReturned ? Icons.check_circle : Icons.movie,
                              color: isReturned ? Colors.green : Theme.of(context).primaryColor,
                              size: 40,
                            ),
                            title: Text(rental.filmTitle ?? 'Película #${rental.inventoryId}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Alquilado el: ${rental.rentalDate}'),
                                if (isReturned) 
                                  Text('Devuelto el: ${rental.returnDate}', style: const TextStyle(color: Colors.green))
                                else
                                  const Text('Estado: Pendiente de devolución', style: TextStyle(color: Colors.orange)),
                              ],
                            ),
                            trailing: isReturned
                                ? const SizedBox.shrink()
                                : ElevatedButton(
                                    onPressed: () => _returnFilm(rental),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                                    child: const Text('Devolver'),
                                  ),
                          ),
                        );
                      },
                    ),
    );
  }
}
