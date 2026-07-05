import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/film.dart';
import '../services/film_service.dart';

class AdminFilmFormPage extends StatefulWidget {
  const AdminFilmFormPage({super.key});

  @override
  State<AdminFilmFormPage> createState() => _AdminFilmFormPageState();
}

class _AdminFilmFormPageState extends State<AdminFilmFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _rentalRateController = TextEditingController(text: '4.99');
  final _replacementCostController = TextEditingController(text: '19.99');
  int _releaseYear = DateTime.now().year;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _rentalRateController.dispose();
    _replacementCostController.dispose();
    super.dispose();
  }

  Future<void> _saveFilm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final film = Film(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        releaseYear: _releaseYear,
        languageId: 1, // Defaulting to English (1)
        rentalDuration: 3, // Defaulting
        rentalRate: double.parse(_rentalRateController.text),
        length: 120, // Defaulting
        replacementCost: double.parse(_replacementCostController.text),
        active: true,
      );

      await FilmService.createFilm(film);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Película creada exitosamente'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // Retorna true para refrescar la lista
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Película'),
        backgroundColor: Colors.redAccent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Título *', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _releaseYear,
                      decoration: const InputDecoration(labelText: 'Año de Lanzamiento', border: OutlineInputBorder()),
                      items: List.generate(DateTime.now().year - 1899, (index) => DateTime.now().year - index)
                          .map((year) => DropdownMenuItem(value: year, child: Text(year.toString())))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _releaseYear = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _rentalRateController,
                      decoration: const InputDecoration(labelText: 'Tarifa de Alquiler (\$)', border: OutlineInputBorder()),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        final val = double.tryParse(v);
                        if (val == null) return 'Debe ser un número válido';
                        if (val < 0.99) return 'Mínimo \$0.99';
                        if (val > 20.00) return 'Máximo \$20.00';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _replacementCostController,
                      decoration: const InputDecoration(labelText: 'Costo de Reemplazo (\$)', border: OutlineInputBorder()),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        final val = double.tryParse(v);
                        if (val == null) return 'Debe ser un número válido';
                        if (val < 5.00) return 'Mínimo \$5.00';
                        if (val > 150.00) return 'Máximo \$150.00';
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _saveFilm,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Crear Película', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
