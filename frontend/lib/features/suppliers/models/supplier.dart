class Supplier {
  final int id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;

  Supplier({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'] as int,
      name: json['name'] as String,
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
    };
  }
}
