import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../models/vehicle_info_model.dart';

class StorageService {
  static const String _userKey = 'user_data';
  static const String _vehicleKey = 'vehicle_data';
  static const String _isLoggedInKey = 'is_logged_in';

  // Save user during signup
  static Future<bool> saveUser(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(user.toJson());
      return await prefs.setString(_userKey, userJson);
    } catch (e) {
      print('Error saving user: $e');
      return false;
    }
  }

  // Get saved user
  static Future<User?> getUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      if (userJson != null) {
        return User.fromJson(jsonDecode(userJson));
      }
      return null;
    } catch (e) {
      print('Error retrieving user: $e');
      return null;
    }
  }

  // Verify login credentials
  static Future<bool> verifyLogin(String loginId, String password) async {
    try {
      final user = await getUser();
      if (user == null) return false;
      return user.loginId == loginId && user.password == password;
    } catch (e) {
      print('Error verifying login: $e');
      return false;
    }
  }

  // Save vehicle info
  static Future<bool> saveVehicleInfo(VehicleInfo vehicleInfo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final vehicleJson = jsonEncode(vehicleInfo.toJson());
      return await prefs.setString(_vehicleKey, vehicleJson);
    } catch (e) {
      print('Error saving vehicle info: $e');
      return false;
    }
  }

  // Get saved vehicle info
  static Future<VehicleInfo?> getVehicleInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final vehicleJson = prefs.getString(_vehicleKey);
      if (vehicleJson != null) {
        return VehicleInfo.fromJson(jsonDecode(vehicleJson));
      }
      return null;
    } catch (e) {
      print('Error retrieving vehicle info: $e');
      return null;
    }
  }

  // Set login status
  static Future<bool> setLoginStatus(bool isLoggedIn) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool(_isLoggedInKey, isLoggedIn);
    } catch (e) {
      print('Error setting login status: $e');
      return false;
    }
  }

  // Get login status
  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isLoggedInKey) ?? false;
    } catch (e) {
      print('Error getting login status: $e');
      return false;
    }
  }

  // Clear all data (logout)
  static Future<bool> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.clear();
    } catch (e) {
      print('Error clearing storage: $e');
      return false;
    }
  }
}
