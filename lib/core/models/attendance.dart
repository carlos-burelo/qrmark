import 'package:dio/dio.dart';
import 'package:qrmark/core/libs/api_client.dart';
import 'package:qrmark/core/models/event.dart';
import 'package:qrmark/core/models/user.dart';

class Attendance {
  final int id;
  final int eventId;
  final int userId;
  final DateTime? checkinTime;
  final DateTime? checkoutTime;
  final DateTime createdAt;
  final Event? event;
  final User? user;
  const Attendance({
    required this.id,
    required this.eventId,
    required this.userId,
    this.checkinTime,
    this.checkoutTime,
    required this.createdAt,
    this.event,
    this.user,
  });
  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'],
      eventId: json['eventId'],
      userId: json['userId'],
      checkinTime: json['checkinTime'] != null ? DateTime.parse(json['checkinTime']) : null,
      checkoutTime: json['checkoutTime'] != null ? DateTime.parse(json['checkoutTime']) : null,
      createdAt: DateTime.parse(json['createdAt']),
      event: json['event'] != null ? Event.fromJson(json['event']) : null,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }
  Map<String, dynamic> toJson() => {
    'id': id,
    'eventId': eventId,
    'userId': userId,
    'checkinTime': checkinTime?.toIso8601String(),
    'checkoutTime': checkoutTime?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };
  Attendance copyWith({
    int? id,
    int? eventId,
    int? userId,
    DateTime? checkinTime,
    DateTime? checkoutTime,
    DateTime? createdAt,
    Event? event,
    User? user,
  }) {
    return Attendance(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      checkinTime: checkinTime ?? this.checkinTime,
      checkoutTime: checkoutTime ?? this.checkoutTime,
      createdAt: createdAt ?? this.createdAt,
      event: event ?? this.event,
      user: user ?? this.user,
    );
  }

  bool get hasCheckedIn => checkinTime != null;
  bool get hasCheckedOut => checkoutTime != null;
  bool get isComplete => hasCheckedIn && (hasCheckedOut || !(event?.requiresCheckout ?? false));
  String get status {
    if (!hasCheckedIn) return 'Pendiente';
    if (hasCheckedOut) return 'Completado';
    if (event?.requiresCheckout ?? false) return 'Check-in realizado';
    return 'Asistió';
  }
}

class AttendanceRepository {
  final ApiClient _apiClient;
  AttendanceRepository(this._apiClient);

  Future<List<Attendance>> getAttendancesByEvent(int eventId) async {
    try {
      final response = await _apiClient.dio.get('/api/events/$eventId/attendances');
      if (response.data['success'] == true) {
        final List<dynamic> attendancesJson = response.data['attendances'];
        return attendancesJson.map((json) => Attendance.fromJson(json)).toList();
      } else {
        throw Exception(response.data['error'] ?? 'Error al obtener las asistencias');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error en la conexión');
    }
  }

  Future<List<Attendance>> getAttendancesByUser() async {
    try {
      final response = await _apiClient.dio.get('/api/attendances/user');
      if (response.data['success'] == true) {
        final List<dynamic> attendancesJson = response.data['attendances'];
        return attendancesJson.map((json) => Attendance.fromJson(json)).toList();
      } else {
        throw Exception(response.data['error'] ?? 'Error al obtener las asistencias');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error en la conexión');
    }
  }

  Future<Map<String, dynamic>> getAttendanceStats(int eventId) async {
    try {
      final response = await _apiClient.dio.get('/api/events/$eventId/stats');
      if (response.data['success'] == true) {
        return response.data['stats'];
      } else {
        throw Exception(response.data['error'] ?? 'Error al obtener las estadísticas');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error en la conexión');
    }
  }

  Future<Map<String, dynamic>> processQR(String token) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/attendances/process-qr',
        data: {'token': token},
      );
      return {
        'success': response.data['success'] ?? false,
        'message': response.data['message'] ?? 'Procesamiento completado',
      };
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error al procesar el código QR');
    }
  }

  Future<String> generateCheckinQR(int eventId) async {
    try {
      final response = await _apiClient.dio.get('/api/events/$eventId/checkin-qr');
      if (response.data['success'] == true) {
        return response.data['token'];
      } else {
        throw Exception(response.data['error'] ?? 'Error al generar el QR de check-in');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error en la conexión');
    }
  }

  Future<String> generateCheckoutQR(int eventId) async {
    try {
      final response = await _apiClient.dio.get('/api/events/$eventId/checkout-qr');
      if (response.data['success'] == true) {
        return response.data['token'];
      } else {
        throw Exception(response.data['error'] ?? 'Error al generar el QR de check-out');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error en la conexión');
    }
  }
}

class AttendanceService {
  final AttendanceRepository _attendanceRepository;
  final UserService _userService;
  AttendanceService(this._attendanceRepository, this._userService);
  Future<List<Attendance>> getAttendancesByEvent(int eventId) async {
    if (!(await _userService.isOrganizer() || await _userService.isModerator())) {
      throw Exception('No tienes permisos para ver las asistencias');
    }
    return await _attendanceRepository.getAttendancesByEvent(eventId);
  }

  Future<List<Attendance>> getMyAttendances() async {
    return await _attendanceRepository.getAttendancesByUser();
  }

  Future<Map<String, dynamic>> getAttendanceStats(int eventId) async {
    if (!(await _userService.isOrganizer() || await _userService.isModerator())) {
      throw Exception('No tienes permisos para ver las estadísticas');
    }
    return await _attendanceRepository.getAttendanceStats(eventId);
  }

  Future<Map<String, dynamic>> processQR(String token) async {
    if (!(await _userService.canScanQR())) {
      throw Exception('No tienes permisos para procesar códigos QR');
    }
    return await _attendanceRepository.processQR(token);
  }

  Future<String> generateCheckinQR(int eventId) async {
    return await _attendanceRepository.generateCheckinQR(eventId);
  }

  Future<String> generateCheckoutQR(int eventId) async {
    return await _attendanceRepository.generateCheckoutQR(eventId);
  }

  Future<bool> eventRequiresCheckout(Attendance attendance) {
    return Future.value(attendance.event?.requiresCheckout ?? false);
  }

  Future<Map<String, dynamic>> prepareQRData(int eventId, bool isCheckout) async {
    final token = isCheckout ? await generateCheckoutQR(eventId) : await generateCheckinQR(eventId);
    final event =
        (await getAttendancesByEvent(eventId)).firstWhere((a) => a.eventId == eventId).event;
    return {
      'token': token,
      'eventTitle': event?.title ?? 'Evento',
      'type': isCheckout ? 'checkout' : 'checkin',
    };
  }
}
