import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static const String _currentUserKey = 'current_user';
  static const String _usersListKey = 'registered_users';

  Future<SharedPreferences> get _prefs async {
    return await SharedPreferences.getInstance();
  }

  // Initialize (no need for complex init with shared_preferences)
  Future<void> init() async {
    // Shared preferences doesn't need explicit initialization
    print('✅ Database Helper initialized');
  }

  // Register new user
  Future<int> registerUser(String name, String email, String password) async {
    try {
      final prefs = await _prefs;

      // Get existing users
      final usersJson = prefs.getString(_usersListKey) ?? '[]';
      final List<dynamic> usersList = json.decode(usersJson);

      // Check if email already exists
      final emailExists = usersList.any((user) => user['email'] == email);
      if (emailExists) {
        throw Exception('Email already exists');
      }

      // Create new user
      final newUser = UserModel(
        id: DateTime.now().millisecondsSinceEpoch,
        name: name,
        email: email,
        password: password,
        createdAt: DateTime.now(),
      );

      // Add new user to list
      usersList.add(newUser.toMap());

      // Save updated users list
      await prefs.setString(_usersListKey, json.encode(usersList));

      print('✅ User registered: ${newUser.name} (ID: ${newUser.id})');
      return newUser.id;
    } catch (e) {
      print('❌ Registration error: $e');
      throw Exception('Registration failed: $e');
    }
  }

  // Login user
  Future<UserModel?> loginUser(String email, String password) async {
    try {
      final prefs = await _prefs;
      final usersJson = prefs.getString(_usersListKey) ?? '[]';
      final List<dynamic> usersList = json.decode(usersJson);

      // Find user by email and password
      for (var userMap in usersList) {
        if (userMap['email'] == email && userMap['password'] == password) {
          final user = UserModel.fromMap(Map<String, dynamic>.from(userMap));

          // Save current user
          await _setCurrentUser(user);
          print('✅ User logged in: ${user.name}');
          return user;
        }
      }

      return null;
    } catch (e) {
      print('❌ Login error: $e');
      return null;
    }
  }

  // Check if user exists
  Future<bool> userExists(String email) async {
    try {
      final prefs = await _prefs;
      final usersJson = prefs.getString(_usersListKey) ?? '[]';
      final List<dynamic> usersList = json.decode(usersJson);

      return usersList.any((user) => user['email'] == email);
    } catch (e) {
      print('❌ User exists check error: $e');
      return false;
    }
  }

  // Get current user
  Future<UserModel?> getCurrentUser() async {
    try {
      final prefs = await _prefs;
      final userJson = prefs.getString(_currentUserKey);

      if (userJson != null) {
        final userMap = json.decode(userJson);
        final user = UserModel.fromMap(Map<String, dynamic>.from(userMap));
        print('✅ Current user loaded: ${user.name}');
        return user;
      }

      print('ℹ️ No current user found');
      return null;
    } catch (e) {
      print('❌ Get current user error: $e');
      return null;
    }
  }

  // Set current user
  Future<void> _setCurrentUser(UserModel user) async {
    try {
      final prefs = await _prefs;
      await prefs.setString(_currentUserKey, user.toJson());
      print('✅ Current user saved: ${user.name}');
    } catch (e) {
      print('❌ Set current user error: $e');
    }
  }

  // Update user profile
  Future<bool> updateUserProfile(UserModel updatedUser) async {
    try {
      final prefs = await _prefs;
      final usersJson = prefs.getString(_usersListKey) ?? '[]';
      final List<dynamic> usersList = json.decode(usersJson);

      // Find and update user
      final userIndex =
          usersList.indexWhere((user) => user['id'] == updatedUser.id);
      if (userIndex != -1) {
        usersList[userIndex] = updatedUser.toMap();
        await prefs.setString(_usersListKey, json.encode(usersList));

        // Update current user if it's the same user
        final currentUser = await getCurrentUser();
        if (currentUser != null && currentUser.id == updatedUser.id) {
          await _setCurrentUser(updatedUser);
        }

        print('✅ User profile updated: ${updatedUser.name}');
        return true;
      }

      return false;
    } catch (e) {
      print('❌ Update user profile error: $e');
      return false;
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      final prefs = await _prefs;
      await prefs.remove(_currentUserKey);
      print('✅ User logged out');
    } catch (e) {
      print('❌ Logout error: $e');
    }
  }

  // Get all users (for debugging)
  Future<List<UserModel>> getAllUsers() async {
    try {
      final prefs = await _prefs;
      final usersJson = prefs.getString(_usersListKey) ?? '[]';
      final List<dynamic> usersList = json.decode(usersJson);

      return usersList
          .map((userMap) =>
              UserModel.fromMap(Map<String, dynamic>.from(userMap)))
          .toList();
    } catch (e) {
      print('❌ Get all users error: $e');
      return [];
    }
  }

  // Clear all data (for testing)
  Future<void> clearAllData() async {
    try {
      final prefs = await _prefs;
      await prefs.remove(_currentUserKey);
      await prefs.remove(_usersListKey);
      print('✅ All data cleared');
    } catch (e) {
      print('❌ Clear all data error: $e');
    }
  }

  // Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final prefs = await _prefs;
      final usersJson = prefs.getString(_usersListKey) ?? '[]';
      final List<dynamic> usersList = json.decode(usersJson);
      final hasCurrentUser = await getCurrentUser() != null;

      return {
        'total_users': usersList.length,
        'has_current_user': hasCurrentUser,
        'users': usersList.map((user) => user['email']).toList(),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
