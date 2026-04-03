import 'package:cborn_stok/data/stock_repository.dart';
import 'package:cborn_stok/models/app_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  group('Supplier ranking', () {
    late Database db;
    late StockRepository repo;

    setUp(() async {
      db = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE products (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                code TEXT NOT NULL,
                name TEXT NOT NULL,
                brand TEXT NOT NULL DEFAULT '',
                material_group TEXT NOT NULL DEFAULT '',
                shelf_location TEXT NOT NULL DEFAULT '',
                image_path TEXT NOT NULL DEFAULT '',
                unit TEXT NOT NULL,
                sale_price REAL NOT NULL DEFAULT 0,
                stock_quantity REAL NOT NULL DEFAULT 0,
                min_stock REAL NOT NULL DEFAULT 0,
                average_cost REAL NOT NULL DEFAULT 0,
                last_cost REAL NOT NULL DEFAULT 0,
                is_active INTEGER NOT NULL DEFAULT 1,
                created_at TEXT NOT NULL
              )
            ''');
            await db.execute('''
              CREATE TABLE suppliers (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL UNIQUE,
                phone TEXT NOT NULL DEFAULT '',
                note TEXT NOT NULL DEFAULT '',
                created_at TEXT NOT NULL
              )
            ''');
            await db.execute('''
              CREATE TABLE product_suppliers (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                product_id INTEGER NOT NULL,
                supplier_id INTEGER NOT NULL,
                list_price REAL NOT NULL DEFAULT 0,
                discount_percent REAL NOT NULL DEFAULT 0,
                net_price REAL NOT NULL DEFAULT 0,
                is_original INTEGER NOT NULL DEFAULT 0,
                priority INTEGER NOT NULL DEFAULT 0,
                note TEXT NOT NULL DEFAULT '',
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
              )
            ''');
            await db.execute('''
              CREATE TABLE purchase_orders (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                product_id INTEGER NOT NULL,
                product_code TEXT NOT NULL,
                product_name TEXT NOT NULL,
                supplier_id INTEGER,
                supplier_name TEXT,
                product_supplier_offer_id INTEGER,
                list_price REAL NOT NULL DEFAULT 0,
                discount_percent REAL NOT NULL DEFAULT 0,
                quantity REAL NOT NULL,
                unit_cost REAL NOT NULL DEFAULT 0,
                status TEXT NOT NULL,
                note TEXT,
                ordered_at TEXT NOT NULL,
                received_at TEXT
              )
            ''');
          },
        ),
      );
      repo = StockRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('returns most profitable supplier first', () async {
      final productId = await repo.saveProduct(
        code: 'P-100',
        name: 'Test Filtre',
        brand: 'Test',
        materialGroup: 'Filtre',
        shelfLocation: 'A-01',
        imagePath: '',
        unit: 'Adet',
        salePrice: 300,
        minStock: 2,
      );

      await repo.replaceProductSuppliers(
        productId: productId,
        drafts: const [
          ProductSupplierDraft(
            supplierName: 'Tedarikci A',
            listPrice: 220,
            discountPercent: 0,
            isOriginal: true,
            priority: 0,
            note: '',
          ),
          ProductSupplierDraft(
            supplierName: 'Tedarikci B',
            listPrice: 260,
            discountPercent: 30,
            isOriginal: false,
            priority: 1,
            note: '',
          ),
        ],
      );

      final product = (await repo.getProductById(productId))!;
      final suggestions = await repo.getSupplierSuggestions(product);

      expect(suggestions, hasLength(2));
      expect(suggestions.first.supplierName, 'Tedarikci B');
      expect(suggestions.first.isBestProfit, isTrue);
      expect(suggestions.first.netPrice, 182);
    });

    test('stores selected supplier pricing on purchase order', () async {
      final productId = await repo.saveProduct(
        code: 'P-200',
        name: 'Test Balata',
        brand: 'Test',
        materialGroup: 'Balata',
        shelfLocation: 'B-01',
        imagePath: '',
        unit: 'Set',
        salePrice: 900,
        minStock: 3,
      );

      await repo.replaceProductSuppliers(
        productId: productId,
        drafts: const [
          ProductSupplierDraft(
            supplierName: 'Tedarikci Karli',
            listPrice: 700,
            discountPercent: 10,
            isOriginal: false,
            priority: 0,
            note: '',
          ),
        ],
      );

      final product = (await repo.getProductById(productId))!;
      final suggestion = (await repo.getSupplierSuggestions(product)).first;

      await repo.createPurchaseOrder(
        product: product,
        quantity: 5,
        unitCost: suggestion.netPrice,
        supplierName: suggestion.supplierName,
        supplierId: suggestion.supplierId,
        offerId: suggestion.offerId,
        listPrice: suggestion.listPrice,
        discountPercent: suggestion.discountPercent,
      );

      final orders = await repo.getPurchaseOrders();
      expect(orders, hasLength(1));
      expect(orders.first.supplierName, 'Tedarikci Karli');
      expect(orders.first.listPrice, 700);
      expect(orders.first.discountPercent, 10);
      expect(orders.first.unitCost, 630);
    });
  });
}
