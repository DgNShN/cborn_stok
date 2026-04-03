import 'package:flutter/material.dart';

import '../data/stock_repository.dart';
import '../models/app_models.dart';
import '../services/pdf_service.dart';
import '../utils/number_utils.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key, required this.repo});

  final StockRepository repo;

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerController = TextEditingController();
  final _phoneController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController(text: '0');
  final _pdfService = PdfService();

  List<Product> _products = const [];
  List<SaleDraftItem> _items = [];
  int? _selectedProductId;
  bool _loading = true;
  bool _saving = false;
  bool _addingItem = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _customerController.dispose();
    _phoneController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final products = await widget.repo.getProducts();
    if (!mounted) return;
    setState(() {
      _products = products;
      _selectedProductId ??= products.isNotEmpty ? products.first.id : null;
      if (_selectedProductId != null) {
        final selected = products.firstWhere((p) => p.id == _selectedProductId);
        _priceController.text = selected.salePrice.toStringAsFixed(2);
      }
      _loading = false;
    });
  }

  void _onProductChanged(int? value) {
    setState(() {
      _selectedProductId = value;
      final selected = _products.where((p) => p.id == value).firstOrNull;
      if (selected != null) {
        _priceController.text = selected.salePrice.toStringAsFixed(2);
      }
    });
  }

  void _addItem() {
    if (_selectedProductId == null || _addingItem) return;
    final product = _products.firstWhere((item) => item.id == _selectedProductId);
    final quantity = double.tryParse(
      _quantityController.text.trim().replaceAll('.', '').replaceAll(',', '.'),
    );
    final unitPrice = double.tryParse(
      _priceController.text.trim().replaceAll('.', '').replaceAll(',', '.'),
    );

    if (quantity == null ||
        quantity <= 0 ||
        quantity > maxStockValue ||
        unitPrice == null ||
        unitPrice < 0 ||
        unitPrice > maxPriceValue) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Miktar ve fiyat bilgilerini kontrol et.')),
      );
      return;
    }

    setState(() {
      _addingItem = true;
      final existingIndex = _items.indexWhere(
        (item) =>
            item.product.id == product.id &&
            item.unitPrice.toStringAsFixed(2) == unitPrice.toStringAsFixed(2),
      );
      if (existingIndex >= 0) {
        final current = _items[existingIndex];
        _items = [..._items];
        _items[existingIndex] = SaleDraftItem(
          product: current.product,
          quantity: current.quantity + quantity,
          unitPrice: current.unitPrice,
        );
      } else {
        _items = [
          ..._items,
          SaleDraftItem(
            product: product,
            quantity: quantity,
            unitPrice: unitPrice,
          ),
        ];
      }
      _quantityController.text = '1';
      _priceController.text = product.salePrice.toStringAsFixed(2);
    });

    Future<void>.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() => _addingItem = false);
    });
  }

  Future<void> _completeSale() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Once sepete urun eklemelisin.')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final sale = await widget.repo.createSale(
        customerName: _customerController.text,
        customerPhone: _phoneController.text,
        items: _items,
      );
      final lines = await widget.repo.getSaleItems(sale.id);
      final pdfPath = await _pdfService.createDispatchPdf(sale: sale, items: lines);
      await widget.repo.updateSalePdfPath(sale.id, pdfPath);

      if (!mounted) return;
      setState(() {
        _items = [];
        _customerController.clear();
        _phoneController.clear();
        _saving = false;
      });
      await _loadProducts();

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Satis Tamamlandi'),
          content: Text(
            'Belge No: ${sale.invoiceNo}\nPDF: $pdfPath',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tamam'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
      setState(() => _saving = false);
    }
  }

  Product? get _selectedProduct =>
      _products.where((item) => item.id == _selectedProductId).firstOrNull;

  double get _requestedQuantity =>
      parseInputNumber(_quantityController.text.trim()).clamp(0, maxStockValue);

  Widget _buildSubstituteAssistant(Product selectedProduct) {
    final requestedQuantity = _requestedQuantity <= 0 ? 1.0 : _requestedQuantity;
    final needsSuggestion = selectedProduct.stockQuantity < requestedQuantity;

    return FutureBuilder<List<SubstituteSuggestion>>(
      future: widget.repo.getSubstituteSuggestions(
        product: selectedProduct,
        requestedQuantity: requestedQuantity,
      ),
      builder: (context, snapshot) {
        final suggestions = snapshot.data ?? const [];
        if (!needsSuggestion && suggestions.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      needsSuggestion ? Icons.auto_awesome : Icons.tips_and_updates,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        needsSuggestion
                            ? 'Akilli Muadil Asistani: secili urun miktari karsilamiyor'
                            : 'Akilli Muadil Asistani',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  needsSuggestion
                      ? 'Istenen miktar: ${formatNumber(requestedQuantity)} ${selectedProduct.unit} • '
                          'Mevcut stok: ${formatNumber(selectedProduct.stockQuantity)} ${selectedProduct.unit}'
                      : 'Ayni malzeme grubunda kullanilabilecek alternatifler listeleniyor.',
                ),
                if (snapshot.connectionState == ConnectionState.waiting) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ] else if (suggestions.isEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Uygun muadil bulunamadi.'),
                ] else ...[
                  const SizedBox(height: 12),
                  ...suggestions.take(3).map(
                    (suggestion) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _SubstituteSuggestionTile(
                        suggestion: suggestion,
                        requestedQuantity: requestedQuantity,
                        onUse: () {
                          _onProductChanged(suggestion.productId);
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _items.fold<double>(0, (sum, item) => sum + item.lineTotal);
    final selectedProduct = _selectedProduct;

    return Scaffold(
      appBar: AppBar(title: const Text('Satis Yap')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? const Center(child: Text('Satis icin once urun eklemelisin.'))
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      TextFormField(
                        controller: _customerController,
                        decoration: const InputDecoration(
                          labelText: 'Musteri Adi',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Musteri Telefonu',
                        ),
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<int>(
                        initialValue: _selectedProductId,
                        decoration: const InputDecoration(labelText: 'Urun'),
                        items: _products
                            .map(
                              (product) => DropdownMenuItem(
                                value: product.id,
                                child: Text(
                                  '${product.code} - ${product.name} '
                                  '${product.brand.isEmpty ? '' : '- ${product.brand} '}'
                                  '(Stok: ${formatNumber(product.stockQuantity)}'
                                  '${product.shelfLocation.isEmpty ? '' : ', Raf: ${product.shelfLocation}'})',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: _onProductChanged,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _quantityController,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: const InputDecoration(labelText: 'Miktar'),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Guncel Satis Fiyati',
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (selectedProduct != null) ...[
                        const SizedBox(height: 12),
                        _buildSubstituteAssistant(selectedProduct),
                      ],
                      const SizedBox(height: 12),
                      FilledButton.tonalIcon(
                        onPressed: _addingItem ? null : _addItem,
                        icon: const Icon(Icons.add_shopping_cart),
                        label: Text(
                          _addingItem ? 'Ekleniyor...' : 'Sepete Ekle',
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Sepet',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (_items.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Sepette urun yok.'),
                          ),
                        ),
                      for (var i = 0; i < _items.length; i++)
                        Card(
                          child: ListTile(
                            title: Text(_items[i].product.name),
                            subtitle: Text(
                              '${_items[i].quantity.toStringAsFixed(2)} x '
                              '${_items[i].unitPrice.toStringAsFixed(2)} TL',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('${formatNumber(_items[i].lineTotal)} TL'),
                                IconButton(
                                  onPressed: () {
                                    setState(() => _items.removeAt(i));
                                  },
                                  icon: const Icon(Icons.close),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        'Genel Toplam: ${formatNumber(total)} TL',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _saving ? null : _completeSale,
                        child: Text(_saving ? 'Kaydediliyor...' : 'Satisi Tamamla'),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _SubstituteSuggestionTile extends StatelessWidget {
  const _SubstituteSuggestionTile({
    required this.suggestion,
    required this.requestedQuantity,
    required this.onUse,
  });

  final SubstituteSuggestion suggestion;
  final double requestedQuantity;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${suggestion.code} - ${suggestion.name}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              FilledButton.tonal(
                onPressed: onUse,
                child: const Text('Sec'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Marka: ${suggestion.brand.isEmpty ? '-' : suggestion.brand}  •  '
            'Raf: ${suggestion.shelfLocation.isEmpty ? '-' : suggestion.shelfLocation}',
          ),
          const SizedBox(height: 6),
          Text(
            'Stok: ${formatNumber(suggestion.stockQuantity)}  •  '
            'Satis: ${formatNumber(suggestion.salePrice)} TL  •  '
            'Tahmini kar: ${formatNumber(suggestion.profitEstimate)} TL',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (suggestion.canFulfill)
                Chip(
                  avatar: const Icon(Icons.check_circle_outline, size: 18),
                  label: Text(
                    '${formatNumber(requestedQuantity)} adedi karsilar',
                  ),
                ),
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

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
