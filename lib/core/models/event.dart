import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qrmark/core/config/theme.dart';
import 'package:qrmark/core/libs/api_client.dart';
import 'package:qrmark/core/models/location.dart';
import 'package:qrmark/core/models/user.dart';
import 'package:qrmark/core/utils/debug.dart';

enum EventStatus {
  upcoming,
  inProgress,
  completed,
  cancelled;

  static EventStatus fromString(String value) {
    final normalizedValue = value.toUpperCase().replaceAll('_', '');

    return EventStatus.values.firstWhere(
      (e) => e.name.toUpperCase().replaceAll('_', '') == normalizedValue,
      orElse: () => EventStatus.upcoming,
    );
  }

  String toDbValue() {
    switch (this) {
      case EventStatus.upcoming:
        return 'UPCOMING';
      case EventStatus.inProgress:
        return 'IN_PROGRESS';
      case EventStatus.completed:
        return 'COMPLETED';
      case EventStatus.cancelled:
        return 'CANCELLED';
    }
  }

  String get displayName {
    switch (this) {
      case EventStatus.upcoming:
        return 'Próximo';
      case EventStatus.inProgress:
        return 'En curso';
      case EventStatus.completed:
        return 'Completado';
      case EventStatus.cancelled:
        return 'Cancelado';
    }
  }

  Color get color {
    switch (this) {
      case EventStatus.upcoming:
        return AppColors.infoColor;
      case EventStatus.inProgress:
        return AppColors.successColor;
      case EventStatus.completed:
        return AppColors.warningColor;
      case EventStatus.cancelled:
        return AppColors.errorColor;
    }
  }
}

class Event {
  final int id;
  final String title;
  final String description;
  final int locationId;
  final DateTime startTime;
  final DateTime endTime;
  final EventStatus status;
  final bool isPublished;
  final int? capacity;
  final bool requiresCheckout;
  final int checkoutToleranceMinutes;
  final int organizerId;
  final bool isRecurring;
  final int? parentEventId;
  final String? recurrencePattern;
  final DateTime createdAt;
  final DateTime updatedAt;

  final Location? location;
  final User? organizer;

  const Event({
    required this.id,
    required this.title,
    required this.description,
    required this.locationId,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.isPublished,
    this.capacity,
    required this.requiresCheckout,
    this.checkoutToleranceMinutes = 0,
    required this.organizerId,
    this.isRecurring = false,
    this.parentEventId,
    this.recurrencePattern,
    required this.createdAt,
    required this.updatedAt,
    this.location,
    this.organizer,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      locationId: json['locationId'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      status: EventStatus.fromString(json['status']),
      isPublished: json['isPublished'] == 1 || json['isPublished'] == true,
      capacity: json['capacity'],
      requiresCheckout: json['requiresCheckout'] == 1 || json['requiresCheckout'] == true,
      checkoutToleranceMinutes: json['checkoutToleranceMinutes'] ?? 0,
      organizerId: json['organizerId'],
      isRecurring: json['isRecurring'] == 1 || json['isRecurring'] == true,
      parentEventId: json['parentEventId'],
      recurrencePattern: json['recurrencePattern'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      location: json['location'] != null ? Location.fromJson(json['location']) : null,
      organizer: json['organizer'] != null ? User.fromJson(json['organizer']) : null,
    );
  }

  // Example JSON:
  //  id: 3,
  //       title: "AAAAAAAAAAAAA",
  //       description: "AAAAAAAAAAA",
  //       startTime: 2025-04-15T22:03:14.000Z,
  //       endTime: 2025-04-15T22:03:16.000Z,
  //       status: "UPCOMING",
  factory Event.invitationFromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      locationId: 0, // Valor dummy o null si lo haces opcional
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      status: EventStatus.fromString(json['status'] ?? 'UPCOMING'),
      isPublished: false,
      requiresCheckout: false,
      checkoutToleranceMinutes: 0,
      organizerId: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'locationId': locationId,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'status': status.toDbValue(),
    'isPublished': isPublished ? 1 : 0,
    'capacity': capacity,
    'requiresCheckout': requiresCheckout ? 1 : 0,
    'checkoutToleranceMinutes': checkoutToleranceMinutes,
    'organizerId': organizerId,
    'isRecurring': isRecurring ? 1 : 0,
    'parentEventId': parentEventId,
    'recurrencePattern': recurrencePattern,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  Event copyWith({
    int? id,
    String? title,
    String? description,
    int? locationId,
    DateTime? startTime,
    DateTime? endTime,
    EventStatus? status,
    bool? isPublished,
    int? capacity,
    bool? requiresCheckout,
    int? checkoutToleranceMinutes,
    int? organizerId,
    bool? isRecurring,
    int? parentEventId,
    String? recurrencePattern,
    DateTime? createdAt,
    DateTime? updatedAt,
    Location? location,
    User? organizer,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      locationId: locationId ?? this.locationId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      isPublished: isPublished ?? this.isPublished,
      capacity: capacity ?? this.capacity,
      requiresCheckout: requiresCheckout ?? this.requiresCheckout,
      checkoutToleranceMinutes: checkoutToleranceMinutes ?? this.checkoutToleranceMinutes,
      organizerId: organizerId ?? this.organizerId,
      isRecurring: isRecurring ?? this.isRecurring,
      parentEventId: parentEventId ?? this.parentEventId,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      location: location ?? this.location,
      organizer: organizer ?? this.organizer,
    );
  }

  Duration get duration => endTime.difference(startTime);

  bool get isInProgress => status == EventStatus.inProgress;

  bool get isUpcoming => status == EventStatus.upcoming;

  bool get isFinished {
    final now = DateTime.now();
    final isPast = endTime.isBefore(now);
    final isCancelled = status == EventStatus.cancelled;

    debug('Event is finished: $isPast, cancelled: $isCancelled');
    return isPast || isCancelled;
  }

  String get formattedDate {
    if (startTime.day == endTime.day &&
        startTime.month == endTime.month &&
        startTime.year == endTime.year) {
      return DateFormat('d MMMM, yyyy', 'es_ES').format(startTime);
    } else {
      return '${DateFormat('d MMM', 'es_ES').format(startTime)} - ${DateFormat('d MMM, yyyy', 'es_ES').format(endTime)}';
    }
  }

  String get formattedTime {
    return '${DateFormat('HH:mm', 'es_ES').format(startTime)} - ${DateFormat('HH:mm', 'es_ES').format(endTime)}';
  }

  bool canGenerateCheckoutToken(DateTime currentTime) {
    if (!requiresCheckout) return false;

    final checkoutAvailableTime = endTime.subtract(Duration(minutes: checkoutToleranceMinutes));
    return currentTime.isAfter(checkoutAvailableTime) && currentTime.isBefore(endTime);
  }
}

class EventRepository {
  final ApiClient _api;

  EventRepository(this._api);

  Future<Event> getEventById(int id) async {
    try {
      final response = await _api.dio.get('/api/events/$id');

      if (response.data['success'] == true) {
        return Event.fromJson(response.data['event']);
      } else {
        throw Exception(response.data['error'] ?? 'Error al obtener el evento');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error en la conexión');
    }
  }

  Future<int> createEvent({
    required String title,
    required String description,
    required int locationId,
    required DateTime startTime,
    required DateTime endTime,
    bool? isPublished,
    int? capacity,
    bool? requiresCheckout,
    int? checkoutToleranceMinutes,
    bool? isRecurring,
    String? recurrencePattern,
  }) async {
    try {
      final response = await _api.dio.post(
        '/api/events',
        data: {
          'title': title,
          'description': description,
          'locationId': locationId,
          'startTime': startTime.toIso8601String(),
          'endTime': endTime.toIso8601String(),
          if (isPublished != null) 'isPublished': isPublished,
          if (capacity != null) 'capacity': capacity,
          if (requiresCheckout != null) 'requiresCheckout': requiresCheckout,
          if (checkoutToleranceMinutes != null)
            'checkoutToleranceMinutes': checkoutToleranceMinutes,
          if (isRecurring != null) 'isRecurring': isRecurring,
          if (recurrencePattern != null) 'recurrencePattern': recurrencePattern,
        },
      );

      if (response.data['success'] == true) {
        return response.data['id'];
      } else {
        throw Exception(response.data['error'] ?? 'Error al crear el evento');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error en la conexión');
    } catch (e) {
      throw Exception('Error al crear el evento: $e');
    }
  }

  Future<bool> updateEvent({
    required int id,
    String? title,
    String? description,
    int? locationId,
    DateTime? startTime,
    DateTime? endTime,
    bool? isPublished,
    int? capacity,
    bool? requiresCheckout,
    int? checkoutToleranceMinutes,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      if (title != null) data['title'] = title;
      if (description != null) data['description'] = description;
      if (locationId != null) data['locationId'] = locationId;
      if (startTime != null) data['startTime'] = startTime.toIso8601String();
      if (endTime != null) data['endTime'] = endTime.toIso8601String();
      if (isPublished != null) data['isPublished'] = isPublished;
      if (capacity != null) data['capacity'] = capacity;
      if (requiresCheckout != null) data['requiresCheckout'] = requiresCheckout;
      if (checkoutToleranceMinutes != null) {
        data['checkoutToleranceMinutes'] = checkoutToleranceMinutes;
      }

      final response = await _api.dio.put('/api/events/$id', data: data);

      return response.data['success'] == true;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error al actualizar el evento');
    }
  }

  Future<bool> deleteEvent(int id) async {
    try {
      final response = await _api.dio.delete('/api/events/$id');
      return response.data['success'] == true;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error al eliminar el evento');
    }
  }

  Future<List<Event>> getEventsByOrganizer(EventStatus? status) async {
    try {
      final response = await _api.dio.get(
        '/api/events/organizer',
        queryParameters: {'status': status?.toDbValue() ?? 'ALL'},
      );

      if (response.data['success'] == true) {
        final List<dynamic> eventsJson = response.data['events'];
        return eventsJson.map((json) => Event.fromJson(json)).toList();
      } else {
        throw Exception(response.data['error'] ?? 'Error al obtener los eventos del organizador');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error en la conexión');
    }
  }

  Future<List<Event>> getUpcomingEvents() async {
    try {
      final response = await _api.dio.get('/api/events/upcoming');

      if (response.data['success'] == true) {
        final List<dynamic> eventsJson = response.data['events'];
        return eventsJson.map((json) => Event.fromJson(json)).toList();
      } else {
        throw Exception(response.data['error'] ?? 'Error al obtener los eventos próximos');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error en la conexión');
    }
  }

  Future<List<Event>> getInProgressEvents() async {
    try {
      final response = await _api.dio.get('/api/events/in-progress');

      if (response.data['success'] == true) {
        final List<dynamic> eventsJson = response.data['events'];
        return eventsJson.map((json) => Event.fromJson(json)).toList();
      } else {
        throw Exception(response.data['error'] ?? 'Error al obtener los eventos en curso');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error en la conexión');
    }
  }

  Future<List<Event>> getUserEvents() async {
    try {
      final response = await _api.dio.get('/api/events/user');

      if (response.data['success'] == true) {
        final List<dynamic> eventsJson = response.data['events'];
        return eventsJson.map((json) => Event.fromJson(json)).toList();
      } else {
        throw Exception(response.data['error'] ?? 'Error al obtener los eventos del usuario');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error en la conexión');
    }
  }

  Future<bool> publishEvent(int id) async {
    try {
      final response = await _api.dio.post('/api/events/$id/publish');
      return response.data['success'] == true;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error al publicar el evento');
    }
  }

  Future<bool> cancelEvent(int id) async {
    try {
      final response = await _api.dio.post('/api/events/$id/cancel');
      return response.data['success'] == true;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error al cancelar el evento');
    }
  }
}

class EventService {
  final EventRepository _eventRepository;
  final UserService _userService;

  EventService(this._eventRepository, this._userService);

  Future<Event> getEventById(int id) async {
    return await _eventRepository.getEventById(id);
  }

  Future<int> createEvent({
    required String title,
    required String description,
    required int locationId,
    required DateTime startTime,
    required DateTime endTime,
    bool? isPublished,
    int? capacity,
    bool? requiresCheckout,
    int? checkoutToleranceMinutes,
    bool? isRecurring,
    String? recurrencePattern,
  }) async {
    if (!await _userService.isOrganizer()) {
      throw Exception('Solo los organizadores pueden crear eventos');
    }

    return await _eventRepository.createEvent(
      title: title,
      description: description,
      locationId: locationId,
      startTime: startTime,
      endTime: endTime,
      isPublished: isPublished,
      capacity: capacity,
      requiresCheckout: requiresCheckout,
      checkoutToleranceMinutes: checkoutToleranceMinutes,
      isRecurring: isRecurring,
      recurrencePattern: recurrencePattern,
    );
  }

  Future<bool> updateEvent({
    required int id,
    String? title,
    String? description,
    int? locationId,
    DateTime? startTime,
    DateTime? endTime,
    bool? isPublished,
    int? capacity,
    bool? requiresCheckout,
    int? checkoutToleranceMinutes,
  }) async {
    if (!await _userService.isOrganizer()) {
      throw Exception('Solo los organizadores pueden actualizar eventos');
    }

    return await _eventRepository.updateEvent(
      id: id,
      title: title,
      description: description,
      locationId: locationId,
      startTime: startTime,
      endTime: endTime,
      isPublished: isPublished,
      capacity: capacity,
      requiresCheckout: requiresCheckout,
      checkoutToleranceMinutes: checkoutToleranceMinutes,
    );
  }

  Future<bool> deleteEvent(int id) async {
    if (!await _userService.isOrganizer()) {
      throw Exception('Solo los organizadores pueden eliminar eventos');
    }

    return await _eventRepository.deleteEvent(id);
  }

  Future<List<Event>> getMyEvents(EventStatus? status) async {
    if (!await _userService.isOrganizer()) {
      throw Exception('Solo los organizadores pueden ver sus eventos creados');
    }

    return await _eventRepository.getEventsByOrganizer(status);
  }

  Future<List<Event>> getUpcomingEvents() async {
    return await _eventRepository.getUpcomingEvents();
  }

  Future<List<Event>> getInProgressEvents() async {
    return await _eventRepository.getInProgressEvents();
  }

  Future<List<Event>> getUserEvents() async {
    return await _eventRepository.getUserEvents();
  }

  Future<bool> publishEvent(int id) async {
    if (!await _userService.isOrganizer()) {
      throw Exception('Solo los organizadores pueden publicar eventos');
    }

    return await _eventRepository.publishEvent(id);
  }

  Future<bool> cancelEvent(int id) async {
    if (!await _userService.isOrganizer()) {
      throw Exception('Solo los organizadores pueden cancelar eventos');
    }

    return await _eventRepository.cancelEvent(id);
  }
}
