import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/medicine.dart';
import '../models/supplier_minimal.dart';

class MedicineProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<Medicine> _medicines = [];
  List<Medicine> get medicines => _medicines;

  List<SupplierMinimal> _suppliers = [];
  List<SupplierMinimal> get suppliers => _suppliers;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchMedicines() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get('/medicines');
      if (response.data is List) {
        _medicines = (response.data as List)
            .map((json) => Medicine.fromJson(json))
            .toList();
      }
    } on DioException catch (e) {
      debugPrint('Error fetching medicines: $e');
      _errorMessage = 'Failed to load medicines. Server might be unreachable.';
    } catch (e) {
      debugPrint('Unexpected error fetching medicines: $e');
      _errorMessage = 'An unexpected error occurred.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchMedicines(String query) async {
    if (query.trim().isEmpty) {
      await fetchMedicines();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get(
        '/medicines/search',
        queryParameters: {'q': query},
      );
      if (response.data is List) {
        _medicines = (response.data as List)
            .map((json) => Medicine.fromJson(json))
            .toList();
      }
    } on DioException catch (e) {
      debugPrint('Error searching medicines: $e');
      _errorMessage = 'Failed to search medicines.';
    } catch (e) {
      debugPrint('Unexpected error searching medicines: $e');
      _errorMessage = 'An unexpected error occurred.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSuppliers() async {
    try {
      final response = await _apiClient.dio.get('/suppliers');
      if (response.data is List) {
        _suppliers = (response.data as List)
            .map((json) => SupplierMinimal.fromJson(json))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching suppliers: $e');
      // We do not fail the whole screen if suppliers fail, but dropdown will be empty
    }
  }

  Future<bool> addMedicine(Medicine medicine) async {
    try {
      final response = await _apiClient.dio.post(
        '/medicines',
        data: medicine.toJson(),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchMedicines(); // Refresh
        return true;
      }
      return false;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to add medicine.';
      throw Exception(msg);
    } catch (e) {
      throw Exception('An unexpected error occurred.');
    }
  }

  Future<bool> updateMedicine(Medicine medicine) async {
    try {
      final response = await _apiClient.dio.put(
        '/medicines/${medicine.id}',
        data: medicine.toJson(),
      );
      if (response.statusCode == 200) {
        await fetchMedicines(); // Refresh
        return true;
      }
      return false;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to update medicine.';
      throw Exception(msg);
    } catch (e) {
      throw Exception('An unexpected error occurred.');
    }
  }

  Future<bool> deleteMedicine(int id) async {
    try {
      final response = await _apiClient.dio.delete('/medicines/$id');
      if (response.statusCode == 200 || response.statusCode == 204) {
        await fetchMedicines(); // Refresh
        return true;
      }
      return false;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to delete medicine. It might be in use.';
      throw Exception(msg);
    } catch (e) {
      throw Exception('An unexpected error occurred.');
    }
  }
}
