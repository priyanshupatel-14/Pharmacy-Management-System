import '../../batches/models/medicine_batch.dart';

class StockInfo {
  final int medicineId;
  final String medicineName;
  final String category;
  final int totalStock;
  final List<MedicineBatch> batches;

  StockInfo({
    required this.medicineId,
    required this.medicineName,
    required this.category,
    required this.totalStock,
    required this.batches,
  });

  factory StockInfo.fromJson(Map<String, dynamic> json) {
    return StockInfo(
      medicineId: json['medicineId'] as int,
      medicineName: json['medicineName'] as String,
      category: json['category'] as String,
      totalStock: (json['totalStock'] as num).toInt(),
      batches: (json['batches'] as List?)
              ?.map((e) => MedicineBatch.fromJson(e))
              .toList() ??
          [],
    );
  }
}
