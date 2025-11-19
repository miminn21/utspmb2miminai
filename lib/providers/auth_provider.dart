import 'package:flutter/foundation.dart';
import '../helpers/database_helper.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  bool _isLoading = false;
  String _errorMessage = '';
  bool _isLoggedIn = false;
  UserModel? _currentUser;

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isLoggedIn => _isLoggedIn;
  UserModel? get currentUser => _currentUser;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _dbHelper.init();
      final user = await _dbHelper.getCurrentUser();
      if (user != null) {
        _isLoggedIn = true;
        _currentUser = user;
      }
    } catch (e) {
      _isLoggedIn = false;
      print('Error checking login status: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // Validation
      if (name.isEmpty || email.isEmpty || password.isEmpty) {
        throw Exception('All fields are required');
      }

      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        throw Exception('Please enter a valid email');
      }

      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters');
      }

      final userId = await _dbHelper.registerUser(name, email, password);

      if (userId > 0) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        throw Exception('Registration failed');
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email and password are required');
      }

      final user = await _dbHelper.loginUser(email, password);

      if (user != null) {
        _isLoggedIn = true;
        _currentUser = user;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        throw Exception('Invalid email or password');
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _dbHelper.logout();
    _isLoggedIn = false;
    _currentUser = null;
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
}
