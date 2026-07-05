import 'package:flutter/material.dart';
import '../components/app_drawer.dart';
import '../models/film.dart';
import '../services/film_service.dart';
import '../services/inventory_service.dart';
import 'admin_film_form_page.dart';
import 'admin_inventory_page.dart';

class AdminFilmsPage extends StatefulWidget {
  const AdminFilmsPage({super.key});

  @override
  State<AdminFilmsPage> createState() => _AdminFilmsPageState();
}

class _AdminFilmsPageState extends State<AdminFilmsPage> {
  final List<Film> _films = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  bool _isFetchingMore = false;
  String _error = '';

  int _currentPage = 0;
  final int _pageSize = 15;
  bool _hasMore = true;

  String _sortBy = 'filmId';
  String _sortDir = 'desc';

  // Filtros
  String? _filterCategory;
  int? _filterYear;
  String? _filterRating;

  @override
  void initState() {
    super.initState();
    _loadFilms();
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
      _loadMoreFilms();
    }
  }

  Future<void> _loadFilms({String? query}) async {
    setState(() {
      _isLoading = true;
      _error = '';
      _currentPage = 0;
      _hasMore = true;
      _films.clear();
    });
    try {
      final q = query ?? _searchController.text.trim();
      final newFilms = await FilmService.advancedSearch(
        title: q,
        category: _filterCategory,
        year: _filterYear,
        rating: _filterRating,
        page: _currentPage,
        size: _pageSize,
        sortBy: _sortBy,
        sortDir: _sortDir,
      );
      _films.addAll(newFilms);
      _hasMore = newFilms.length == _pageSize;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreFilms() async {
    setState(() => _isFetchingMore = true);
    _currentPage++;
    
    try {
      final q = _searchController.text.trim();
      final newFilms = await FilmService.advancedSearch(
        title: q,
        category: _filterCategory,
        year: _filterYear,
        rating: _filterRating,
        page: _currentPage,
        size: _pageSize,
        sortBy: _sortBy,
        sortDir: _sortDir,
      );
      _films.addAll(newFilms);
      _hasMore = newFilms.length == _pageSize;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando más películas: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingMore = false);
    }
  }

  void _onSearch() {
    _loadFilms(query: _searchController.text.trim());
  }

  Future<void> _toggleFilmStatus(Film film, bool newValue) async {
    if (film.id == null) return;
    try {
      await FilmService.updateFilmStatus(film.id!, newValue);
      _loadFilms();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Estado actualizado'), backgroundColor: Colors.green),
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

  void _openInventory(Film film) {
    if (film.id == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AdminInventoryPage(film: film)),
    );
  }

  void _showFilterDialog() {
    String? tempCategory = _filterCategory;
    int? tempYear = _filterYear;
    String? tempRating = _filterRating;

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
                    decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
                    value: tempCategory,
                    items: ['Action', 'Animation', 'Children', 'Classics', 'Comedy', 'Documentary', 'Drama', 'Family', 'Foreign', 'Games', 'Horror', 'Music', 'New', 'Sci-Fi', 'Sports', 'Travel']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) => setModalState(() => tempCategory = val),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Clasificación', border: OutlineInputBorder()),
                    value: tempRating,
                    items: ['G', 'PG', 'PG-13', 'R', 'NC-17']
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (val) => setModalState(() => tempRating = val),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: 'Año de Lanzamiento', border: OutlineInputBorder()),
                    value: tempYear,
                    items: List.generate(20, (i) => 2006 + i)
                        .map((y) => DropdownMenuItem(value: y, child: Text(y.toString())))
                        .toList(),
                    onChanged: (val) => setModalState(() => tempYear = val),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _filterCategory = null;
                              _filterYear = null;
                              _filterRating = null;
                            });
                            Navigator.pop(context);
                            _loadFilms();
                          },
                          child: const Text('Limpiar'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
                          onPressed: () {
                            setState(() {
                              _filterCategory = tempCategory;
                              _filterYear = tempYear;
                              _filterRating = tempRating;
                            });
                            Navigator.pop(context);
                            _loadFilms();
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
        title: const Text('Administrar Películas'),
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
              _loadFilms();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'title:asc', child: Text('De la A a la Z')),
              const PopupMenuItem(value: 'title:desc', child: Text('De la Z a la A')),
              const PopupMenuItem(value: 'filmId:desc', child: Text('Más nuevas a más viejas')),
              const PopupMenuItem(value: 'filmId:asc', child: Text('Más viejas a más nuevas')),
            ],
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadFilms),
          IconButton(icon: const Icon(Icons.add), onPressed: () async {
            final bool? result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AdminFilmFormPage()),
            );
            if (result == true) {
              _loadFilms();
            }
          }),
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
                      labelText: 'Buscar película...',
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
                  color: (_filterCategory != null || _filterYear != null || _filterRating != null) 
                      ? Theme.of(context).primaryColor 
                      : Colors.grey[700],
                  tooltip: 'Filtros Avanzados',
                  onPressed: _showFilterDialog,
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _onSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
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
                        itemCount: _films.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _films.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
      
                          final film = _films[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: Icon(Icons.movie, color: Theme.of(context).primaryColor),
                              title: Text(film.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('ID: ${film.id} | Tarifa: \$${film.rentalRate}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.inventory, color: Theme.of(context).primaryColor),
                                    tooltip: 'Ver/Administrar Ejemplares',
                                    onPressed: () => _openInventory(film),
                                  ),
                                  Switch(
                                    value: film.active ?? true,
                                    activeColor: Colors.green,
                                    onChanged: (val) => _toggleFilmStatus(film, val),
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
