import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  int? _userId;
  String? _username;
  String? _role;
  String? _fullName;
  String? _pharmacyName;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get userId => _userId;
  String? get username => _username;
  String? get role => _role;
  String? get fullName => _fullName;
  String? get pharmacyName => _pharmacyName;

  AuthProvider() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    if (token != null && token.isNotEmpty) {
      _isAuthenticated = true;
      _userId = prefs.getInt('userId');
      _username = prefs.getString('username');
      _role = prefs.getString('role');
      _fullName = prefs.getString('fullName');
      _pharmacyName = prefs.getString('pharmacyName');
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.post('/auth/login', data: {
        'username': username,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        final token = data['token'];
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, token);
        await prefs.setInt('userId', data['id']);
        await prefs.setString('username', data['username']);
        await prefs.setString('role', data['role']);
        await prefs.setString('fullName', data['fullName']);
        if (data['pharmacyName'] != null) {
          await prefs.setString('pharmacyName', data['pharmacyName']);
        }

        _isAuthenticated = true;
        _userId = data['id'];
        _username = data['username'];
        _role = data['role'];
        _fullName = data['fullName'];
        _pharmacyName = data['pharmacyName'];
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      if (e is DioException && e.response != null) {
        final data = e.response?.data;
        if (data is Map<String, dynamic> && data.containsKey('message')) {
          _errorMessage = data['message'];
        } else {
          _errorMessage = 'Invalid username or password';
        }
      } else {
        _errorMessage = 'Could not connect to the server';
      }
      
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String pharmacyName, String fullName, String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.post('/auth/register', data: {
        'pharmacyName': pharmacyName,
        'fullName': fullName,
        'username': username,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        final token = data['token'];
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, token);
        await prefs.setInt('userId', data['id']);
        await prefs.setString('username', data['username']);
        await prefs.setString('role', data['role']);
        await prefs.setString('fullName', data['fullName']);
        if (data['pharmacyName'] != null) {
          await prefs.setString('pharmacyName', data['pharmacyName']);
        }

        _isAuthenticated = true;
        _userId = data['id'];
        _username = data['username'];
        _role = data['role'];
        _fullName = data['fullName'];
        _pharmacyName = data['pharmacyName'];
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      if (e is DioException && e.response != null) {
        final data = e.response?.data;
        if (data is Map<String, dynamic> && data.containsKey('message')) {
          _errorMessage = data['message'];
        } else {
          _errorMessage = 'Registration failed. Please check your inputs.';
        }
      } else {
        _errorMessage = 'Could not connect to the server';
      }
      
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove('userId');
    await prefs.remove('username');
    await prefs.remove('role');
    await prefs.remove('fullName');
    await prefs.remove('pharmacyName');
    
    _isAuthenticated = false;
    _userId = null;
    _username = null;
    _role = null;
    _fullName = null;
    _pharmacyName = null;
    notifyListeners();
  }
}
