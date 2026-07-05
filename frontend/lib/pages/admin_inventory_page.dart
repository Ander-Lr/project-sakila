import 'package:flutter/material.dart';
import '../models/film.dart';
import '../models/inventory.dart';
import '../services/inventory_service.dart';

class AdminInventoryPage extends StatefulWidget {
  final Film film;

  const AdminInventoryPage({super.key, required this.film});

  @override
  State<AdminInventoryPage> createState() => _AdminInventoryPageState();
}

class _AdminInventoryPageState extends State<AdminInventoryPage> {
  List<Inventory> _inventoryItems = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    if (widget.film.id == null) return;
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      _inventoryItems = await InventoryService.getInventoryByFilmId(widget.film.id!);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleStatus(Inventory item, bool newValue) async {
    if (item.inventoryId == null) return;
    try {
      await InventoryService.updateInventoryStatus(item.inventoryId!, newValue);
      _loadInventory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Estado de ejemplar actualizado'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _addCopy() async {
    if (widget.film.id == null) return;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Ejemplar'),
        content: Text('¿Deseas agregar una nueva copia física de "${widget.film.title}" en la tienda principal?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Agregar')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await InventoryService.createInventory(filmId: widget.film.id!, storeId: 1);
      _loadInventory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ejemplar agregado exitosamente'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error agregando ejemplar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inventario: ${widget.film.title}'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadInventory),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error, style: const TextStyle(color: Colors.red)))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Ejemplares: ${_inventoryItems.length}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ElevatedButton.icon(
                            onPressed: widget.film.active == true ? _addCopy : null,
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar Copia'),
                            style: ElevatedButton.styleFrom(
                              disabledBackgroundColor: Colors.grey.shade300,
                              disabledForegroundColor: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _inventoryItems.length,
                        itemBuilder: (context, index) {
                          final item = _inventoryItems[index];
                          return Card(
                            child: ListTile(
                              leading: Icon(
                                Icons.inventory,
                                color: item.active == true ? Theme.of(context).primaryColor : Colors.grey,
                              ),
                              title: Text('Ejemplar ID: ${item.inventoryId}'),
                              subtitle: Text('Tienda: ${item.storeId}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(item.active == true ? 'Disponible' : 'No Disponible'),
                                  Switch(
                                    value: item.active ?? true,
                                    activeColor: Colors.green,
                                    onChanged: (val) => _toggleStatus(item, val),
                                  ),
                                ],
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
