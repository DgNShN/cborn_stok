import 'package:flutter/material.dart';

import '../data/stock_repository.dart';
import '../models/app_models.dart';
import '../utils/number_utils.dart';

class StockQueryScreen extends StatefulWidget {
  const StockQueryScreen({super.key, required this.repo});

  final StockRepository repo;

  @override
  State<StockQueryScreen> createState() => _StockQueryScreenState();
}

class _StockQueryScreenState extends State<StockQueryScreen> {
  final _searchController = TextEditingController();
  List<Product> _products = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final products = await widget.repo.getProducts(search: _searchController.text);
    if (!mounted) return;
    setState(() {
      _products = products;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stok Sorgulama')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Urun ara',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => _load(),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? const Center(child: Text('Urun bulunamadi.'))
                    : ListView.builder(
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          final isLowStock =
                              product.minStock > 0 &&
                              product.stockQuantity <= product.minStock;
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            color: isLowStock
                                ? Theme.of(context)
                                    .colorScheme
                                    .errorContainer
                                    .withValues(alpha: 0.5)
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${product.code} - ${product.name}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Mevcut: ${formatNumber(product.stockQuantity)} ${product.unit}\n'
                                              'Min stok: ${formatNumber(product.minStock)}  •  '
                                              'Guncel satis: ${formatNumber(product.salePrice)} TL\n'
                                              'Alis fiyati: ${formatNumber(product.lastCost)} TL  •  '
                                              'Kar: ${formatNumber(product.profitMarginPercent, trimTrailingZeros: true)}%\n'
                                              'Ort. maliyet: ${formatNumber(product.averageCost)} TL  •  '
                                              'Son maliyet: ${formatNumber(product.lastCost)} TL\n'
                                              'Raf: ${product.shelfLocation.isEmpty ? '-' : product.shelfLocation}  •  '
                                              'Marka: ${product.brand.isEmpty ? '-' : product.brand}',
                                            ),
                                            const SizedBox(height: 12),
                                            FutureBuilder<ProductPerformance>(
                                              future: widget.repo
                                                  .getProductPerformance(product.id),
                                              builder: (context, snapshot) {
                                                final performance = snapshot.data;
                                                if (snapshot.connectionState ==
                                                    ConnectionState.waiting) {
                                                  return const LinearProgressIndicator();
                                                }
                                                return Text(
                                                  'Toplam alis: ${formatNumber(performance?.totalPurchasedQuantity ?? 0)} ${product.unit}  •  '
                                                  'Toplam satis: ${formatNumber(performance?.totalSoldQuantity ?? 0)} ${product.unit}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(
                                        isLowStock
                                            ? Icons.warning_amber_rounded
                                            : Icons.check_circle_outline,
                                      ),
                                    ],
                                  ),
                                  if (product.materialGroup.trim().isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    FutureBuilder<List<AlternativeBrandStock>>(
                                      future: widget.repo
                                          .getAlternativeBrandStocks(product),
                                      builder: (context, snapshot) {
                                        final brands = snapshot.data ?? const [];
                                        if (brands.isEmpty) {
                                          return Text(
                                            'Alternatif marka stok: yok',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          );
                                        }
                                        final summary = brands
                                            .map(
                                              (item) =>
                                                  '${item.brand.isEmpty ? item.productName : item.brand}: ${formatNumber(item.stockQuantity)}',
                                            )
                                            .join('  •  ');
                                        return Text(
                                          'Alternatif marka stok: $summary',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    FutureBuilder<List<SubstituteSuggestion>>(
                                      future: widget.repo.getSubstituteSuggestions(
                                        product: product,
                                        requestedQuantity:
                                            product.minStock > 0 ? product.minStock : 1,
                                      ),
                                      builder: (context, snapshot) {
                                        final suggestions =
                                            snapshot.data ?? const [];
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const LinearProgressIndicator();
                                        }
                                        if (suggestions.isEmpty) {
                                          return Text(
                                            'Akilli muadil asistani: onerilecek aktif muadil yok',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          );
                                        }
                                        final topSuggestion = suggestions.first;
                                        return _SubstituteInsightCard(
                                          suggestion: topSuggestion,
                                        );
                                      },
                                    ),
                                  ],
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

class _SubstituteInsightCard extends StatelessWidget {
  const _SubstituteInsightCard({required this.suggestion});

  final SubstituteSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Akilli muadil onerisi',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          Text(
            '${suggestion.code} - ${suggestion.name} '
            '${suggestion.brand.isEmpty ? '' : '• ${suggestion.brand}'}',
          ),
          const SizedBox(height: 4),
          Text(
            'Stok: ${formatNumber(suggestion.stockQuantity)}  •  '
            'Raf: ${suggestion.shelfLocation.isEmpty ? '-' : suggestion.shelfLocation}  •  '
            'Tahmini kar: ${formatNumber(suggestion.profitEstimate)} TL',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (suggestion.canFulfill)
                const Chip(label: Text('Talebi karsilar')),
              if (suggestion.isBestProfit)
                const Chip(label: Text('En karli')),
              if (suggestion.isNearestShelf)
                const Chip(label: Text('En yakin raf')),
            ],
          ),
        ],
      ),
    );
  }
}
