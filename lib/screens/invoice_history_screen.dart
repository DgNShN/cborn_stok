import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../data/stock_repository.dart';
import '../models/app_models.dart';

class InvoiceHistoryScreen extends StatefulWidget {
  const InvoiceHistoryScreen({super.key, required this.repo});

  final StockRepository repo;

  @override
  State<InvoiceHistoryScreen> createState() => _InvoiceHistoryScreenState();
}

class _InvoiceHistoryScreenState extends State<InvoiceHistoryScreen> {
  final _dateFormatter = DateFormat('dd.MM.yyyy HH:mm');
  List<SaleRecord> _sales = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sales = await widget.repo.getSales();
    if (!mounted) return;
    setState(() {
      _sales = sales;
      _loading = false;
    });
  }

  Future<void> _showItems(SaleRecord sale) async {
    final items = await widget.repo.getSaleItems(sale.id);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(sale.invoiceNo),
        content: SizedBox(
          width: double.maxFinite,
          child: items.isEmpty
              ? const Text('Satir bulunamadi.')
              : ListView(
                  shrinkWrap: true,
                  children: items
                      .map(
                        (item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.productName),
                          subtitle: Text(
                            '${item.quantity.toStringAsFixed(2)} x '
                            '${item.unitPrice.toStringAsFixed(2)} TL',
                          ),
                          trailing: Text('${item.lineTotal.toStringAsFixed(2)} TL'),
                        ),
                      )
                      .toList(),
                ),
        ),
      ),
    );
  }

  Future<void> _sharePdf(SaleRecord sale) async {
    final path = sale.pdfPath;
    if (path == null || path.isEmpty || !File(path).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF dosyasi bulunamadi.')),
      );
      return;
    }

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path)],
        text: '${sale.invoiceNo} irsaliyesi',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Irsaliye Gecmisi')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sales.isEmpty
              ? const Center(child: Text('Henuz satis kaydi yok.'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _sales.length,
                    itemBuilder: (context, index) {
                      final sale = _sales[index];
                      return Card(
                        child: ListTile(
                          title: Text(sale.invoiceNo),
                          subtitle: Text(
                            '${sale.customerName.isEmpty ? 'Genel Musteri' : sale.customerName}\n'
                            '${_dateFormatter.format(sale.createdAt)}  •  '
                            '${sale.itemCount} kalem',
                          ),
                          isThreeLine: true,
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${sale.totalAmount.toStringAsFixed(2)} TL'),
                              const SizedBox(height: 4),
                              TextButton(
                                onPressed: () => _sharePdf(sale),
                                child: const Text('PDF'),
                              ),
                            ],
                          ),
                          onTap: () => _showItems(sale),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
