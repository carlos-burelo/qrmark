import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qrmark/core/libs/api_client.dart';
import 'package:qrmark/core/models/user.dart';

enum DistributionMode { users, lists }

extension DistributionModeExtension on DistributionMode {
  String get label {
    switch (this) {
      case DistributionMode.users:
        return "Usuarios";
      case DistributionMode.lists:
        return "Listas de distribución";
    }
  }

  IconData get icon {
    switch (this) {
      case DistributionMode.users:
        return LucideIcons.userPlus;
      case DistributionMode.lists:
        return LucideIcons.listCheck;
    }
  }
}

class DistributionList {
  final int id;
  final String name;
  final String? description;
  final int organizerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? memberCount;
  final User? organizer;
  final List<User>? members;

  const DistributionList({
    required this.id,
    required this.name,
    this.description,
    required this.organizerId,
    required this.createdAt,
    required this.updatedAt,
    this.organizer,
    this.members,
    this.memberCount,
  });

  factory DistributionList.fromJson(Map<String, dynamic> json) {
    return DistributionList(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      organizerId: json['organizerId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      organizer: json['organizer'] != null ? User.fromJson(json['organizer']) : null,
      members:
          json['members'] != null
              ? List<User>.from(json['members'].map((x) => User.fromJson(x)))
              : null,
      memberCount: json['memberCount'] != null ? int.parse(json['memberCount'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'organizerId': organizerId,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  DistributionList copyWith({
    int? id,
    String? name,
    String? description,
    int? organizerId,
    DateTime? createdAt,
    DateTime? updatedAt,
    User? organizer,
    List<User>? members,
  }) {
    return DistributionList(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      organizerId: organizerId ?? this.organizerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      organizer: organizer ?? this.organizer,
      members: members ?? this.members,
    );
  }
}

class DistributionListRepository {
  final ApiClient _apiClient;

  DistributionListRepository(this._apiClient);

  Future<DistributionList> getListById(int id) async {
    try {
      final response = await _apiClient.dio.get('/api/lists/$id');

      if (response.data['success'] == true) {
        return DistributionList.fromJson(response.data['list']);
      } else {
        throw Exception(response.data['error'] ?? 'Error al obtener la lista');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error en la conexión');
    }
  }

  Future<int> createList({required String name, String? description}) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/lists',
        data: {'name': name, if (description != null) 'description': description},
      );

      if (response.data['success'] == true) {
        return response.data['id'];
      } else {
        throw Exception(response.data['error'] ?? 'Error al crear la lista');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error en la conexión');
    }
  }

  Future<bool> updateList({required int id, String? name, String? description}) async {
    try {
      final Map<String, dynamic> data = {};
      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;

      final response = await _apiClient.dio.put('/api/lists/$id', data: data);

      return response.data['success'] == true;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error al actualizar la lista');
    }
  }

  Future<bool> deleteList(int id) async {
    try {
      final response = await _apiClient.dio.delete('/api/lists/$id');
      return response.data['success'] == true;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error al eliminar la lista');
    }
  }

  Future<List<DistributionList>> getListsByOrganizer() async {
    try {
      final response = await _apiClient.dio.get('/api/lists');

      if (response.data['success'] == true) {
        final List<dynamic> listsJson = response.data['lists'];
        return listsJson.map((json) => DistributionList.fromJson(json)).toList();
      } else {
        throw Exception(response.data['error'] ?? 'Error al obtener las listas');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error en la conexión');
    }
  }

  Future<bool> addMultipleMembersToList(int listId, List<int> userIds) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/lists/$listId/members',
        data: {'userIds': userIds},
      );

      return response.data['success'] == true;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error al añadir los miembros');
    }
  }

  Future<bool> removeMemberFromList(int listId, int userId) async {
    try {
      final response = await _apiClient.dio.delete('/api/lists/$listId/members/$userId');
      return response.data['success'] == true;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error al eliminar el miembro');
    }
  }

  Future<List<User>> getListMembers(int listId) async {
    try {
      final response = await _apiClient.dio.get('/api/lists/$listId/members');

      if (response.data['success'] == true) {
        final List<dynamic> membersJson = response.data['members'];

        final members =
            membersJson.map((json) {
              try {
                return User.fromJson(json);
              } catch (e) {
                throw Exception('Error al parsear el miembro: $json');
              }
            }).toList();

        return members;
      } else {
        throw Exception(response.data['error'] ?? 'Error al obtener los miembros');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error en la conexión');
    }
  }
}

class DistributionListService {
  final DistributionListRepository _distributionListRepository;
  final UserService _userService;

  DistributionListService(this._distributionListRepository, this._userService);

  Future<DistributionList> getListById(int id) async {
    if (!await _userService.isOrganizer()) {
      throw Exception('Solo los organizadores pueden acceder a las listas de distribución');
    }

    return await _distributionListRepository.getListById(id);
  }

  Future<int> createList({required String name, String? description}) async {
    if (!await _userService.isOrganizer()) {
      throw Exception('Solo los organizadores pueden crear listas de distribución');
    }

    return await _distributionListRepository.createList(name: name, description: description);
  }

  Future<bool> updateList({required int id, String? name, String? description}) async {
    if (!await _userService.isOrganizer()) {
      throw Exception('Solo los organizadores pueden actualizar listas de distribución');
    }

    return await _distributionListRepository.updateList(
      id: id,
      name: name,
      description: description,
    );
  }

  Future<bool> deleteList(int id) async {
    if (!await _userService.isOrganizer()) {
      throw Exception('Solo los organizadores pueden eliminar listas de distribución');
    }

    return await _distributionListRepository.deleteList(id);
  }

  Future<List<DistributionList>> getMyLists() async {
    if (!await _userService.isOrganizer()) {
      throw Exception('Solo los organizadores pueden ver listas de distribución');
    }

    return await _distributionListRepository.getListsByOrganizer();
  }

  Future<bool> addMultipleMembersToList(int listId, List<int> userIds) async {
    if (!await _userService.isOrganizer()) {
      throw Exception('Solo los organizadores pueden añadir miembros a listas');
    }
    await _distributionListRepository.addMultipleMembersToList(listId, userIds);
    return true;
  }

  Future<bool> removeMemberFromList(int listId, int userId) async {
    if (!await _userService.isOrganizer()) {
      throw Exception('Solo los organizadores pueden eliminar miembros de listas');
    }

    return await _distributionListRepository.removeMemberFromList(listId, userId);
  }

  Future<List<User>> getListMembers(int listId) async {
    if (!await _userService.isOrganizer()) {
      throw Exception('Solo los organizadores pueden ver los miembros de listas');
    }

    return await _distributionListRepository.getListMembers(listId);
  }
}
