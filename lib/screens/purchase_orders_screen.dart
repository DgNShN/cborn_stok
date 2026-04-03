import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/stock_repository.dart';
import '../models/app_models.dart';
import '../utils/number_utils.dart';

class PurchaseOrdersScreen extends StatefulWidget {
  const PurchaseOrdersScreen({super.key, required this.repo});

  final StockRepository repo;

  @override
  State<PurchaseOrdersScreen> createState() => _PurchaseOrdersScreenState();
}

class _PurchaseOrdersScreenState extends State<PurchaseOrdersScreen> {
  final _formatter = DateFormat('dd.MM.yyyy HH:mm');
  List<PurchaseOrder> _orders = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final orders = await widget.repo.getPurchaseOrders();
    if (!mounted) return;
    setState(() {
      _orders = orders;
      _loading = false;
    });
  }

  Future<void> _receiveOrder(PurchaseOrder order) async {
    try {
      await widget.repo.receivePurchaseOrder(order.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${order.productName} siparisi stoga islendi.')),
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Siparisler')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? const Center(child: Text('Henuz siparis yok.'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    itemBuilder: (context, index) {
                      final order = _orders[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${order.productCode} - ${order.productName}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                  ),
                                  Chip(
                                    label: Text(order.status.label),
                                    backgroundColor:
                                        order.status.color.withValues(alpha: 0.12),
                                    side: BorderSide(
                                      color:
                                          order.status.color.withValues(alpha: 0.24),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tedarikci: ${order.supplierName.isEmpty ? '-' : order.supplierName}',
                              ),
                              Text(
                                'Miktar: ${formatNumber(order.quantity)}  •  '
                                'Alis: ${formatNumber(order.unitCost)} TL',
                              ),
                              if (order.listPrice > 0 || order.discountPercent > 0)
                                Text(
                                  'Liste: ${formatNumber(order.listPrice)} TL  •  '
                                  'Indirim: ${formatNumber(order.discountPercent, trimTrailingZeros: true)}%',
                                ),
                              Text(
                                'Siparis: ${_formatter.format(order.orderedAt)}'
                                '${order.receivedAt == null ? '' : '  •  Teslim: ${_formatter.format(order.receivedAt!)}'}',
                              ),
                              if (order.note.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text('Not: ${order.note}'),
                              ],
                              if (order.status == PurchaseOrderStatus.pending) ...[
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: FilledButton.icon(
                                    onPressed: () => _receiveOrder(order),
                                    icon: const Icon(Icons.inventory_rounded),
                                    label: const Text('Teslim Al'),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
