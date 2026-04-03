import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<Database> openAppDatabase() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final dir = await getApplicationDocumentsDirectory();
  final dbPath = p.join(dir.path, 'cborn_stok_simple.db');

  return openDatabase(
    dbPath,
    version: 5,
    onConfigure: (db) async {
      await db.execute('PRAGMA foreign_keys = ON');
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 2) {
        await db.execute(
          'ALTER TABLE products ADD COLUMN is_active INTEGER NOT NULL DEFAULT 1',
        );
      }
      if (oldVersion < 3) {
        await db.execute(
          "ALTER TABLE products ADD COLUMN brand TEXT NOT NULL DEFAULT ''",
        );
        await db.execute(
          "ALTER TABLE products ADD COLUMN material_group TEXT NOT NULL DEFAULT ''",
        );
        await db.execute(
          "ALTER TABLE products ADD COLUMN shelf_location TEXT NOT NULL DEFAULT ''",
        );
        await db.execute(
          'ALTER TABLE products ADD COLUMN average_cost REAL NOT NULL DEFAULT 0',
        );
        await db.execute(
          'ALTER TABLE products ADD COLUMN last_cost REAL NOT NULL DEFAULT 0',
        );
      }
      if (oldVersion < 4) {
        await db.execute('''
          CREATE TABLE purchase_orders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            product_id INTEGER NOT NULL,
            product_code TEXT NOT NULL,
            product_name TEXT NOT NULL,
            supplier_name TEXT,
            quantity REAL NOT NULL,
            unit_cost REAL NOT NULL DEFAULT 0,
            status TEXT NOT NULL,
            note TEXT,
            ordered_at TEXT NOT NULL,
            received_at TEXT,
            FOREIGN KEY (product_id) REFERENCES products (id)
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_purchase_orders_status ON purchase_orders(status)',
        );
      }
      if (oldVersion < 5) {
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
            updated_at TEXT NOT NULL,
            FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE,
            FOREIGN KEY (supplier_id) REFERENCES suppliers (id) ON DELETE CASCADE
          )
        ''');
        await db.execute(
          'CREATE UNIQUE INDEX idx_product_suppliers_unique ON product_suppliers(product_id, supplier_id)',
        );
        await db.execute(
          'CREATE INDEX idx_product_suppliers_product ON product_suppliers(product_id)',
        );
        await db.execute(
          'ALTER TABLE purchase_orders ADD COLUMN supplier_id INTEGER',
        );
        await db.execute(
          'ALTER TABLE purchase_orders ADD COLUMN product_supplier_offer_id INTEGER',
        );
        await db.execute(
          'ALTER TABLE purchase_orders ADD COLUMN list_price REAL NOT NULL DEFAULT 0',
        );
        await db.execute(
          'ALTER TABLE purchase_orders ADD COLUMN discount_percent REAL NOT NULL DEFAULT 0',
        );
      }
    },
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE products (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          code TEXT NOT NULL UNIQUE,
          name TEXT NOT NULL,
          brand TEXT NOT NULL DEFAULT '',
          material_group TEXT NOT NULL DEFAULT '',
          shelf_location TEXT NOT NULL DEFAULT '',
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
        CREATE TABLE sales (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          invoice_no TEXT NOT NULL UNIQUE,
          customer_name TEXT,
          customer_phone TEXT,
          total_amount REAL NOT NULL,
          created_at TEXT NOT NULL,
          pdf_path TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE sale_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sale_id INTEGER NOT NULL,
          product_id INTEGER NOT NULL,
          product_code TEXT NOT NULL,
          product_name TEXT NOT NULL,
          quantity REAL NOT NULL,
          unit_price REAL NOT NULL,
          line_total REAL NOT NULL,
          FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE,
          FOREIGN KEY (product_id) REFERENCES products (id)
        )
      ''');

      await db.execute('''
        CREATE TABLE stock_movements (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          product_id INTEGER NOT NULL,
          type TEXT NOT NULL,
          quantity REAL NOT NULL,
          unit_price REAL NOT NULL DEFAULT 0,
          note TEXT,
          created_at TEXT NOT NULL,
          sale_id INTEGER,
          FOREIGN KEY (product_id) REFERENCES products (id),
          FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE SET NULL
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
          received_at TEXT,
          FOREIGN KEY (product_id) REFERENCES products (id),
          FOREIGN KEY (supplier_id) REFERENCES suppliers (id) ON DELETE SET NULL,
          FOREIGN KEY (product_supplier_offer_id) REFERENCES product_suppliers (id) ON DELETE SET NULL
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
          updated_at TEXT NOT NULL,
          FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE,
          FOREIGN KEY (supplier_id) REFERENCES suppliers (id) ON DELETE CASCADE
        )
      ''');

      await db.execute(
        'CREATE INDEX idx_stock_movements_product ON stock_movements(product_id)',
      );
      await db.execute(
        'CREATE INDEX idx_sale_items_sale ON sale_items(sale_id)',
      );
      await db.execute(
        'CREATE INDEX idx_purchase_orders_status ON purchase_orders(status)',
      );
      await db.execute(
        'CREATE UNIQUE INDEX idx_product_suppliers_unique ON product_suppliers(product_id, supplier_id)',
      );
      await db.execute(
        'CREATE INDEX idx_product_suppliers_product ON product_suppliers(product_id)',
      );
    },
  );
}
