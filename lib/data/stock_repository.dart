import 'package:sqflite/sqflite.dart';

import '../db/db.dart';
import '../models/app_models.dart';
import '../utils/number_utils.dart';

class StockRepository {
  StockRepository(this._db);

  final Database _db;

  static Future<StockRepository> create() async {
    final db = await openAppDatabase();
    await db.execute('PRAGMA foreign_keys = ON');
    return StockRepository(db);
  }

  Future<DashboardSummary> getDashboardSummary() async {
    final rows = await _db.rawQuery('''
      SELECT
        COUNT(*) AS product_count,
        COALESCE(SUM(stock_quantity), 0) AS total_stock,
        COALESCE(SUM(CASE WHEN stock_quantity <= min_stock AND min_stock > 0 THEN 1 ELSE 0 END), 0)
          AS low_stock_count
      FROM products
      WHERE is_active = 1
    ''');
    final row = rows.first;
    return DashboardSummary(
      productCount: (row['product_count'] as num).toInt(),
      totalStock: (row['total_stock'] as num).toDouble(),
      lowStockCount: (row['low_stock_count'] as num).toInt(),
    );
  }

  Future<List<Product>> getProducts({String search = ''}) async {
    final cleaned = search.trim();
    final rows = cleaned.isEmpty
        ? await _db.query(
            'products',
            where: 'is_active = 1',
            orderBy: 'name COLLATE NOCASE',
          )
        : await _db.query(
            'products',
            where: 'is_active = 1 AND (name LIKE ? OR code LIKE ?)',
            whereArgs: ['%$cleaned%', '%$cleaned%'],
            orderBy: 'name COLLATE NOCASE',
          );
    return rows.map(Product.fromMap).toList();
  }

  Future<List<Product>> getLowStockProducts() async {
    final rows = await _db.query(
      'products',
      where: 'is_active = 1 AND min_stock > 0 AND stock_quantity <= min_stock',
      orderBy: 'stock_quantity ASC, name COLLATE NOCASE',
    );
    return rows.map(Product.fromMap).toList();
  }

  Future<Product?> getProductById(int id) async {
    final rows = await _db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Product.fromMap(rows.first);
  }

  Future<int> saveProduct({
    int? id,
    required String code,
    required String name,
    required String brand,
    required String materialGroup,
    required String shelfLocation,
    required String unit,
    required double salePrice,
    required double minStock,
  }) async {
    final cleanedCode = code.trim();
    final cleanedName = name.trim();
    final cleanedBrand = brand.trim();
    final cleanedMaterialGroup = materialGroup.trim();
    final cleanedShelfLocation = shelfLocation.trim();
    if (salePrice < 0 || salePrice > maxPriceValue) {
      throw StateError('Satis fiyati cok buyuk veya gecersiz.');
    }
    if (minStock < 0 || minStock > maxStockValue) {
      throw StateError('Minimum stok gecersiz.');
    }
    await _ensureUniqueProduct(
      id: id,
      code: cleanedCode,
      name: cleanedName,
    );

    final values = {
      'code': cleanedCode,
      'name': cleanedName,
      'brand': cleanedBrand,
      'material_group': cleanedMaterialGroup,
      'shelf_location': cleanedShelfLocation,
      'unit': unit.trim().isEmpty ? 'Adet' : unit.trim(),
      'sale_price': salePrice,
      'min_stock': minStock,
      'is_active': 1,
      if (id == null) 'stock_quantity': 0.0,
      if (id == null) 'created_at': DateTime.now().toIso8601String(),
    };

    if (id == null) {
      return _db.insert('products', values);
    }

    await _db.update(
      'products',
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
    return id;
  }

  Future<void> _ensureUniqueProduct({
    required int? id,
    required String code,
    required String name,
  }) async {
    final existingCode = await _db.query(
      'products',
      columns: ['id'],
      where: id == null
          ? 'LOWER(code) = LOWER(?) AND is_active = 1'
          : 'LOWER(code) = LOWER(?) AND is_active = 1 AND id != ?',
      whereArgs: id == null ? [code] : [code, id],
      limit: 1,
    );
    if (existingCode.isNotEmpty) {
      throw StateError('Ayni urun kodu zaten kayitli.');
    }

    final existingName = await _db.query(
      'products',
      columns: ['id'],
      where: id == null
          ? 'LOWER(name) = LOWER(?) AND is_active = 1'
          : 'LOWER(name) = LOWER(?) AND is_active = 1 AND id != ?',
      whereArgs: id == null ? [name] : [name, id],
      limit: 1,
    );
    if (existingName.isNotEmpty) {
      throw StateError('Ayni urun adi zaten kayitli.');
    }
  }

  Future<void> deleteProduct(int id) async {
    final count = await _db.update(
      'products',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    if (count == 0) {
      throw StateError('Urun bulunamadi.');
    }
  }

  Future<ProductPerformance> getProductPerformance(int productId) async {
    final purchasedRows = await _db.rawQuery(
      '''
      SELECT COALESCE(SUM(quantity), 0) AS total
      FROM stock_movements
      WHERE product_id = ? AND type = ?
      ''',
      [productId, MovementType.stockIn.dbValue],
    );
    final soldRows = await _db.rawQuery(
      '''
      SELECT COALESCE(SUM(quantity), 0) AS total
      FROM stock_movements
      WHERE product_id = ? AND type = ?
      ''',
      [productId, MovementType.sale.dbValue],
    );

    return ProductPerformance(
      totalPurchasedQuantity: (purchasedRows.first['total'] as num).toDouble(),
      totalSoldQuantity: (soldRows.first['total'] as num).toDouble(),
    );
  }

  Future<PendingPurchaseOrderInfo> getPendingPurchaseOrderInfo(
    int productId,
  ) async {
    final rows = await _db.rawQuery(
      '''
      SELECT
        COUNT(*) AS order_count,
        COALESCE(SUM(quantity), 0) AS total_quantity
      FROM purchase_orders
      WHERE product_id = ? AND status = ?
      ''',
      [productId, PurchaseOrderStatus.pending.dbValue],
    );
    final row = rows.first;
    return PendingPurchaseOrderInfo(
      orderCount: (row['order_count'] as num).toInt(),
      totalQuantity: (row['total_quantity'] as num).toDouble(),
    );
  }

  Future<List<Supplier>> getSuppliers() async {
    final rows = await _db.query(
      'suppliers',
      orderBy: 'name COLLATE NOCASE',
    );
    return rows.map(Supplier.fromMap).toList();
  }

  Future<List<ProductSupplierOffer>> getProductSuppliers(int productId) async {
    final rows = await _db.rawQuery(
      '''
      SELECT
        ps.*,
        s.name AS supplier_name
      FROM product_suppliers ps
      JOIN suppliers s ON s.id = ps.supplier_id
      WHERE ps.product_id = ?
      ORDER BY ps.priority ASC, ps.net_price ASC, s.name COLLATE NOCASE
      ''',
      [productId],
    );
    return rows.map(ProductSupplierOffer.fromMap).toList();
  }

  Future<void> replaceProductSuppliers({
    required int productId,
    required List<ProductSupplierDraft> drafts,
  }) async {
    await _db.transaction((txn) async {
      await txn.delete(
        'product_suppliers',
        where: 'product_id = ?',
        whereArgs: [productId],
      );

      for (final draft in drafts) {
        final supplierName = draft.supplierName.trim();
        if (supplierName.isEmpty) continue;
        if (draft.listPrice < 0 || draft.listPrice > maxPriceValue) {
          throw StateError('Tedarikci liste fiyati gecersiz.');
        }
        if (draft.discountPercent < 0 || draft.discountPercent > 100) {
          throw StateError('Tedarikci indirimi 0-100 arasi olmali.');
        }
        final supplierId = await _ensureSupplier(txn, supplierName);
        final now = DateTime.now().toIso8601String();
        await txn.insert('product_suppliers', {
          'product_id': productId,
          'supplier_id': supplierId,
          'list_price': draft.listPrice,
          'discount_percent': draft.discountPercent,
          'net_price': draft.netPrice,
          'is_original': draft.isOriginal ? 1 : 0,
          'priority': draft.priority,
          'note': draft.note.trim(),
          'created_at': now,
          'updated_at': now,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<SupplierSuggestion>> getSupplierSuggestions(Product product) async {
    final offers = await getProductSuppliers(product.id);
    if (offers.isEmpty) return const [];

    final bestProfitOfferId = offers
        .map((offer) => MapEntry(offer.id, product.salePrice - offer.netPrice))
        .reduce((best, current) => current.value > best.value ? current : best)
        .key;

    final suggestions = offers
        .map(
          (offer) => SupplierSuggestion(
            offerId: offer.id,
            productId: offer.productId,
            supplierId: offer.supplierId,
            supplierName: offer.supplierName,
            listPrice: offer.listPrice,
            discountPercent: offer.discountPercent,
            netPrice: offer.netPrice,
            salePrice: product.salePrice,
            profitAmount: product.salePrice - offer.netPrice,
            profitPercent: offer.netPrice <= 0
                ? 0
                : ((product.salePrice - offer.netPrice) / offer.netPrice) * 100,
            isBestProfit: offer.id == bestProfitOfferId,
            isDiscounted: offer.discountPercent > 0,
            isOriginal: offer.isOriginal,
          ),
        )
        .toList();

    suggestions.sort((left, right) {
      final leftScore =
          (left.isBestProfit ? 1000 : 0) +
          (left.isDiscounted ? 100 : 0) +
          (left.isOriginal ? 20 : 0) +
          left.profitAmount.round();
      final rightScore =
          (right.isBestProfit ? 1000 : 0) +
          (right.isDiscounted ? 100 : 0) +
          (right.isOriginal ? 20 : 0) +
          right.profitAmount.round();
      return rightScore.compareTo(leftScore);
    });

    return suggestions;
  }

  Future<int> createPurchaseOrder({
    required Product product,
    required double quantity,
    required double unitCost,
    required String supplierName,
    int? supplierId,
    int? offerId,
    double listPrice = 0,
    double discountPercent = 0,
    String note = '',
  }) async {
    if (quantity <= 0 || quantity > maxStockValue) {
      throw StateError('Siparis miktari gecersiz.');
    }
    if (unitCost < 0 || unitCost > maxPriceValue) {
      throw StateError('Alis fiyati gecersiz.');
    }
    if (discountPercent < 0 || discountPercent > 100) {
      throw StateError('Indirim 0-100 arasi olmali.');
    }

    return _db.transaction((txn) async {
      var resolvedSupplierId = supplierId;
      final cleanedSupplierName = supplierName.trim();
      if (resolvedSupplierId == null && cleanedSupplierName.isNotEmpty) {
        resolvedSupplierId = await _ensureSupplier(txn, cleanedSupplierName);
      }

      return txn.insert('purchase_orders', {
        'product_id': product.id,
        'product_code': product.code,
        'product_name': product.name,
        'supplier_id': resolvedSupplierId,
        'supplier_name': cleanedSupplierName,
        'product_supplier_offer_id': offerId,
        'list_price': listPrice,
        'discount_percent': discountPercent,
        'quantity': quantity,
        'unit_cost': unitCost,
        'status': PurchaseOrderStatus.pending.dbValue,
        'note': note.trim(),
        'ordered_at': DateTime.now().toIso8601String(),
      });
    });
  }

  Future<List<PurchaseOrder>> getPurchaseOrders() async {
    final rows = await _db.query(
      'purchase_orders',
      orderBy: 'ordered_at DESC, id DESC',
    );
    return rows.map(PurchaseOrder.fromMap).toList();
  }

  Future<void> receivePurchaseOrder(int orderId) async {
    await _db.transaction((txn) async {
      final orderRows = await txn.query(
        'purchase_orders',
        where: 'id = ?',
        whereArgs: [orderId],
        limit: 1,
      );
      if (orderRows.isEmpty) {
        throw StateError('Siparis bulunamadi.');
      }

      final order = PurchaseOrder.fromMap(orderRows.first);
      if (order.status == PurchaseOrderStatus.received) {
        throw StateError('Bu siparis zaten teslim alinmis.');
      }

      final productRows = await txn.query(
        'products',
        where: 'id = ?',
        whereArgs: [order.productId],
        limit: 1,
      );
      if (productRows.isEmpty) {
        throw StateError('Siparise ait urun bulunamadi.');
      }

      final product = Product.fromMap(productRows.first);
      final updateValues = _buildStockInUpdateValues(
        product: product,
        quantity: order.quantity,
        unitPrice: order.unitCost,
      );
      await txn.update(
        'products',
        updateValues,
        where: 'id = ?',
        whereArgs: [product.id],
      );
      await _insertStockMovement(
        txn: txn,
        productId: order.productId,
        type: MovementType.stockIn,
        quantity: order.quantity,
        unitPrice: order.unitCost,
        note:
            'Siparis teslim alindi${order.supplierName.isEmpty ? '' : ' - ${order.supplierName}'}',
      );

      await txn.update(
        'purchase_orders',
        {
          'status': PurchaseOrderStatus.received.dbValue,
          'received_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [orderId],
      );
    });
  }

  Future<List<AlternativeBrandStock>> getAlternativeBrandStocks(
    Product product,
  ) async {
    final group = product.materialGroup.trim();
    if (group.isEmpty) return const [];

    final rows = await _db.query(
      'products',
      columns: ['id', 'name', 'brand', 'stock_quantity'],
      where:
          'is_active = 1 AND id != ? AND LOWER(material_group) = LOWER(?) AND stock_quantity > 0',
      whereArgs: [product.id, group],
      orderBy: 'brand COLLATE NOCASE, name COLLATE NOCASE',
    );
    return rows.map(AlternativeBrandStock.fromMap).toList();
  }

  Future<List<SubstituteSuggestion>> getSubstituteSuggestions({
    required Product product,
    required double requestedQuantity,
  }) async {
    final group = product.materialGroup.trim();
    if (group.isEmpty) return const [];

    final rows = await _db.query(
      'products',
      where:
          'is_active = 1 AND id != ? AND LOWER(material_group) = LOWER(?) AND stock_quantity > 0',
      whereArgs: [product.id, group],
      orderBy: 'stock_quantity DESC, sale_price DESC',
    );

    if (rows.isEmpty) return const [];

    final mapped = rows.map(Product.fromMap).toList();
    final bestProfitId = mapped
        .map((candidate) => MapEntry(candidate.id, candidate.salePrice - candidate.averageCost))
        .reduce((best, current) => current.value > best.value ? current : best)
        .key;

    final nearestShelfId = _resolveNearestShelfId(
      originShelf: product.shelfLocation,
      candidates: mapped,
    );

    final suggestions = mapped
        .map(
          (candidate) => SubstituteSuggestion(
            productId: candidate.id,
            code: candidate.code,
            name: candidate.name,
            brand: candidate.brand,
            shelfLocation: candidate.shelfLocation,
            stockQuantity: candidate.stockQuantity,
            salePrice: candidate.salePrice,
            averageCost: candidate.averageCost,
            lastCost: candidate.lastCost,
            profitEstimate: candidate.salePrice - candidate.averageCost,
            canFulfill: candidate.stockQuantity >= requestedQuantity,
            isBestProfit: candidate.id == bestProfitId,
            isNearestShelf: candidate.id == nearestShelfId,
          ),
        )
        .toList();

    suggestions.sort((left, right) {
      final leftScore =
          (left.canFulfill ? 1000 : 0) +
          (left.isBestProfit ? 200 : 0) +
          (left.isNearestShelf ? 100 : 0) +
          left.stockQuantity.round();
      final rightScore =
          (right.canFulfill ? 1000 : 0) +
          (right.isBestProfit ? 200 : 0) +
          (right.isNearestShelf ? 100 : 0) +
          right.stockQuantity.round();
      return rightScore.compareTo(leftScore);
    });

    return suggestions;
  }

  int? _resolveNearestShelfId({
    required String originShelf,
    required List<Product> candidates,
  }) {
    if (candidates.isEmpty) return null;
    final normalizedOrigin = originShelf.trim().toUpperCase();
    if (normalizedOrigin.isEmpty) return candidates.first.id;

    int bestScore = -1;
    int? bestId;
    for (final candidate in candidates) {
      final score = _shelfSimilarityScore(
        normalizedOrigin,
        candidate.shelfLocation.trim().toUpperCase(),
      );
      if (score > bestScore) {
        bestScore = score;
        bestId = candidate.id;
      }
    }
    return bestId;
  }

  int _shelfSimilarityScore(String left, String right) {
    if (right.isEmpty) return 0;
    if (left == right) return 100;
    final leftPrefix = left.split('-').first;
    final rightPrefix = right.split('-').first;
    if (leftPrefix == rightPrefix) return 75;
    if (left[0] == right[0]) return 50;
    return 10;
  }

  Future<void> recordMovement({
    required int productId,
    required MovementType type,
    required double quantity,
    double unitPrice = 0,
    double? profitPercent,
    String note = '',
  }) async {
    if (quantity <= 0 || quantity > maxStockValue) {
      throw StateError('Miktar sifirdan buyuk olmali.');
    }
    if (unitPrice < 0 || unitPrice > maxPriceValue) {
      throw StateError('Fiyat gecersiz.');
    }
    if (profitPercent != null && (profitPercent < 0 || profitPercent > maxPriceValue)) {
      throw StateError('Kar yuzdesi gecersiz.');
    }

    await _db.transaction((txn) async {
      final rows = await txn.query(
        'products',
        where: 'id = ?',
        whereArgs: [productId],
        limit: 1,
      );
      if (rows.isEmpty) throw StateError('Urun bulunamadi.');

      final product = Product.fromMap(rows.first);
      final delta = type == MovementType.stockIn ? quantity : -quantity;
      final newStock = product.stockQuantity + delta;
      if (newStock < 0) {
        throw StateError('Yetersiz stok. Mevcut stok: ${product.stockQuantity}.');
      }

      final updateValues = <String, Object?>{
        'stock_quantity': newStock,
      };
      if (type == MovementType.stockIn) {
        updateValues.addAll(
          _buildStockInUpdateValues(
            product: product,
            quantity: quantity,
            unitPrice: unitPrice,
          ),
        );
        if (profitPercent != null) {
          final calculatedSalePrice = unitPrice * (1 + (profitPercent / 100));
          if (calculatedSalePrice > maxPriceValue) {
            throw StateError('Hesaplanan satis fiyati cok buyuk.');
          }
          updateValues['sale_price'] = calculatedSalePrice;
        }
      }

      await txn.update(
        'products',
        updateValues,
        where: 'id = ?',
        whereArgs: [productId],
      );

      await _insertStockMovement(
        txn: txn,
        productId: productId,
        type: type,
        quantity: quantity,
        unitPrice: unitPrice,
        note: note,
      );
    });
  }

  Future<List<StockMovement>> getMovements() async {
    final rows = await _db.rawQuery('''
      SELECT
        m.id,
        m.product_id,
        p.code AS product_code,
        p.name AS product_name,
        m.type,
        m.quantity,
        m.unit_price,
        m.note,
        m.created_at
      FROM stock_movements m
      JOIN products p ON p.id = m.product_id
      ORDER BY m.created_at DESC, m.id DESC
    ''');
    return rows.map(StockMovement.fromMap).toList();
  }

  Future<SaleRecord> createSale({
    required String customerName,
    required String customerPhone,
    required List<SaleDraftItem> items,
  }) async {
    if (items.isEmpty) {
      throw StateError('Satis icin en az bir urun eklemelisin.');
    }
    for (final item in items) {
      if (item.quantity <= 0 || item.quantity > maxStockValue) {
        throw StateError('Satis miktari gecersiz.');
      }
      if (item.unitPrice < 0 || item.unitPrice > maxPriceValue) {
        throw StateError('Satis fiyati gecersiz.');
      }
    }

    final invoiceNo = _generateInvoiceNo();
    final createdAt = DateTime.now();
    final totalAmount = items.fold<double>(
      0,
      (sum, item) => sum + item.lineTotal,
    );

    final saleId = await _db.transaction<int>((txn) async {
      for (final item in items) {
        final rows = await txn.query(
          'products',
          where: 'id = ?',
          whereArgs: [item.product.id],
          limit: 1,
        );
        if (rows.isEmpty) throw StateError('Urun bulunamadi.');

        final product = Product.fromMap(rows.first);
        if (product.stockQuantity < item.quantity) {
          throw StateError(
            '${product.name} icin yeterli stok yok. Mevcut: ${product.stockQuantity}',
          );
        }
      }

      final saleId = await txn.insert('sales', {
        'invoice_no': invoiceNo,
        'customer_name': customerName.trim(),
        'customer_phone': customerPhone.trim(),
        'total_amount': totalAmount,
        'created_at': createdAt.toIso8601String(),
      });

      for (final item in items) {
        await txn.insert('sale_items', {
          'sale_id': saleId,
          'product_id': item.product.id,
          'product_code': item.product.code,
          'product_name': item.product.name,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'line_total': item.lineTotal,
        });

        await txn.update(
          'products',
          {'stock_quantity': item.product.stockQuantity - item.quantity},
          where: 'id = ?',
          whereArgs: [item.product.id],
        );

        await txn.insert('stock_movements', {
          'product_id': item.product.id,
          'type': MovementType.sale.dbValue,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'note': 'Satis - $invoiceNo',
          'created_at': createdAt.toIso8601String(),
          'sale_id': saleId,
        });
      }

      return saleId;
    });

    return SaleRecord(
      id: saleId,
      invoiceNo: invoiceNo,
      customerName: customerName.trim(),
      customerPhone: customerPhone.trim(),
      totalAmount: totalAmount,
      createdAt: createdAt,
      pdfPath: null,
      itemCount: items.length,
    );
  }

  Future<List<SaleRecord>> getSales() async {
    final rows = await _db.rawQuery('''
      SELECT
        s.*,
        (SELECT COUNT(*) FROM sale_items si WHERE si.sale_id = s.id) AS item_count
      FROM sales s
      ORDER BY s.created_at DESC, s.id DESC
    ''');
    return rows.map(SaleRecord.fromMap).toList();
  }

  Future<List<SaleLine>> getSaleItems(int saleId) async {
    final rows = await _db.query(
      'sale_items',
      where: 'sale_id = ?',
      whereArgs: [saleId],
      orderBy: 'id ASC',
    );
    return rows.map(SaleLine.fromMap).toList();
  }

  Future<void> updateSalePdfPath(int saleId, String pdfPath) async {
    await _db.update(
      'sales',
      {'pdf_path': pdfPath},
      where: 'id = ?',
      whereArgs: [saleId],
    );
  }

  Future<ImportSummary> importProducts(
    List<Map<String, String>> rows,
  ) async {
    var imported = 0;
    var skipped = 0;
    final messages = <String>[];

    for (var index = 0; index < rows.length; index++) {
      final row = rows[index];
      try {
        final code = (row['code'] ?? '').trim();
        final name = (row['name'] ?? '').trim();
        if (code.isEmpty || name.isEmpty) {
          skipped++;
          messages.add('Satir ${index + 2}: kod veya urun adi bos.');
          continue;
        }

        final productId = await saveProduct(
          code: code,
          name: name,
          brand: (row['brand'] ?? '').trim(),
          materialGroup: (row['material_group'] ?? '').trim(),
          shelfLocation: (row['shelf_location'] ?? '').trim(),
          unit: (row['unit'] ?? 'Adet').trim(),
          salePrice: _parseOptionalNumber(row['sale_price']),
          minStock: _parseOptionalNumber(row['min_stock']),
        );

        final initialStock = _parseOptionalNumber(row['initial_stock']);
        final lastCost = _parseOptionalNumber(row['last_cost']);
        if (initialStock > 0) {
          await recordMovement(
            productId: productId,
            type: MovementType.stockIn,
            quantity: initialStock,
            unitPrice: lastCost,
            note: 'Toplu ice aktarma',
          );
        }

        imported++;
      } catch (error) {
        skipped++;
        messages.add('Satir ${index + 2}: $error');
      }
    }

    return ImportSummary(
      importedCount: imported,
      skippedCount: skipped,
      messages: messages,
    );
  }

  double _parseOptionalNumber(String? raw) {
    final text = (raw ?? '').trim();
    if (text.isEmpty) return 0;
    return parseInputNumber(text);
  }

  Future<int> _ensureSupplier(Transaction txn, String name) async {
    final rows = await txn.query(
      'suppliers',
      columns: ['id'],
      where: 'LOWER(name) = LOWER(?)',
      whereArgs: [name],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      return (rows.first['id'] as num).toInt();
    }

    return txn.insert('suppliers', {
      'name': name.trim(),
      'phone': '',
      'note': '',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Map<String, Object?> _buildStockInUpdateValues({
    required Product product,
    required double quantity,
    required double unitPrice,
  }) {
    final newStock = product.stockQuantity + quantity;
    final weightedTotal =
        (product.stockQuantity * product.averageCost) + (quantity * unitPrice);
    final averageCost = newStock > 0 ? weightedTotal / newStock : unitPrice;

    return <String, Object?>{
      'stock_quantity': newStock,
      'average_cost': averageCost,
      'last_cost': unitPrice,
    };
  }

  Future<void> _insertStockMovement({
    required Transaction txn,
    required int productId,
    required MovementType type,
    required double quantity,
    required double unitPrice,
    required String note,
    int? saleId,
    DateTime? createdAt,
  }) async {
    await txn.insert('stock_movements', {
      'product_id': productId,
      'type': type.dbValue,
      'quantity': quantity,
      'unit_price': unitPrice,
      'note': note.trim(),
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
      ...?saleId == null ? null : {'sale_id': saleId},
    });
  }

  String _generateInvoiceNo() {
    final now = DateTime.now();
    final compact = [
      now.year.toString().padLeft(4, '0'),
      now.month.toString().padLeft(2, '0'),
      now.day.toString().padLeft(2, '0'),
      now.hour.toString().padLeft(2, '0'),
      now.minute.toString().padLeft(2, '0'),
      now.second.toString().padLeft(2, '0'),
    ].join();
    return 'IRS-$compact';
  }
}
