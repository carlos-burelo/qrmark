import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:qrmark/core/libs/api_client.dart';
import 'package:qrmark/core/models/user.dart';

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  Future<Map<String, dynamic>> register({
    required String email,
    required String fullName,
    required String password,
    UserRole role = UserRole.user,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/auth/register',
        data: {
          'email': email,
          'fullName': fullName,
          'password': password,
          'role': role.toDbValue(),
        },
      );
      if (response.data['success'] == true) {
        return {'id': response.data['id'], 'token': response.data['token']};
      } else {
        throw Exception(response.data['error'] ?? 'Error en el registro');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error en la conexión');
    }
  }

  Future<Map<String, dynamic>> login({required String email, required String password}) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/auth/login',
        data: {'email': email, 'password': password},
      );
      if (response.data['success'] == true) {
        return {
          'id': response.data['id'],
          'token': response.data['token'],
          'role': UserRole.fromString(response.data['role']),
        };
      } else {
        throw Exception(response.data['error'] ?? 'Error en el inicio de sesión');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error en la conexión');
    }
  }

  Future<bool> checkToken() async {
    try {
      final response = await _apiClient.dio.get('/api/auth/check-token');
      if (response.statusCode != 200) return false;
      return response.data['success'] == true;
    } on DioException catch (_) {
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/auth/change-password',
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
      return response.data['success'] == true;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error al cambiar la contraseña');
    }
  }

  Future<void> logout() async {
    try {} on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error al cerrar sesión');
    }
  }
}

class AuthService {
  final AuthRepository _authRepository;
  final FlutterSecureStorage _secureStorage;
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userRoleKey = 'user_role';
  AuthService(this._authRepository, this._secureStorage);
  Future<bool> register({
    required String email,
    required String fullName,
    required String password,
    UserRole role = UserRole.user,
  }) async {
    try {
      final result = await _authRepository.register(
        email: email,
        fullName: fullName,
        password: password,
        role: role,
      );
      await _saveSession(result['token'], result['id'], role);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> login({required String email, required String password}) async {
    try {
      final result = await _authRepository.login(email: email, password: password);
      await _saveSession(result['token'], result['id'], result['role'] as UserRole);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return await _authRepository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  Future<void> logout() async {
    try {
      await _authRepository.logout();
      await _clearSession();
    } catch (e) {
      await _clearSession();
      rethrow;
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _secureStorage.read(key: _tokenKey);
    final existsToken = token != null && token.isNotEmpty;
    final isValidToken = await _authRepository.checkToken();
    return existsToken && isValidToken;
  }

  Future<int?> getCurrentUserId() async {
    final userIdStr = await _secureStorage.read(key: _userIdKey);
    return userIdStr != null ? int.tryParse(userIdStr) : null;
  }

  Future<UserRole?> getCurrentUserRole() async {
    final roleStr = await _secureStorage.read(key: _userRoleKey);
    if (roleStr != null) {
      return UserRole.fromString(roleStr);
    }
    return null;
  }

  Future<void> _saveSession(String token, int userId, UserRole role) async {
    await _secureStorage.write(key: _tokenKey, value: token);
    await _secureStorage.write(key: _userIdKey, value: userId.toString());
    await _secureStorage.write(key: _userRoleKey, value: role.name);
  }

  Future<void> _clearSession() async {
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _userIdKey);
    await _secureStorage.delete(key: _userRoleKey);
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  Future<bool> hasValidSession() async {
    try {
      final token = await getToken();
      final userId = await getCurrentUserId();
      final userRole = await getCurrentUserRole();

      return token != null && userId != null && userRole != null;
    } catch (e) {
      return false;
    }
  }

  Future<SessionInfo?> getCurrentSession() async {
    try {
      final token = await getToken();
      final userId = await getCurrentUserId();
      final userRole = await getCurrentUserRole();

      if (token != null && userId != null && userRole != null) {
        return SessionInfo(token: token, userId: userId, role: userRole);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

class SessionInfo {
  final String token;
  final int userId;
  final UserRole role;

  SessionInfo({required this.token, required this.userId, required this.role});
}

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _secureStorage;
  static const String _tokenKey = 'auth_token';
  AuthInterceptor(this._secureStorage);
  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _secureStorage.read(key: _tokenKey);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {}
    return handler.next(err);
  }
}
