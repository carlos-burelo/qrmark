import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:qrmark/core/libs/api_client.dart';
import 'package:qrmark/core/models/attendance.dart';
import 'package:qrmark/core/models/auth.dart';
import 'package:qrmark/core/models/distribution_list.dart';
import 'package:qrmark/core/models/event.dart';
import 'package:qrmark/core/models/invitation.dart';
import 'package:qrmark/core/models/location.dart';
import 'package:qrmark/core/models/user.dart';

class ServiceFacade {
  ServiceFacade._();
  static final ServiceFacade _instance = ServiceFacade._();
  static ServiceFacade get I => _instance;

  AuthService get auth => ServiceLocator.I.get<AuthService>();
  UserService get user => ServiceLocator.I.get<UserService>();
  EventService get event => ServiceLocator.I.get<EventService>();
  LocationService get location => ServiceLocator.I.get<LocationService>();
  AttendanceService get attendance => ServiceLocator.I.get<AttendanceService>();
  InvitationService get invitation => ServiceLocator.I.get<InvitationService>();
  DistributionListService get distributionList => ServiceLocator.I.get<DistributionListService>();
}

final service = ServiceFacade.I;

class ServiceLocator {
  ServiceLocator._();
  static final ServiceLocator _instance = ServiceLocator._();
  static ServiceLocator get I => _instance;

  final Map<Type, Object> _instances = {};

  void register<T extends Object>(T instance) {
    _instances[T] = instance;
  }

  T get<T extends Object>() {
    final instance = _instances[T];
    if (instance == null) {
      throw Exception('No se encontró registro para $T');
    }
    return instance as T;
  }
}

void initializeServices() {
  final locator = ServiceLocator.I;
  final secureStorage = const FlutterSecureStorage();
  final apiClient = ApiClient(baseUrl: 'http://localhost:5000', secureStorage: secureStorage);

  final authInterceptor = AuthInterceptor(secureStorage);
  apiClient.dio.interceptors.add(authInterceptor);

  final authRepo = AuthRepository(apiClient);
  final userRepo = UserRepository(apiClient);
  final eventRepo = EventRepository(apiClient);
  final locationRepo = LocationRepository(apiClient);
  final attendanceRepo = AttendanceRepository(apiClient);
  final invitationRepo = InvitationRepository(apiClient);
  final distributionListRepo = DistributionListRepository(apiClient);

  final authService = AuthService(authRepo, secureStorage);

  final userService = UserService(userRepo, authService);

  final eventService = EventService(eventRepo, userService);
  final locationService = LocationService(locationRepo, userService);
  final attendanceService = AttendanceService(attendanceRepo, userService);
  final invitationService = InvitationService(invitationRepo, userService);
  final distributionListService = DistributionListService(distributionListRepo, userService);

  locator.register<AuthService>(authService);
  locator.register<UserService>(userService);
  locator.register<EventService>(eventService);
  locator.register<LocationService>(locationService);
  locator.register<AttendanceService>(attendanceService);
  locator.register<InvitationService>(invitationService);
  locator.register<DistributionListService>(distributionListService);
}
