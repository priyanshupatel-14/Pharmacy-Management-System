class SaleItemRequest {
  final int batchId;
  final int quantity;

  SaleItemRequest({
    required this.batchId,
    required this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'batchId': batchId,
      'quantity': quantity,
    };
  }
}

class SaleRequest {
  final int userId;
  final List<SaleItemRequest> items;

  SaleRequest({
    required this.userId,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }
}
