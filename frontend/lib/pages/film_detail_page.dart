import 'package:flutter/material.dart';
import '../models/film.dart';
import '../services/film_service.dart';
import 'checkout_page.dart';

class FilmDetailPage extends StatefulWidget {
  final Film film;

  const FilmDetailPage({super.key, required this.film});

  @override
  State<FilmDetailPage> createState() => _FilmDetailPageState();
}

class _FilmDetailPageState extends State<FilmDetailPage> {
  bool _isLoading = true;
  int _availableStock = 0;

  @override
  void initState() {
    super.initState();
    _checkStock();
  }

  Future<void> _checkStock() async {
    try {
      if (widget.film.id != null) {
        _availableStock = await FilmService.checkInventory(widget.film.id!);
      }
    } catch (_) {
      _availableStock = 0;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.film.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.movie_creation, size: 80, color: Colors.grey[400]),
              ),
            const SizedBox(height: 20),
            Text(
              widget.film.title,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              widget.film.description ?? 'Sin descripción',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            if (widget.film.categories != null && widget.film.categories!.isNotEmpty)
              Wrap(
                spacing: 8.0,
                runSpacing: -8.0,
                children: widget.film.categories!
                    .map((cat) => Chip(
                          label: Text(cat),
                          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          side: BorderSide.none,
                        ))
                    .toList(),
              ),
            if (widget.film.actors != null && widget.film.actors!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Elenco:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(widget.film.actors!.join(', ')),
            ],
            const SizedBox(height: 20),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.star_border),
              title: const Text('Clasificación'),
              trailing: Text('${widget.film.rating ?? "N/A"}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Año de lanzamiento'),
              trailing: Text('${widget.film.releaseYear ?? "N/A"}'),
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Duración (min)'),
              trailing: Text('${widget.film.length ?? "N/A"}'),
            ),
            ListTile(
              leading: const Icon(Icons.monetization_on),
              title: const Text('Tarifa de Alquiler'),
              trailing: Text('\$${widget.film.rentalRate ?? "N/A"}'),
            ),
            const Divider(),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Column(
                children: [
                  Text(
                    _availableStock > 0
                        ? 'Ejemplares disponibles: $_availableStock'
                        : 'No hay stock disponible.',
                    style: TextStyle(
                      fontSize: 18,
                      color: _availableStock > 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _availableStock > 0
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CheckoutPage(film: widget.film),
                                ),
                              );
                            }
                          : null,
                      icon: const Icon(Icons.shopping_cart),
                      label: const Text('Alquilar Ahora', style: TextStyle(fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
