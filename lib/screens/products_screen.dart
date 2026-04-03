import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../data/stock_repository.dart';
import '../models/app_models.dart';
import '../utils/number_utils.dart';
import 'product_import_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key, required this.repo});

  final StockRepository repo;

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
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

  Future<void> _openForm([Product? product]) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ProductFormSheet(repo: widget.repo, product: product),
    );
    if (mounted) {
      setState(() => _loading = true);
      await _load();
    }
  }

  Future<void> _deleteProduct(Product product) async {
    try {
      await widget.repo.deleteProduct(product.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.name} silindi.')),
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
      appBar: AppBar(
        title: const Text('Urunler'),
        actions: [
          IconButton(
            tooltip: 'Toplu Ice Aktar',
            onPressed: () async {
              await Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ProductImportScreen(repo: widget.repo),
                ),
              );
              if (mounted) {
                setState(() => _loading = true);
                await _load();
              }
            },
            icon: const Icon(Icons.upload_file_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Urun Ekle'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Ara',
                hintText: 'Kod veya urun adi',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _load();
                  },
                  icon: const Icon(Icons.clear),
                ),
              ),
              onChanged: (_) => _load(),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? const Center(child: Text('Henuz urun eklenmedi.'))
                    : ListView.builder(
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            child: ListTile(
                              leading: _ProductImageThumb(
                                imagePath: product.imagePath,
                              ),
                              title: Text('${product.code} - ${product.name}'),
                              subtitle: Text(
                                'Stok: ${formatNumber(product.stockQuantity)} ${product.unit}  •  '
                                'Satis: ${formatNumber(product.salePrice)} TL  •  '
                                'Kar: ${formatNumber(product.profitMarginPercent, trimTrailingZeros: true)}%  •  '
                                'Ort. Maliyet: ${formatNumber(product.averageCost)} TL\n'
                                'Son Maliyet: ${formatNumber(product.lastCost)} TL  •  '
                                'Raf: ${product.shelfLocation.isEmpty ? '-' : product.shelfLocation}  •  '
                                'Marka: ${product.brand.isEmpty ? '-' : product.brand}',
                              ),
                              isThreeLine: true,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () => _openForm(product),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    onPressed: () => _deleteProduct(product),
                                    icon: const Icon(Icons.delete_outline),
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

class ProductFormSheet extends StatefulWidget {
  const ProductFormSheet({
    super.key,
    required this.repo,
    this.product,
  });

  final StockRepository repo;
  final Product? product;

  @override
  State<ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _materialGroupController;
  late final TextEditingController _shelfLocationController;
  late final TextEditingController _unitController;
  late final TextEditingController _priceController;
  late final TextEditingController _minStockController;
  String _imagePath = '';
  final List<_SupplierDraftController> _supplierDrafts = [];
  bool _saving = false;
  bool _loadingSuppliers = false;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _codeController = TextEditingController(text: product?.code ?? '');
    _nameController = TextEditingController(text: product?.name ?? '');
    _brandController = TextEditingController(text: product?.brand ?? '');
    _materialGroupController = TextEditingController(
      text: product?.materialGroup ?? '',
    );
    _shelfLocationController = TextEditingController(
      text: product?.shelfLocation ?? '',
    );
    _unitController = TextEditingController(text: product?.unit ?? 'Adet');
    _priceController = TextEditingController(
      text: product?.salePrice.toStringAsFixed(2) ?? '0',
    );
    _minStockController = TextEditingController(
      text: product?.minStock.toStringAsFixed(2) ?? '0',
    );
    _imagePath = product?.imagePath ?? '';
    if (product == null) {
      _addSupplierDraft();
    } else {
      _loadSuppliers();
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _brandController.dispose();
    _materialGroupController.dispose();
    _shelfLocationController.dispose();
    _unitController.dispose();
    _priceController.dispose();
    _minStockController.dispose();
    for (final draft in _supplierDrafts) {
      draft.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSuppliers() async {
    final product = widget.product;
    if (product == null) return;
    setState(() => _loadingSuppliers = true);
    final offers = await widget.repo.getProductSuppliers(product.id);
    if (!mounted) return;
    for (final draft in _supplierDrafts) {
      draft.dispose();
    }
    _supplierDrafts
      ..clear()
      ..addAll(
        offers.map(
          (offer) => _SupplierDraftController.fromOffer(offer),
        ),
      );
    if (_supplierDrafts.isEmpty) {
      _addSupplierDraft(notify: false);
    }
    setState(() => _loadingSuppliers = false);
  }

  void _addSupplierDraft({bool notify = true}) {
    _supplierDrafts.add(_SupplierDraftController());
    if (notify) {
      setState(() {});
    }
  }

  void _removeSupplierDraft(int index) {
    final draft = _supplierDrafts.removeAt(index);
    draft.dispose();
    if (_supplierDrafts.isEmpty) {
      _addSupplierDraft(notify: false);
    }
    setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final productId = await widget.repo.saveProduct(
        id: widget.product?.id,
        code: _codeController.text,
        name: _nameController.text,
        brand: _brandController.text,
        materialGroup: _materialGroupController.text,
        shelfLocation: _shelfLocationController.text,
        imagePath: _imagePath,
        unit: _unitController.text,
        salePrice: parseInputNumber(_priceController.text),
        minStock: parseInputNumber(_minStockController.text),
      );
      await widget.repo.replaceProductSuppliers(
        productId: productId,
        drafts: _supplierDrafts
            .asMap()
            .entries
            .map((entry) => entry.value.toDraft(priority: entry.key))
            .where((draft) => draft.supplierName.trim().isNotEmpty)
            .toList(),
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
      setState(() => _saving = false);
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    final sourcePath = result?.files.single.path;
    if (sourcePath == null) return;

    try {
      final importedPath = await widget.repo.importProductImage(
        sourcePath,
        _codeController.text.trim().isEmpty ? _nameController.text : _codeController.text,
      );
      if (!mounted) return;
      setState(() => _imagePath = importedPath);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.product == null ? 'Yeni Urun' : 'Urun Duzenle',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: 'Urun Kodu'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Zorunlu alan' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Urun Adi'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Zorunlu alan' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(labelText: 'Marka'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _materialGroupController,
                decoration: const InputDecoration(
                  labelText: 'Malzeme Grubu',
                  hintText: 'Ayni malzemenin ortak adi',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _shelfLocationController,
                decoration: const InputDecoration(labelText: 'Raf Yeri'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _ProductImageThumb(imagePath: _imagePath, size: 72),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: _saving ? null : _pickImage,
                          icon: const Icon(Icons.image_outlined),
                          label: Text(
                            _imagePath.isEmpty ? 'Resim Sec' : 'Resmi Degistir',
                          ),
                        ),
                        if (_imagePath.isNotEmpty)
                          TextButton(
                            onPressed: _saving
                                ? null
                                : () => setState(() => _imagePath = ''),
                            child: const Text('Resmi Kaldir'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _unitController,
                decoration: const InputDecoration(labelText: 'Birim'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Guncel Satis Fiyati'),
                validator: validatePriceNumber,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _minStockController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Minimum Stok'),
                validator: validateStockNumber,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tedarikciler',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _saving ? null : _addSupplierDraft,
                    icon: const Icon(Icons.add),
                    label: const Text('Tedarikci Ekle'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_loadingSuppliers)
                const LinearProgressIndicator()
              else
                for (var i = 0; i < _supplierDrafts.length; i++) ...[
                  _SupplierDraftCard(
                    draft: _supplierDrafts[i],
                    index: i,
                    onRemove: _supplierDrafts.length == 1
                        ? null
                        : () => _removeSupplierDraft(i),
                  ),
                  const SizedBox(height: 12),
                ],
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

class _ProductImageThumb extends StatelessWidget {
  const _ProductImageThumb({
    required this.imagePath,
    this.size = 52,
  });

  final String imagePath;
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    return ClipRRect(
      borderRadius: radius,
      child: Container(
        width: size,
        height: size,
        color: const Color(0xFFE5E7EB),
        child: imagePath.isEmpty
            ? const Icon(Icons.inventory_2_outlined)
            : Image.file(
                File(imagePath),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.broken_image_outlined),
              ),
      ),
    );
  }
}

class _SupplierDraftController {
  _SupplierDraftController({
    String supplierName = '',
    String listPrice = '0',
    String discountPercent = '0',
    this.isOriginal = false,
    this.priority = 0,
    String note = '',
  })  : supplierNameController = TextEditingController(text: supplierName),
        listPriceController = TextEditingController(text: listPrice),
        discountPercentController = TextEditingController(text: discountPercent),
        noteController = TextEditingController(text: note);

  factory _SupplierDraftController.fromOffer(ProductSupplierOffer offer) {
    return _SupplierDraftController(
      supplierName: offer.supplierName,
      listPrice: formatNumber(offer.listPrice, trimTrailingZeros: true),
      discountPercent: formatNumber(
        offer.discountPercent,
        trimTrailingZeros: true,
      ),
      isOriginal: offer.isOriginal,
      priority: offer.priority,
      note: offer.note,
    );
  }

  final TextEditingController supplierNameController;
  final TextEditingController listPriceController;
  final TextEditingController discountPercentController;
  final TextEditingController noteController;
  bool isOriginal;
  int priority;

  ProductSupplierDraft toDraft({int? priority}) {
    return ProductSupplierDraft(
      supplierName: supplierNameController.text,
      listPrice: parseInputNumber(listPriceController.text),
      discountPercent: parseInputNumber(discountPercentController.text),
      isOriginal: isOriginal,
      priority: priority ?? this.priority,
      note: noteController.text,
    );
  }

  void dispose() {
    supplierNameController.dispose();
    listPriceController.dispose();
    discountPercentController.dispose();
    noteController.dispose();
  }
}

class _SupplierDraftCard extends StatefulWidget {
  const _SupplierDraftCard({
    required this.draft,
    required this.index,
    this.onRemove,
  });

  final _SupplierDraftController draft;
  final int index;
  final VoidCallback? onRemove;

  @override
  State<_SupplierDraftCard> createState() => _SupplierDraftCardState();
}

class _SupplierDraftCardState extends State<_SupplierDraftCard> {
  @override
  void initState() {
    super.initState();
    widget.draft.listPriceController.addListener(_refresh);
    widget.draft.discountPercentController.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.draft.listPriceController.removeListener(_refresh);
    widget.draft.discountPercentController.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final netPrice = draft.toDraft().netPrice;
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
                    'Tedarikci ${widget.index + 1}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (widget.onRemove != null)
                  IconButton(
                    onPressed: widget.onRemove,
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            TextFormField(
              controller: draft.supplierNameController,
              decoration: const InputDecoration(labelText: 'Tedarikci Adi'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: draft.listPriceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Liste Fiyati'),
                    validator: validatePriceNumber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: draft.discountPercentController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Indirim',
                      suffixText: '%',
                    ),
                    validator: (value) {
                      final parsed = parseInputNumber((value ?? '').trim());
                      if (parsed < 0 || parsed > 100) {
                        return '0-100 arasi olmali';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Net alis: ${formatNumber(netPrice)} TL'),
            CheckboxListTile(
              value: draft.isOriginal,
              onChanged: (value) {
                setState(() => draft.isOriginal = value ?? false);
              },
              contentPadding: EdgeInsets.zero,
              title: const Text('Orijinal parca'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            TextFormField(
              controller: draft.noteController,
              decoration: const InputDecoration(labelText: 'Not'),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
