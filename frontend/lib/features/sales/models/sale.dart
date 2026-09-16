class SaleItem {
  final int id;
  final int saleId;
  final int batchId;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final String? medicineName;
  final String? batchNumber;

  SaleItem({
    required this.id,
    required this.saleId,
    required this.batchId,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.medicineName,
    this.batchNumber,
  });

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      id: json['id'] as int,
      saleId: json['saleId'] as int,
      batchId: json['batchId'] as int,
      quantity: (json['quantity'] as num).toInt(),
      unitPrice: (json['unitPrice'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
      medicineName: json['medicineName'],
      batchNumber: json['batchNumber'],
    );
  }
}

class Sale {
  final int id;
  final int userId;
  final double totalAmount;
  final String saleDate;
  final String? userName;
  final List<SaleItem>? items;

  Sale({
    required this.id,
    required this.userId,
    required this.totalAmount,
    required this.saleDate,
    this.userName,
    this.items,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id'] as int,
      userId: json['userId'] as int,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      saleDate: json['saleDate'] as String,
      userName: json['userName'],
      items: (json['items'] as List?)
          ?.map((e) => SaleItem.fromJson(e))
          .toList(),
    );
  }
}
