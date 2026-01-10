import '../models/user_model.dart';
import 'storage_service.dart';

class AuthenticationService {
  // Register/Signup a new user
  static Future<Map<String, dynamic>> signup(
    String fullName,
    String loginId,
    String password,
    String confirmPassword,
  ) async {
    try {
      // Validation
      if (fullName.isEmpty || loginId.isEmpty || password.isEmpty) {
        return {
          'success': false,
          'message': 'All fields are required',
        };
      }

      if (password != confirmPassword) {
        return {
          'success': false,
          'message': 'Passwords do not match',
        };
      }

      if (password.length < 6) {
        return {
          'success': false,
          'message': 'Password must be at least 6 characters',
        };
      }

      if (loginId.length < 3) {
        return {
          'success': false,
          'message': 'Login ID must be at least 3 characters',
        };
      }

      // Check if user already exists
      final existingUser = await StorageService.getUser();
      if (existingUser != null && existingUser.loginId == loginId) {
        return {
          'success': false,
          'message': 'Login ID already exists',
        };
      }

      // Create new user
      final newUser = User(
        loginId: loginId,
        password: password,
        fullName: fullName,
      );

      // Save user
      final saved = await StorageService.saveUser(newUser);
      if (saved) {
        return {
          'success': true,
          'message': 'Account created successfully',
          'user': newUser,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to create account',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error during signup: ${e.toString()}',
      };
    }
  }

  // Login user
  static Future<Map<String, dynamic>> login(
    String loginId,
    String password,
  ) async {
    try {
      // Validation
      if (loginId.isEmpty || password.isEmpty) {
        return {
          'success': false,
          'message': 'Login ID and password are required',
        };
      }

      // Verify credentials
      final isValid = await StorageService.verifyLogin(loginId, password);
      if (!isValid) {
        return {
          'success': false,
          'message': 'Invalid login ID or password',
        };
      }

      // Get user details
      final user = await StorageService.getUser();
      if (user == null) {
        return {
          'success': false,
          'message': 'User not found',
        };
      }

      // Set login status
      await StorageService.setLoginStatus(true);

      return {
        'success': true,
        'message': 'Login successful',
        'user': user,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error during login: ${e.toString()}',
      };
    }
  }

  // Logout user
  static Future<bool> logout() async {
    try {
      await StorageService.setLoginStatus(false);
      return true;
    } catch (e) {
      print('Error logging out: $e');
      return false;
    }
  }

  // Get current user
  static Future<User?> getCurrentUser() async {
    try {
      return await StorageService.getUser();
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }
}
