class MedicineBatch {
  final int id;
  final int medicineId;
  final String batchNumber;
  final String expiryDate;
  final int quantity;
  final double purchasePrice;
  final String? medicineName;

  MedicineBatch({
    required this.id,
    required this.medicineId,
    required this.batchNumber,
    required this.expiryDate,
    required this.quantity,
    required this.purchasePrice,
    this.medicineName,
  });

  factory MedicineBatch.fromJson(Map<String, dynamic> json) {
    return MedicineBatch(
      id: json['id'] as int,
      medicineId: json['medicineId'] as int,
      batchNumber: json['batchNumber'] as String,
      expiryDate: json['expiryDate'] as String,
      quantity: (json['quantity'] as num).toInt(),
      purchasePrice: (json['purchasePrice'] as num).toDouble(),
      medicineName: json['medicineName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medicineId': medicineId,
      'batchNumber': batchNumber,
      'expiryDate': expiryDate,
      'quantity': quantity,
      'purchasePrice': purchasePrice,
    };
  }

  bool get isExpired {
    try {
      final expiry = DateTime.parse(expiryDate);
      return expiry.isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  bool get isExpiringSoon {
    try {
      final expiry = DateTime.parse(expiryDate);
      final daysDifference = expiry.difference(DateTime.now()).inDays;
      return daysDifference >= 0 && daysDifference <= 30; // Within 30 days
    } catch (_) {
      return false;
    }
  }
}
