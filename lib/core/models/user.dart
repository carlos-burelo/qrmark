import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qrmark/core/config/theme.dart';
import 'package:qrmark/core/libs/api_client.dart';
import 'package:qrmark/core/models/auth.dart';

enum UserRole {
  user,
  moderator,
  organizer;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => UserRole.user,
    );
  }

  String toDbValue() => name.toUpperCase();

  String get displayName {
    switch (this) {
      case UserRole.user:
        return 'Usuario';
      case UserRole.moderator:
        return 'Moderador';
      case UserRole.organizer:
        return 'Organizador';
    }
  }

  Color get color {
    switch (this) {
      case UserRole.user:
        return AppColors.successColor;
      case UserRole.moderator:
        return AppColors.infoColor;
      case UserRole.organizer:
        return AppColors.errorColor;
    }
  }

  Icon get icon {
    switch (this) {
      case UserRole.user:
        return const Icon(Icons.person, color: AppColors.successColor);
      case UserRole.moderator:
        return const Icon(Icons.shield, color: AppColors.infoColor);
      case UserRole.organizer:
        return const Icon(Icons.star, color: AppColors.errorColor);
    }
  }
}

class User {
  final int id;
  final String email;
  final String fullName;
  final UserRole role;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? addedAt;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    this.addedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      fullName: json['fullName'],
      role: UserRole.fromString(json['role']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      addedAt: json['addedAt'] != null ? DateTime.parse(json['addedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'fullName': fullName,
    'role': role.toDbValue(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  User copyWith({
    int? id,
    String? email,
    String? fullName,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get userHandle {
    return fullName.isNotEmpty ? fullName : email.split('@')[0];
  }

  String get joinDate => DateFormat('dd/MM/yyyy').format(createdAt);
  @override
  String toString() => 'User(id: $id, email: $email, fullName: $fullName, role: ${role.name})';
}

class UserRepository {
  final ApiClient _apiClient;

  UserRepository(this._apiClient);

  Future<User> getCurrentUser() async {
    try {
      final response = await _apiClient.dio.get('/api/users/me');

      if (response.data['success'] == true) {
        return User.fromJson(response.data['user']);
      } else {
        throw Exception(response.data['error'] ?? 'Error al obtener el usuario');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error en la conexión');
    }
  }

  Future<bool> updateUser({required String fullName}) async {
    try {
      final response = await _apiClient.dio.put('/api/users/me', data: {'fullName': fullName});

      return response.data['success'] == true;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error al actualizar el usuario');
    }
  }

  Future<List<User>> getAllUsers(UserRole? roleQuery) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/users',
        queryParameters: {'role': roleQuery?.toDbValue()},
      );

      if (response.data['success'] == true) {
        final List<dynamic> usersJson = response.data['users'];
        return usersJson.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception(response.data['error'] ?? 'Error al obtener los usuarios');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error en la conexión');
    }
  }

  Future<bool> promoteToModerator(int userId) async {
    try {
      final response = await _apiClient.dio.post('/api/users/$userId/promote');
      return response.data['success'] == true;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error al promover al usuario');
    }
  }

  Future<bool> demoteToUser(int userId) async {
    try {
      final response = await _apiClient.dio.post('/api/users/$userId/demote');
      return response.data['success'] == true;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error al degradar al usuario');
    }
  }
}

class UserService {
  final UserRepository _userRepository;
  final AuthService _authService;

  User? _currentUser;

  UserService(this._userRepository, this._authService);

  Future<User> getCurrentUser({bool forceRefresh = false}) async {
    if (_currentUser != null && !forceRefresh) {
      return _currentUser!;
    }

    _currentUser = await _userRepository.getCurrentUser();
    return _currentUser!;
  }

  Future<User> refreshCurrentUser() async {
    return getCurrentUser(forceRefresh: true);
  }

  Future<bool> updateUserName(String fullName) async {
    final success = await _userRepository.updateUser(fullName: fullName);

    if (success) {
      _currentUser = (_currentUser?.copyWith(fullName: fullName));
    }

    return success;
  }

  Future<List<User>> getAllUsers(UserRole? roleQuery) async {
    final role = await _authService.getCurrentUserRole();

    if (role != UserRole.organizer) {
      throw Exception('No tienes permisos para ver todos los usuarios');
    }

    return await _userRepository.getAllUsers(roleQuery);
  }

  Future<bool> promoteToModerator(int userId) async {
    final role = await _authService.getCurrentUserRole();

    if (role != UserRole.organizer) {
      throw Exception('No tienes permisos para promover usuarios');
    }

    return await _userRepository.promoteToModerator(userId);
  }

  Future<bool> demoteToUser(int userId) async {
    final role = await _authService.getCurrentUserRole();

    if (role != UserRole.organizer) {
      throw Exception('No tienes permisos para degradar usuarios');
    }

    return await _userRepository.demoteToUser(userId);
  }

  Future<bool> isOrganizer() async {
    final role = await _authService.getCurrentUserRole();
    return role == UserRole.organizer;
  }

  Future<bool> isModerator() async {
    final role = await _authService.getCurrentUserRole();
    return role == UserRole.moderator;
  }

  Future<bool> canScanQR() async {
    final role = await _authService.getCurrentUserRole();
    return role == UserRole.moderator || role == UserRole.organizer;
  }
}
