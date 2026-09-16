import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/medicine_batch.dart';
import '../../medicines/models/medicine.dart'; // To fetch medicines for dropdown

class BatchProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<MedicineBatch> _batches = [];
  List<MedicineBatch> get batches => _batches;

  List<Medicine> _medicines = [];
  List<Medicine> get medicines => _medicines;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String _filter = 'all'; // all, expired, expiring_soon
  String get filter => _filter;

  void setFilter(String filter) {
    _filter = filter;
    fetchBatches();
  }

  Future<void> fetchMedicines() async {
    try {
      final response = await _apiClient.dio.get('/medicines');
      if (response.data is List) {
        _medicines = (response.data as List)
            .map((json) => Medicine.fromJson(json))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching medicines for batch dropdown: $e');
    }
  }

  Future<void> fetchBatches() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String endpoint = '/batches';
      if (_filter == 'expired') endpoint = '/batches/expired';
      if (_filter == 'expiring_soon') endpoint = '/batches/expiring-soon?days=30';

      final response = await _apiClient.dio.get(endpoint);
      if (response.data is List) {
        _batches = (response.data as List)
            .map((json) => MedicineBatch.fromJson(json))
            .toList();
      }
    } on DioException catch (e) {
      debugPrint('Error fetching batches: $e');
      _errorMessage = 'Failed to load batches. Server might be unreachable.';
    } catch (e) {
      debugPrint('Unexpected error fetching batches: $e');
      _errorMessage = 'An unexpected error occurred.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addBatch(MedicineBatch batch) async {
    try {
      final response = await _apiClient.dio.post(
        '/batches',
        data: batch.toJson(),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchBatches();
        return true;
      }
      return false;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to add batch.';
      throw Exception(msg);
    } catch (e) {
      throw Exception('An unexpected error occurred.');
    }
  }

  Future<bool> updateBatch(MedicineBatch batch) async {
    try {
      final response = await _apiClient.dio.put(
        '/batches/${batch.id}',
        data: batch.toJson(),
      );
      if (response.statusCode == 200) {
        await fetchBatches();
        return true;
      }
      return false;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to update batch.';
      throw Exception(msg);
    } catch (e) {
      throw Exception('An unexpected error occurred.');
    }
  }

  Future<bool> deleteBatch(int id) async {
    try {
      final response = await _apiClient.dio.delete('/batches/$id');
      if (response.statusCode == 200 || response.statusCode == 204) {
        await fetchBatches();
        return true;
      }
      return false;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to delete batch. It might be in use.';
      throw Exception(msg);
    } catch (e) {
      throw Exception('An unexpected error occurred.');
    }
  }
}
