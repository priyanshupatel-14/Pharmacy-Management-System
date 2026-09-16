import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/stock_info.dart';

class StockProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<StockInfo> _stocks = [];
  List<StockInfo> get stocks => _stocks;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _showLowStockOnly = false;
  bool get showLowStockOnly => _showLowStockOnly;

  void toggleLowStockFilter(bool value) {
    _showLowStockOnly = value;
    fetchStock();
  }

  Future<void> fetchStock() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final endpoint = _showLowStockOnly ? '/stock/low?threshold=10' : '/stock';
      final response = await _apiClient.dio.get(endpoint);
      
      if (response.data is List) {
        _stocks = (response.data as List)
            .map((json) => StockInfo.fromJson(json))
            .toList();
      }
    } on DioException catch (e) {
      debugPrint('Error fetching stock: $e');
      _errorMessage = 'Failed to load stock data. Server might be unreachable.';
    } catch (e) {
      debugPrint('Unexpected error fetching stock: $e');
      _errorMessage = 'An unexpected error occurred.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
