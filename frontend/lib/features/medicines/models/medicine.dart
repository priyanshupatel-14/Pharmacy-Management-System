class Medicine {
  final int id;
  final String name;
  final String category;
  final String? manufacturer;
  final double unitPrice;
  final int? supplierId;
  final String? supplierName;

  Medicine({
    required this.id,
    required this.name,
    required this.category,
    this.manufacturer,
    required this.unitPrice,
    this.supplierId,
    this.supplierName,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'] as int,
      name: json['name'] as String,
      category: json['category'] ?? '',
      manufacturer: json['manufacturer'],
      unitPrice: (json['unitPrice'] as num).toDouble(),
      supplierId: json['supplierId'] as int?,
      supplierName: json['supplierName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'manufacturer': manufacturer,
      'unitPrice': unitPrice,
      'supplierId': supplierId,
    };
  }
}
