import 'package:flutter/material.dart';

enum MovementType {
  stockIn('IN', 'Stok Girisi', Colors.green),
  stockOut('OUT', 'Stok Cikisi', Colors.orange),
  sale('SALE', 'Satis', Colors.red);

  const MovementType(this.dbValue, this.label, this.color);

  final String dbValue;
  final String label;
  final Color color;

  static MovementType fromDb(String value) {
    return MovementType.values.firstWhere(
      (type) => type.dbValue == value,
      orElse: () => MovementType.stockIn,
    );
  }
}

enum PurchaseOrderStatus {
  pending('PENDING', 'Beklemede', Colors.orange),
  received('RECEIVED', 'Teslim Alindi', Colors.green);

  const PurchaseOrderStatus(this.dbValue, this.label, this.color);

  final String dbValue;
  final String label;
  final Color color;

  static PurchaseOrderStatus fromDb(String value) {
    return PurchaseOrderStatus.values.firstWhere(
      (status) => status.dbValue == value,
      orElse: () => PurchaseOrderStatus.pending,
    );
  }
}

class Supplier {
  const Supplier({
    required this.id,
    required this.name,
    required this.phone,
    required this.note,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String phone;
  final String note;
  final DateTime createdAt;

  factory Supplier.fromMap(Map<String, Object?> map) {
    return Supplier(
      id: map['id'] as int,
      name: map['name'] as String,
      phone: (map['phone'] as String?) ?? '',
      note: (map['note'] as String?) ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class Product {
  const Product({
    required this.id,
    required this.code,
    required this.name,
    required this.brand,
    required this.materialGroup,
    required this.shelfLocation,
    required this.unit,
    required this.salePrice,
    required this.stockQuantity,
    required this.minStock,
    required this.averageCost,
    required this.lastCost,
    required this.createdAt,
  });

  final int id;
  final String code;
  final String name;
  final String brand;
  final String materialGroup;
  final String shelfLocation;
  final String unit;
  final double salePrice;
  final double stockQuantity;
  final double minStock;
  final double averageCost;
  final double lastCost;
  final DateTime createdAt;

  double get profitMarginPercent {
    if (lastCost <= 0) return 0;
    return ((salePrice - lastCost) / lastCost) * 100;
  }

  factory Product.fromMap(Map<String, Object?> map) {
    return Product(
      id: map['id'] as int,
      code: map['code'] as String,
      name: map['name'] as String,
      brand: (map['brand'] as String?) ?? '',
      materialGroup: (map['material_group'] as String?) ?? '',
      shelfLocation: (map['shelf_location'] as String?) ?? '',
      unit: map['unit'] as String,
      salePrice: (map['sale_price'] as num).toDouble(),
      stockQuantity: (map['stock_quantity'] as num).toDouble(),
      minStock: (map['min_stock'] as num).toDouble(),
      averageCost: ((map['average_cost'] as num?) ?? 0).toDouble(),
      lastCost: ((map['last_cost'] as num?) ?? 0).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class ProductPerformance {
  const ProductPerformance({
    required this.totalPurchasedQuantity,
    required this.totalSoldQuantity,
  });

  final double totalPurchasedQuantity;
  final double totalSoldQuantity;
}

class PendingPurchaseOrderInfo {
  const PendingPurchaseOrderInfo({
    required this.orderCount,
    required this.totalQuantity,
  });

  final int orderCount;
  final double totalQuantity;
}

class ProductSupplierOffer {
  const ProductSupplierOffer({
    required this.id,
    required this.productId,
    required this.supplierId,
    required this.supplierName,
    required this.listPrice,
    required this.discountPercent,
    required this.netPrice,
    required this.isOriginal,
    required this.priority,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int productId;
  final int supplierId;
  final String supplierName;
  final double listPrice;
  final double discountPercent;
  final double netPrice;
  final bool isOriginal;
  final int priority;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ProductSupplierOffer.fromMap(Map<String, Object?> map) {
    return ProductSupplierOffer(
      id: map['id'] as int,
      productId: map['product_id'] as int,
      supplierId: map['supplier_id'] as int,
      supplierName: map['supplier_name'] as String,
      listPrice: (map['list_price'] as num).toDouble(),
      discountPercent: (map['discount_percent'] as num).toDouble(),
      netPrice: (map['net_price'] as num).toDouble(),
      isOriginal: ((map['is_original'] as num?) ?? 0).toInt() == 1,
      priority: ((map['priority'] as num?) ?? 0).toInt(),
      note: (map['note'] as String?) ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

class ProductSupplierDraft {
  const ProductSupplierDraft({
    required this.supplierName,
    required this.listPrice,
    required this.discountPercent,
    required this.isOriginal,
    required this.priority,
    required this.note,
  });

  final String supplierName;
  final double listPrice;
  final double discountPercent;
  final bool isOriginal;
  final int priority;
  final String note;

  double get netPrice => listPrice * (1 - (discountPercent / 100));
}

class SupplierSuggestion {
  const SupplierSuggestion({
    required this.offerId,
    required this.productId,
    required this.supplierId,
    required this.supplierName,
    required this.listPrice,
    required this.discountPercent,
    required this.netPrice,
    required this.salePrice,
    required this.profitAmount,
    required this.profitPercent,
    required this.isBestProfit,
    required this.isDiscounted,
    required this.isOriginal,
  });

  final int offerId;
  final int productId;
  final int supplierId;
  final String supplierName;
  final double listPrice;
  final double discountPercent;
  final double netPrice;
  final double salePrice;
  final double profitAmount;
  final double profitPercent;
  final bool isBestProfit;
  final bool isDiscounted;
  final bool isOriginal;
}

class PurchaseOrder {
  const PurchaseOrder({
    required this.id,
    required this.productId,
    required this.productCode,
    required this.productName,
    required this.supplierId,
    required this.supplierName,
    required this.offerId,
    required this.listPrice,
    required this.discountPercent,
    required this.quantity,
    required this.unitCost,
    required this.status,
    required this.note,
    required this.orderedAt,
    required this.receivedAt,
  });

  final int id;
  final int productId;
  final String productCode;
  final String productName;
  final int? supplierId;
  final String supplierName;
  final int? offerId;
  final double listPrice;
  final double discountPercent;
  final double quantity;
  final double unitCost;
  final PurchaseOrderStatus status;
  final String note;
  final DateTime orderedAt;
  final DateTime? receivedAt;

  factory PurchaseOrder.fromMap(Map<String, Object?> map) {
    return PurchaseOrder(
      id: map['id'] as int,
      productId: map['product_id'] as int,
      productCode: map['product_code'] as String,
      productName: map['product_name'] as String,
      supplierId: (map['supplier_id'] as num?)?.toInt(),
      supplierName: (map['supplier_name'] as String?) ?? '',
      offerId: (map['product_supplier_offer_id'] as num?)?.toInt(),
      listPrice: ((map['list_price'] as num?) ?? 0).toDouble(),
      discountPercent: ((map['discount_percent'] as num?) ?? 0).toDouble(),
      quantity: (map['quantity'] as num).toDouble(),
      unitCost: (map['unit_cost'] as num).toDouble(),
      status: PurchaseOrderStatus.fromDb(map['status'] as String),
      note: (map['note'] as String?) ?? '',
      orderedAt: DateTime.parse(map['ordered_at'] as String),
      receivedAt: map['received_at'] == null
          ? null
          : DateTime.parse(map['received_at'] as String),
    );
  }
}

class AlternativeBrandStock {
  const AlternativeBrandStock({
    required this.productId,
    required this.brand,
    required this.productName,
    required this.stockQuantity,
  });

  final int productId;
  final String brand;
  final String productName;
  final double stockQuantity;

  factory AlternativeBrandStock.fromMap(Map<String, Object?> map) {
    return AlternativeBrandStock(
      productId: map['id'] as int,
      brand: (map['brand'] as String?) ?? '',
      productName: map['name'] as String,
      stockQuantity: (map['stock_quantity'] as num).toDouble(),
    );
  }
}

class SubstituteSuggestion {
  const SubstituteSuggestion({
    required this.productId,
    required this.code,
    required this.name,
    required this.brand,
    required this.shelfLocation,
    required this.stockQuantity,
    required this.salePrice,
    required this.averageCost,
    required this.lastCost,
    required this.profitEstimate,
    required this.canFulfill,
    required this.isBestProfit,
    required this.isNearestShelf,
  });

  final int productId;
  final String code;
  final String name;
  final String brand;
  final String shelfLocation;
  final double stockQuantity;
  final double salePrice;
  final double averageCost;
  final double lastCost;
  final double profitEstimate;
  final bool canFulfill;
  final bool isBestProfit;
  final bool isNearestShelf;
}

class ImportSummary {
  const ImportSummary({
    required this.importedCount,
    required this.skippedCount,
    required this.messages,
  });

  final int importedCount;
  final int skippedCount;
  final List<String> messages;
}

class DashboardSummary {
  const DashboardSummary({
    required this.productCount,
    required this.totalStock,
    required this.lowStockCount,
  });

  final int productCount;
  final double totalStock;
  final int lowStockCount;
}

class StockMovement {
  const StockMovement({
    required this.id,
    required this.productId,
    required this.productCode,
    required this.productName,
    required this.type,
    required this.quantity,
    required this.unitPrice,
    required this.note,
    required this.createdAt,
  });

  final int id;
  final int productId;
  final String productCode;
  final String productName;
  final MovementType type;
  final double quantity;
  final double unitPrice;
  final String note;
  final DateTime createdAt;

  factory StockMovement.fromMap(Map<String, Object?> map) {
    return StockMovement(
      id: map['id'] as int,
      productId: map['product_id'] as int,
      productCode: map['product_code'] as String,
      productName: map['product_name'] as String,
      type: MovementType.fromDb(map['type'] as String),
      quantity: (map['quantity'] as num).toDouble(),
      unitPrice: (map['unit_price'] as num).toDouble(),
      note: (map['note'] as String?) ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class SaleRecord {
  const SaleRecord({
    required this.id,
    required this.invoiceNo,
    required this.customerName,
    required this.customerPhone,
    required this.totalAmount,
    required this.createdAt,
    required this.pdfPath,
    required this.itemCount,
  });

  final int id;
  final String invoiceNo;
  final String customerName;
  final String customerPhone;
  final double totalAmount;
  final DateTime createdAt;
  final String? pdfPath;
  final int itemCount;

  factory SaleRecord.fromMap(Map<String, Object?> map) {
    return SaleRecord(
      id: map['id'] as int,
      invoiceNo: map['invoice_no'] as String,
      customerName: (map['customer_name'] as String?) ?? '',
      customerPhone: (map['customer_phone'] as String?) ?? '',
      totalAmount: (map['total_amount'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
      pdfPath: map['pdf_path'] as String?,
      itemCount: ((map['item_count'] as num?) ?? 0).toInt(),
    );
  }
}

class SaleLine {
  const SaleLine({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.productName,
    required this.productCode,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  final int id;
  final int saleId;
  final int productId;
  final String productName;
  final String productCode;
  final double quantity;
  final double unitPrice;
  final double lineTotal;

  factory SaleLine.fromMap(Map<String, Object?> map) {
    return SaleLine(
      id: map['id'] as int,
      saleId: map['sale_id'] as int,
      productId: map['product_id'] as int,
      productName: map['product_name'] as String,
      productCode: map['product_code'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unitPrice: (map['unit_price'] as num).toDouble(),
      lineTotal: (map['line_total'] as num).toDouble(),
    );
  }
}

class SaleDraftItem {
  const SaleDraftItem({
    required this.product,
    required this.quantity,
    required this.unitPrice,
  });

  final Product product;
  final double quantity;
  final double unitPrice;

  double get lineTotal => quantity * unitPrice;
}
