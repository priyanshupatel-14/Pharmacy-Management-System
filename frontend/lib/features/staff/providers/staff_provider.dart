import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class StaffProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  
  List<Map<String, dynamic>> _staff = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> get staff => _staff;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchStaff() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get('/users');
      if (response.statusCode == 200) {
        _staff = List<Map<String, dynamic>>.from(response.data);
      } else {
        _errorMessage = 'Failed to load staff';
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) {
          _errorMessage = 'Unauthorized. Only ADMIN can view staff.';
      } else {
          _errorMessage = 'Error connecting to server';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createStaff(String fullName, String username, String password, String role) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.post('/users', data: {
        'fullName': fullName,
        'username': username,
        'password': password,
        'role': role,
      });

      if (response.statusCode == 200) {
        await fetchStaff();
        return true;
      } else {
        _errorMessage = 'Failed to create staff';
        return false;
      }
    } catch (e) {
      if (e is DioException && e.response != null) {
        final data = e.response?.data;
        if (data is Map<String, dynamic> && data.containsKey('message')) {
          _errorMessage = data['message'];
        } else {
          _errorMessage = 'Failed to create staff';
        }
      } else {
        _errorMessage = 'Error connecting to server';
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteStaff(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.delete('/users/$id');
      if (response.statusCode == 200) {
        _staff.removeWhere((member) => member['id'] == id);
        return true;
      } else {
        _errorMessage = 'Failed to delete staff';
        return false;
      }
    } catch (e) {
       if (e is DioException && e.response != null) {
        final data = e.response?.data;
        if (data is Map<String, dynamic> && data.containsKey('message')) {
          _errorMessage = data['message'];
        } else {
          _errorMessage = 'Failed to delete staff';
        }
      } else {
        _errorMessage = 'Error connecting to server';
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
