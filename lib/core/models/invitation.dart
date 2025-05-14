import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:qrmark/core/config/theme.dart';
import 'package:qrmark/core/libs/api_client.dart';
import 'package:qrmark/core/models/event.dart';
import 'package:qrmark/core/models/user.dart';

enum InvitationStatus {
  pending,
  accepted,
  declined;

  static InvitationStatus fromString(String value) {
    return InvitationStatus.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => InvitationStatus.pending,
    );
  }

  String toDbValue() => name.toUpperCase();

  String get displayName {
    switch (this) {
      case InvitationStatus.pending:
        return 'Pendiente';
      case InvitationStatus.accepted:
        return 'Aceptada';
      case InvitationStatus.declined:
        return 'Rechazada';
    }
  }

  Color get color {
    switch (this) {
      case InvitationStatus.pending:
        return AppColors.warningColor;
      case InvitationStatus.accepted:
        return AppColors.successColor;
      case InvitationStatus.declined:
        return AppColors.errorColor;
    }
  }
}

class Invitation {
  final int id;
  final int eventId;
  final int userId;
  final InvitationStatus status;
  final DateTime sentAt;
  final DateTime? respondedAt;

  final Event? event;
  final User? user;

  const Invitation({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.status,
    required this.sentAt,
    this.respondedAt,
    this.event,
    this.user,
  });

  factory Invitation.fromJson(Map<String, dynamic> json) {
    return Invitation(
      id: json['id'],
      eventId: json['eventId'],
      userId: json['userId'],
      status: InvitationStatus.fromString(json['status']),
      sentAt: DateTime.parse(json['sentAt']),
      respondedAt: json['respondedAt'] != null ? DateTime.parse(json['respondedAt']) : null,
      event: json['event'] != null ? Event.invitationFromJson(json['event']) : null,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'eventId': eventId,
    'userId': userId,
    'status': status.toDbValue(),
    'sentAt': sentAt.toIso8601String(),
    'respondedAt': respondedAt?.toIso8601String(),
  };

  Invitation copyWith({
    int? id,
    int? eventId,
    int? userId,
    InvitationStatus? status,
    DateTime? sentAt,
    DateTime? respondedAt,
    Event? event,
    User? user,
  }) {
    return Invitation(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      sentAt: sentAt ?? this.sentAt,
      respondedAt: respondedAt ?? this.respondedAt,
      event: event ?? this.event,
      user: user ?? this.user,
    );
  }

  bool get isPending => status == InvitationStatus.pending;
  bool get isAccepted => status == InvitationStatus.accepted;
  bool get isDeclined => status == InvitationStatus.declined;
  bool get hasResponded => respondedAt != null;
}

typedef InvitationList = List<Invitation>;
typedef InvitationListPromise = Future<InvitationList>;
typedef InvitationPromise = Future<Invitation>;

class InvitationRepository {
  final ApiClient _apiClient;

  InvitationRepository(this._apiClient);

  Future<Invitation> getInvitationById(int id) async {
    try {
      final response = await _apiClient.dio.get('/api/invitations/$id');

      if (response.data['success'] == true) {
        return Invitation.fromJson(response.data['invitation']);
      } else {
        throw Exception(response.data['error'] ?? 'Error al obtener la invitación');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error en la conexión');
    }
  }

  Future<int> createInvitation({required int eventId, required int userId}) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/invitations',
        data: {'eventId': eventId, 'userId': userId},
      );

      if (response.data['success'] == true) {
        return response.data['id'];
      } else {
        throw Exception(response.data['error'] ?? 'Error al crear la invitación');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error en la conexión');
    }
  }

  Future<int> bulkCreateInvitations({required int eventId, required List<int> userIds}) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/invitations/bulk',
        data: {'eventId': eventId, 'userIds': userIds.join(',')},
      );

      if (response.data['success'] == true) {
        return response.data['count'];
      } else {
        throw Exception(response.data['error'] ?? 'Error al crear las invitaciones');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error en la conexión');
    }
  }

  Future<int> inviteList({required int eventId, required int listId}) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/invitations/list',
        data: {'eventId': eventId, 'listId': listId},
      );

      if (response.data['success'] == true) {
        return response.data['count'];
      } else {
        throw Exception(response.data['error'] ?? 'Error al invitar a la lista');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error en la conexión');
    }
  }

  Future<bool> respondToInvitation({required int id, required InvitationStatus status}) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/invitations/$id/respond',
        data: {'status': status.toDbValue()},
      );

      return response.data['success'] == true;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error al responder a la invitación');
    }
  }

  Future<bool> deleteInvitation(int id) async {
    try {
      final response = await _apiClient.dio.delete('/api/invitations/$id');
      return response.data['success'] == true;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error al eliminar la invitación');
    }
  }

  Future<List<Invitation>> getInvitationsByUser() async {
    try {
      final response = await _apiClient.dio.get('/api/invitations/user');

      if (response.data['success'] == true) {
        final List<dynamic> invitationsJson = response.data['invitations'];
        return invitationsJson.map((json) => Invitation.fromJson(json)).toList();
      } else {
        throw Exception(response.data['error'] ?? 'Error al obtener las invitaciones');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error en la conexión');
    }
  }

  Future<List<Invitation>> getInvitationsByEvent(int eventId) async {
    try {
      final response = await _apiClient.dio.get('/api/events/$eventId/invitations');

      if (response.data['success'] == true) {
        final List<dynamic> invitationsJson = response.data['invitations'];
        return invitationsJson.map((json) => Invitation.fromJson(json)).toList();
      } else {
        throw Exception(response.data['error'] ?? 'Error al obtener las invitaciones');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error en la conexión');
    }
  }

  Future<List<Invitation>> getPendingInvitationsByUser() async {
    try {
      final response = await _apiClient.dio.get('/api/invitations/user/pending');

      if (response.data['success'] == true) {
        final List<dynamic> invitationsJson = response.data['invitations'];
        return invitationsJson.map((json) => Invitation.fromJson(json)).toList();
      } else {
        throw Exception(response.data['error'] ?? 'Error al obtener las invitaciones pendientes');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error en la conexión');
    }
  }
}

class InvitationService {
  final InvitationRepository _invitationRepository;
  final UserService _userService;

  InvitationService(this._invitationRepository, this._userService);

  Future<Invitation> getInvitationById(int id) async {
    return await _invitationRepository.getInvitationById(id);
  }

  Future<int> createInvitation({required int eventId, required int userId}) async {
    if (!await _userService.isOrganizer()) {
      throw Exception('Solo los organizadores pueden enviar invitaciones');
    }

    return await _invitationRepository.createInvitation(eventId: eventId, userId: userId);
  }

  Future<int> bulkCreateInvitations({required int eventId, required List<int> userIds}) async {
    if (!await _userService.isOrganizer()) {
      throw Exception('Solo los organizadores pueden enviar invitaciones en masa');
    }

    return await _invitationRepository.bulkCreateInvitations(eventId: eventId, userIds: userIds);
  }

  Future<int> inviteList({required int eventId, required int listId}) async {
    if (!await _userService.isOrganizer()) {
      throw Exception('Solo los organizadores pueden invitar listas completas');
    }

    return await _invitationRepository.inviteList(eventId: eventId, listId: listId);
  }

  Future<bool> respondToInvitation({required int id, required InvitationStatus status}) async {
    return await _invitationRepository.respondToInvitation(id: id, status: status);
  }

  Future<bool> deleteInvitation(int id) async {
    if (!await _userService.isOrganizer()) {
      throw Exception('Solo los organizadores pueden eliminar invitaciones');
    }

    return await _invitationRepository.deleteInvitation(id);
  }

  Future<List<Invitation>> getMyInvitations() async {
    return await _invitationRepository.getInvitationsByUser();
  }

  Future<List<Invitation>> getInvitationsByEvent(int eventId) async {
    if (!await _userService.isOrganizer()) {
      throw Exception('Solo los organizadores pueden ver las invitaciones de un evento');
    }

    return await _invitationRepository.getInvitationsByEvent(eventId);
  }

  Future<List<Invitation>> getMyPendingInvitations() async {
    return await _invitationRepository.getPendingInvitationsByUser();
  }

  Future<bool> acceptInvitation(int id) async {
    return await respondToInvitation(id: id, status: InvitationStatus.accepted);
  }

  Future<bool> declineInvitation(int id) async {
    return await respondToInvitation(id: id, status: InvitationStatus.declined);
  }
}
