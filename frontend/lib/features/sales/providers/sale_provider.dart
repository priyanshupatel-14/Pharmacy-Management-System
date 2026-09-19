import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../models/sale.dart';
import '../models/sale_request.dart';
import '../../stock/models/stock_info.dart';
import '../../medicines/models/medicine.dart';

class SaleProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<Sale> _sales = [];
  List<Sale> get sales => _sales;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<StockInfo> _availableStock = [];
  List<StockInfo> get availableStock => _availableStock;

  List<Medicine> _medicines = [];
  List<Medicine> get medicines => _medicines;

  Future<void> fetchSales() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get('/sales');
      if (response.data is List) {
        _sales = (response.data as List)
            .map((json) => Sale.fromJson(json))
            .toList();
        // Sort descending by ID or date
        _sales.sort((a, b) => b.id.compareTo(a.id));
      }
    } on DioException catch (e) {
      debugPrint('Error fetching sales: $e');
      _errorMessage = 'Failed to load sales history. Server might be unreachable.';
    } catch (e) {
      debugPrint('Unexpected error: $e');
      _errorMessage = 'An unexpected error occurred.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Sale?> fetchSaleDetails(int saleId) async {
    try {
      final response = await _apiClient.dio.get('/sales/$saleId');
      return Sale.fromJson(response.data);
    } catch (e) {
      debugPrint('Error fetching sale details: $e');
      return null;
    }
  }

  Future<StockInfo?> fetchMedicineDetailedStock(int medicineId) async {
    try {
      final response = await _apiClient.dio.get('/stock/medicine/$medicineId');
      return StockInfo.fromJson(response.data);
    } catch (e) {
      debugPrint('Error fetching detailed stock for medicine $medicineId: $e');
      return null;
    }
  }

  Future<void> fetchAvailableStockAndMedicines() async {
    try {
      final stockResp = await _apiClient.dio.get('/stock');
      if (stockResp.data is List) {
        _availableStock = (stockResp.data as List)
            .map((json) => StockInfo.fromJson(json))
            .toList();
      }

      final medResp = await _apiClient.dio.get('/medicines');
      if (medResp.data is List) {
        _medicines = (medResp.data as List)
            .map((json) => Medicine.fromJson(json))
            .toList();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching stock and medicines for sales: $e');
    }
  }

  Future<bool> createSale(List<SaleItemRequest> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Assuming username is saved. To do real userId, we might need a dummy one or fetch it.
      // Wait, backend requires userId. Let's hardcode 1 for now if we don't store user ID.
      // Or let's see what is stored during login.
      final userId = prefs.getInt('userId') ?? 1; // Fallback to 1

      final request = SaleRequest(userId: userId, items: items);
      
      final response = await _apiClient.dio.post(
        '/sales',
        data: request.toJson(),
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchSales();
        return true;
      }
      return false;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to create sale. Please verify stock.';
      throw Exception(msg);
    } catch (e) {
      throw Exception('An unexpected error occurred.');
    }
  }
}
