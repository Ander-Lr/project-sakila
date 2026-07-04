import 'package:flutter/material.dart';
import '../services/film_service.dart';
import '../models/film.dart';
import '../components/app_drawer.dart';
import 'film_detail_page.dart';

class CustomerPage extends StatefulWidget {
  final String role;
  const CustomerPage({super.key, required this.role});

  @override
  State<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final List<Film> _films = [];
  final Map<int, int> _inventoryCache = {}; // Cache para inventarios {filmId: count}

  bool _isLoading = true;
  bool _isFetchingMore = false;
  String _error = '';

  int _currentPage = 0;
  final int _pageSize = 12;
  bool _hasMore = true;

  String _sortBy = 'filmId';
  String _sortDir = 'desc';

  // Filtros activos
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
      _fetchInventories(newFilms);
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
      _fetchInventories(newFilms);
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

  Future<void> _fetchInventories(List<Film> films) async {
    for (var film in films) {
      if (!_inventoryCache.containsKey(film.id!)) {
        try {
          final count = await FilmService.checkInventory(film.id!);
          if (mounted) {
            setState(() {
              _inventoryCache[film.id!] = count;
            });
          }
        } catch (e) {
          debugPrint('Error loading inventory for ${film.id!}: $e');
        }
      }
    }
  }

  void _onSearch() {
    _loadFilms(query: _searchController.text.trim());
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
                top: 24,
                left: 24,
                right: 24,
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
                    items: List.generate(20, (i) => 2006 + i) // Del 2006 en adelante (Sakila DB)
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
                          child: const Text('Limpiar Filtros'),
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
                          child: const Text('Aplicar Filtros'),
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

  Widget _buildFilmCard(Film film) {
    final copies = _inventoryCache[film.id!];
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FilmDetailPage(film: film),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Image Placeholder
            Expanded(
              flex: 3,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                ),
                child: Center(
                  child: Icon(Icons.movie_creation, size: 48, color: Colors.grey[400]),
                ),
              ),
            ),
            // Details
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      film.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            film.rating ?? 'N/A',
                            style: const TextStyle(fontSize: 10, color: Colors.redAccent, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${film.releaseYear ?? "-"}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (film.categories != null && film.categories!.isNotEmpty)
                      Text(
                        film.categories!.join(', '),
                        style: TextStyle(fontSize: 11, color: Colors.grey[500], fontStyle: FontStyle.italic),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${film.rentalRate}',
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        if (copies != null)
                          Row(
                            children: [
                              Icon(Icons.inventory_2, size: 14, color: copies > 0 ? Theme.of(context).primaryColor : Colors.red),
                              const SizedBox(width: 4),
                              Text(
                                copies > 0 ? '$copies disp.' : 'Agotado',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: copies > 0 ? Theme.of(context).primaryColor : Colors.red,
                                ),
                              ),
                            ],
                          )
                        else
                          const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Películas'),
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
              const PopupMenuItem(value: 'title:asc', child: Text('Título A-Z')),
              const PopupMenuItem(value: 'title:desc', child: Text('Título Z-A')),
              const PopupMenuItem(value: 'rentalRate:desc', child: Text('Precio mayor a menor')),
              const PopupMenuItem(value: 'rentalRate:asc', child: Text('Precio menor a mayor')),
              const PopupMenuItem(value: 'releaseYear:desc', child: Text('Más recientes primero')),
            ],
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => _loadFilms()),
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
                      labelText: 'Buscar por título...',
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
                    : _films.isEmpty
                        ? const Center(child: Text('No se encontraron películas.', style: TextStyle(fontSize: 16)))
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              int crossAxisCount = constraints.maxWidth > 900
                                  ? 5
                                  : constraints.maxWidth > 600
                                      ? 3
                                      : 2;
                              return GridView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(16),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 0.65, // Adjust for new card height
                                ),
                                itemCount: _films.length + (_hasMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == _films.length) {
                                    return const Center(child: CircularProgressIndicator());
                                  }
                                  return _buildFilmCard(_films[index]);
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
