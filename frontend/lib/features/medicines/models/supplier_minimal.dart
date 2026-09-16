class SupplierMinimal {
  final int id;
  final String name;

  SupplierMinimal({
    required this.id,
    required this.name,
  });

  factory SupplierMinimal.fromJson(Map<String, dynamic> json) {
    return SupplierMinimal(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}
