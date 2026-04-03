import 'package:flutter/material.dart';

import '../data/stock_repository.dart';
import '../models/app_models.dart';
import '../utils/number_utils.dart';

class StockActionScreen extends StatefulWidget {
  const StockActionScreen({
    super.key,
    required this.repo,
    required this.type,
  });

  final StockRepository repo;
  final MovementType type;

  @override
  State<StockActionScreen> createState() => _StockActionScreenState();
}

class _StockActionScreenState extends State<StockActionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _unitPriceController = TextEditingController(text: '0');
  final _profitPercentController = TextEditingController(text: '0');
  final _noteController = TextEditingController();
  List<Product> _products = const [];
  int? _selectedProductId;
  bool _loading = true;
  bool _saving = false;
  bool _initializedSelection = false;

  bool get _isStockIn => widget.type == MovementType.stockIn;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _unitPriceController.dispose();
    _profitPercentController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final products = await widget.repo.getProducts();
    if (!mounted) return;
    setState(() {
      _products = products;
      if (!_initializedSelection) {
        _selectedProductId = products.isNotEmpty ? products.first.id : null;
        _initializedSelection = true;
        _syncPricingFromSelectedProduct();
      }
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedProductId == null) return;
    setState(() => _saving = true);

    try {
      await widget.repo.recordMovement(
        productId: _selectedProductId!,
        type: widget.type,
        quantity: parseInputNumber(_quantityController.text),
        unitPrice: _isStockIn
            ? parseInputNumber(_unitPriceController.text)
            : 0,
        profitPercent: _isStockIn
            ? parseInputNumber(_profitPercentController.text)
            : null,
        note: _noteController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.type.label} kaydedildi.')),
      );
      setState(() {
        _selectedProductId = null;
        _quantityController.clear();
        _unitPriceController.text = '0';
        _profitPercentController.text = '0';
        _noteController.clear();
        _saving = false;
      });
      await _loadProducts();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
      setState(() => _saving = false);
    }
  }

  void _selectAllIfHasValue(TextEditingController controller) {
    if (controller.text.isEmpty) return;
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
  }

  Product? get _selectedProduct =>
      _products.where((item) => item.id == _selectedProductId).firstOrNull;

  void _syncPricingFromSelectedProduct() {
    final product = _selectedProduct;
    if (product == null || !_isStockIn) return;
    _unitPriceController.text = formatNumber(
      product.lastCost,
      trimTrailingZeros: true,
    );
    _profitPercentController.text = formatNumber(
      product.profitMarginPercent,
      trimTrailingZeros: true,
    );
  }

  double get _calculatedSalePrice {
    final purchasePrice = parseInputNumber(_unitPriceController.text);
    final profitPercent = parseInputNumber(_profitPercentController.text);
    return purchasePrice * (1 + (profitPercent / 100));
  }

  String? _validateProfitPercent(String? value) {
    final cleaned = (value ?? '').trim();
    if (cleaned.isEmpty) return 'Kar yuzdesi zorunlu';
    final parsed = parseInputNumber(cleaned);
    if (parsed < 0) return 'Kar yuzdesi negatif olamaz';
    if (parsed > maxPriceValue) return 'Kar yuzdesi cok buyuk';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selectedProduct = _selectedProduct;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
      appBar: AppBar(title: Text(widget.type.label)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? const Center(child: Text('Once urun eklemelisin.'))
              : SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<int>(
                          key: ValueKey(_selectedProductId),
                          initialValue: _selectedProductId,
                          decoration: const InputDecoration(
                            labelText: 'Urun',
                            hintText: 'Urun sec',
                          ),
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
                          onChanged: (value) => setState(() {
                            _selectedProductId = value;
                            _syncPricingFromSelectedProduct();
                          }),
                          validator: (value) =>
                              value == null ? 'Urun secmelisin' : null,
                        ),
                        if (selectedProduct != null) ...[
                          const SizedBox(height: 12),
                          FutureBuilder<ProductPerformance>(
                            future: widget.repo.getProductPerformance(
                              selectedProduct.id,
                            ),
                            builder: (context, snapshot) {
                              final performance = snapshot.data;
                              return _ProductInfoCard(
                                product: selectedProduct,
                                performance: performance,
                              );
                            },
                          ),
                        ],
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _quantityController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(labelText: 'Miktar'),
                          onTap: () => _selectAllIfHasValue(_quantityController),
                          validator: (value) =>
                              validateStockNumber(value, allowZero: false),
                        ),
                        if (_isStockIn) ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _unitPriceController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Alis Fiyati',
                            ),
                            onTap: () => _selectAllIfHasValue(_unitPriceController),
                            onChanged: (_) => setState(() {}),
                            validator: validatePriceNumber,
                          ),
                          if (selectedProduct != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Varsayilan satis fiyati: ${formatNumber(selectedProduct.salePrice)} TL',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _profitPercentController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Kar Yuzdesi',
                              suffixText: '%',
                            ),
                            onTap: () => _selectAllIfHasValue(_profitPercentController),
                            onChanged: (_) => setState(() {}),
                            validator: _validateProfitPercent,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Onerilen satis fiyati: ${formatNumber(_calculatedSalePrice)} TL',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _noteController,
                          decoration: const InputDecoration(labelText: 'Not'),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _saving ? null : _save,
                            child: Text(_saving ? 'Kaydediliyor...' : 'Kaydet'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

}

class _ProductInfoCard extends StatelessWidget {
  const _ProductInfoCard({
    required this.product,
    required this.performance,
  });

  final Product product;
  final ProductPerformance? performance;

  @override
  Widget build(BuildContext context) {
    final infoStyle = Theme.of(context).textTheme.bodyMedium;
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Parca Ozeti',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Alis fiyati: ${formatNumber(product.lastCost)} TL', style: infoStyle),
            Text('Satis fiyati: ${formatNumber(product.salePrice)} TL', style: infoStyle),
            Text(
              'Kar orani: ${formatNumber(product.profitMarginPercent, trimTrailingZeros: true)}%',
              style: infoStyle,
            ),
            Text(
              'Raf: ${product.shelfLocation.isEmpty ? '-' : product.shelfLocation}',
              style: infoStyle,
            ),
            const SizedBox(height: 8),
            if (performance == null)
              const LinearProgressIndicator()
            else ...[
              Text(
                'Toplam alis adedi: ${formatNumber(performance!.totalPurchasedQuantity)} ${product.unit}',
                style: infoStyle,
              ),
              Text(
                'Toplam satis adedi: ${formatNumber(performance!.totalSoldQuantity)} ${product.unit}',
                style: infoStyle,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
