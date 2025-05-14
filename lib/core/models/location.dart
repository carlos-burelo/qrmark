import 'package:dio/dio.dart';
import 'package:qrmark/core/libs/api_client.dart';
import 'package:qrmark/core/models/user.dart';

class Location {
  final int id;
  final String name;
  final String? address;
  final String? mapsUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Location({
    required this.id,
    required this.name,
    this.address,
    this.mapsUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      mapsUrl: json['mapsUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'mapsUrl': mapsUrl,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  Location copyWith({
    int? id,
    String? name,
    String? address,
    String? mapsUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Location(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      mapsUrl: mapsUrl ?? this.mapsUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get hasMapLink => mapsUrl != null && mapsUrl!.isNotEmpty;
}

class LocationRepository {
  final ApiClient _apiClient;

  LocationRepository(this._apiClient);

  Future<Location> getLocationById(int id) async {
    try {
      final response = await _apiClient.dio.get('/api/locations/$id');

      if (response.data['success'] == true) {
        return Location.fromJson(response.data['location']);
      } else {
        throw Exception(response.data['error'] ?? 'Error al obtener la ubicación');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error en la conexión');
    }
  }

  Future<int> createLocation({required String name, String? address, String? mapsUrl}) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/locations',
        data: {
          'name': name,
          if (address != null) 'address': address,
          if (mapsUrl != null) 'mapsUrl': mapsUrl,
        },
      );

      if (response.data['success'] == true) {
        return response.data['id'];
      } else {
        throw Exception(response.data['error'] ?? 'Error al crear la ubicación');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error en la conexión');
    }
  }

  Future<bool> updateLocation({
    required int id,
    String? name,
    String? address,
    String? mapsUrl,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      if (name != null) data['name'] = name;
      if (address != null) data['address'] = address;
      if (mapsUrl != null) data['mapsUrl'] = mapsUrl;

      final response = await _apiClient.dio.put('/api/locations/$id', data: data);

      return response.data['success'] == true;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error al actualizar la ubicación');
    }
  }

  Future<bool> deleteLocation(int id) async {
    try {
      final response = await _apiClient.dio.delete('/api/locations/$id');
      return response.data['success'] == true;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error al eliminar la ubicación');
    }
  }

  Future<List<Location>> getAllLocations() async {
    try {
      final response = await _apiClient.dio.get('/api/locations');

      if (response.data['success'] == true) {
        final List<dynamic> locationsJson = response.data['locations'];
        return locationsJson.map((json) => Location.fromJson(json)).toList();
      } else {
        throw Exception(response.data['error'] ?? 'Error al obtener las ubicaciones');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error en la conexión');
    }
  }
}

class LocationService {
  final LocationRepository _locationRepository;
  final UserService _userService;

  LocationService(this._locationRepository, this._userService);

  Future<Location> getLocationById(int id) async {
    return await _locationRepository.getLocationById(id);
  }

  Future<int> createLocation({required String name, String? address, String? mapsUrl}) async {
    if (!await _userService.isOrganizer()) {
      throw Exception('Solo los organizadores pueden crear ubicaciones');
    }

    return await _locationRepository.createLocation(name: name, address: address, mapsUrl: mapsUrl);
  }

  Future<bool> updateLocation({
    required int id,
    String? name,
    String? address,
    String? mapsUrl,
  }) async {
    if (!await _userService.isOrganizer()) {
      throw Exception('Solo los organizadores pueden actualizar ubicaciones');
    }

    return await _locationRepository.updateLocation(
      id: id,
      name: name,
      address: address,
      mapsUrl: mapsUrl,
    );
  }

  Future<bool> deleteLocation(int id) async {
    if (!await _userService.isOrganizer()) {
      throw Exception('Solo los organizadores pueden eliminar ubicaciones');
    }

    return await _locationRepository.deleteLocation(id);
  }

  Future<List<Location>> getAllLocations() async {
    return await _locationRepository.getAllLocations();
  }
}
