import 'package:flutter/material.dart';
import '../models/film.dart';
import '../models/api_error.dart';
import '../services/rental_service.dart';

class CheckoutPage extends StatefulWidget {
  final Film film;

  const CheckoutPage({super.key, required this.film});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expirationDateController = TextEditingController();
  final _cvvController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expirationDateController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  Future<void> _processRental() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await RentalService.createRentalAndPay(
        filmId: widget.film.id,
        cardNumber: _cardNumberController.text.trim(),
        cardHolder: _cardHolderController.text.trim(),
        expirationDate: _expirationDateController.text.trim(),
        cvv: _cvvController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alquiler procesado con éxito'), backgroundColor: Colors.green),
      );
      Navigator.popUntil(context, (route) => route.isFirst); // Go back to Catalog
    } on ApiError catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Error en el alquiler'), backgroundColor: Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout Seguro'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock, size: 50, color: Theme.of(context).primaryColor),
                      const SizedBox(height: 20),
                      Text(
                        'Alquilar: ${widget.film.title}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Total a pagar: \$${widget.film.rentalRate}',
                        style: const TextStyle(fontSize: 18, color: Colors.green),
                        textAlign: TextAlign.center,
                      ),
                      const Divider(height: 40),
                      TextFormField(
                        controller: _cardNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Número de Tarjeta',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.credit_card),
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 16,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Requerido';
                          if (value.length != 16) return 'Debe tener 16 dígitos';
                          if (!RegExp(r'^\d+$').hasMatch(value)) return 'Solo números';
                          
                          // Algoritmo de Luhn
                          int sum = 0;
                          bool isSecond = false;
                          for (int i = value.length - 1; i >= 0; i--) {
                            int d = int.parse(value[i]);
                            if (isSecond) {
                              d = d * 2;
                              if (d > 9) d -= 9;
                            }
                            sum += d;
                            isSecond = !isSecond;
                          }
                          if (sum % 10 != 0) return 'Número de tarjeta inválido';
                          
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _cardHolderController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del Titular',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _expirationDateController,
                              decoration: const InputDecoration(
                                labelText: 'Expiración (MM/AA)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.date_range),
                              ),
                              maxLength: 5,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Requerido';
                                if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) return 'Formato MM/AA';
                                
                                final parts = value.split('/');
                                final month = int.tryParse(parts[0]) ?? 0;
                                final year = (int.tryParse(parts[1]) ?? 0) + 2000;
                                
                                if (month < 1 || month > 12) return 'Mes inválido';
                                
                                final now = DateTime.now();
                                if (year < now.year) return 'Tarjeta expirada';
                                if (year == now.year && month < now.month) return 'Tarjeta expirada';
                                
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _cvvController,
                              decoration: const InputDecoration(
                                labelText: 'CVV',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.security),
                              ),
                              keyboardType: TextInputType.number,
                              maxLength: 3,
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Requerido';
                                if (!RegExp(r'^\d{3}$').hasMatch(value)) return 'Debe tener 3 dígitos';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _processRental,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Confirmar Pago y Alquilar', style: TextStyle(fontSize: 18)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
