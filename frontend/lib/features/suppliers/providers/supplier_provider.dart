import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/supplier.dart';

class SupplierProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<Supplier> _suppliers = [];
  List<Supplier> get suppliers => _suppliers;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchSuppliers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get('/suppliers');
      if (response.data is List) {
        _suppliers = (response.data as List)
            .map((json) => Supplier.fromJson(json))
            .toList();
      }
    } on DioException catch (e) {
      debugPrint('Error fetching suppliers: $e');
      _errorMessage = 'Failed to load suppliers. Server might be unreachable.';
    } catch (e) {
      debugPrint('Unexpected error fetching suppliers: $e');
      _errorMessage = 'An unexpected error occurred.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addSupplier(Supplier supplier) async {
    try {
      final response = await _apiClient.dio.post(
        '/suppliers',
        data: supplier.toJson(),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchSuppliers();
        return true;
      }
      return false;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to add supplier.';
      throw Exception(msg);
    } catch (e) {
      throw Exception('An unexpected error occurred.');
    }
  }

  Future<bool> updateSupplier(Supplier supplier) async {
    try {
      final response = await _apiClient.dio.put(
        '/suppliers/${supplier.id}',
        data: supplier.toJson(),
      );
      if (response.statusCode == 200) {
        await fetchSuppliers();
        return true;
      }
      return false;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to update supplier.';
      throw Exception(msg);
    } catch (e) {
      throw Exception('An unexpected error occurred.');
    }
  }

  Future<bool> deleteSupplier(int id) async {
    try {
      final response = await _apiClient.dio.delete('/suppliers/$id');
      if (response.statusCode == 200 || response.statusCode == 204) {
        await fetchSuppliers();
        return true;
      }
      return false;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to delete supplier. It might be in use.';
      throw Exception(msg);
    } catch (e) {
      throw Exception('An unexpected error occurred.');
    }
  }
}
