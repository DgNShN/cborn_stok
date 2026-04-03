import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/stock_repository.dart';
import '../models/app_models.dart';

class MovementsScreen extends StatefulWidget {
  const MovementsScreen({super.key, required this.repo});

  final StockRepository repo;

  @override
  State<MovementsScreen> createState() => _MovementsScreenState();
}

class _MovementsScreenState extends State<MovementsScreen> {
  final _formatter = DateFormat('dd.MM.yyyy HH:mm');
  List<StockMovement> _movements = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final movements = await widget.repo.getMovements();
    if (!mounted) return;
    setState(() {
      _movements = movements;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hareket Gecmisi')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _movements.isEmpty
              ? const Center(child: Text('Henuz hareket kaydi yok.'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _movements.length,
                    itemBuilder: (context, index) {
                      final movement = _movements[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: movement.type.color.withValues(
                              alpha: 0.15,
                            ),
                            child: Icon(
                              movement.type == MovementType.stockIn
                                  ? Icons.south
                                  : movement.type == MovementType.stockOut
                                      ? Icons.north
                                      : Icons.shopping_cart_checkout,
                              color: movement.type.color,
                            ),
                          ),
                          title: Text(
                            '${movement.productCode} - ${movement.productName}',
                          ),
                          subtitle: Text(
                            '${movement.type.label} • '
                            '${movement.quantity.toStringAsFixed(2)}\n'
                            '${_formatter.format(movement.createdAt)}'
                            '${movement.note.isEmpty ? '' : ' • ${movement.note}'}',
                          ),
                          isThreeLine: true,
                          trailing: Text(
                            movement.unitPrice > 0
                                ? '${movement.unitPrice.toStringAsFixed(2)} TL'
                                : '-',
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
