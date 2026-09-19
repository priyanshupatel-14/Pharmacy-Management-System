import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  bool _isLoading = false;
  String? _errorMessage;

  int _totalMedicines = 0;
  int _totalStock = 0;
  int _lowStockCount = 0;
  int _expiredBatchesCount = 0;
  int _expiringSoonCount = 0;
  double _totalSales = 0.0;

  List<dynamic> _recentSales = [];
  List<dynamic> _lowStockItems = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalMedicines => _totalMedicines;
  int get totalStock => _totalStock;
  int get lowStockCount => _lowStockCount;
  int get expiredBatchesCount => _expiredBatchesCount;
  int get expiringSoonCount => _expiringSoonCount;
  double get totalSales => _totalSales;
  
  List<dynamic> get recentSales => _recentSales;
  List<dynamic> get lowStockItems => _lowStockItems;

  Future<void> fetchDashboardData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Medicines
      try {
        final medicinesResponse = await _apiClient.dio.get('/medicines');
        if (medicinesResponse.data is List) {
          _totalMedicines = (medicinesResponse.data as List).length;
        }
      } catch (e) {
        debugPrint('Error fetching medicines: $e');
      }

      // 2. Stock (Total Stock)
      try {
        final stockResponse = await _apiClient.dio.get('/stock');
        if (stockResponse.data is List) {
          int stock = 0;
          for (var item in stockResponse.data) {
            stock += (item['totalStock'] as num?)?.toInt() ?? 0;
          }
          _totalStock = stock;
        }
      } catch (e) {
        debugPrint('Error fetching stock: $e');
      }

      // 3. Low Stock
      try {
        final lowStockResponse = await _apiClient.dio.get('/stock/low');
        if (lowStockResponse.data is List) {
          final list = lowStockResponse.data as List;
          _lowStockCount = list.length;
          // Store top 5 low stock items
          _lowStockItems = list.take(5).toList();
        }
      } catch (e) {
        debugPrint('Error fetching low stock: $e');
      }

      // 4. Expired Batches
      try {
        final expiredResponse = await _apiClient.dio.get('/batches/expired');
        if (expiredResponse.data is List) {
          _expiredBatchesCount = (expiredResponse.data as List).length;
        }
      } catch (e) {
        debugPrint('Error fetching expired batches: $e');
      }

      // 5. Expiring Soon
      try {
        final expiringResponse = await _apiClient.dio.get('/batches/expiring-soon?days=30');
        if (expiringResponse.data is List) {
          _expiringSoonCount = (expiringResponse.data as List).length;
        }
      } catch (e) {
        debugPrint('Error fetching expiring soon batches: $e');
      }

      // 6. Sales
      try {
        final salesResponse = await _apiClient.dio.get('/sales');
        if (salesResponse.data is List) {
          final list = salesResponse.data as List;
          double salesTotal = 0.0;
          for (var item in list) {
            salesTotal += (item['totalAmount'] as num?)?.toDouble() ?? 0.0;
          }
          _totalSales = salesTotal;
          // Store 5 most recent sales (assuming API returns chronologically, we reverse to get newest if it's oldest first, but let's just reverse to be safe assuming ID ascending)
          _recentSales = list.reversed.take(5).toList();
        }
      } catch (e) {
        debugPrint('Error fetching sales: $e');
      }

      _isLoading = false;
      notifyListeners();
      
    } on DioException catch (e) {
      debugPrint('Dio error: $e');
      _errorMessage = 'Could not fetch dashboard data. Server might be unreachable.';
      _isLoading = false;
      notifyListeners();
    } catch (_) {
      _errorMessage = 'An unexpected error occurred.';
      _isLoading = false;
      notifyListeners();
    }
  }
}
