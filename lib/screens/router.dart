import 'package:flutter/material.dart';
import 'package:qrmark/core/models/user.dart';
import 'package:qrmark/screens/attendee/attendee_tabs.dart';
import 'package:qrmark/screens/attendee/events/events_tab.dart';
import 'package:qrmark/screens/attendee/invitations/details/invitation_details.dart';
import 'package:qrmark/screens/attendee/invitations/qr/qr_screen.dart';
import 'package:qrmark/screens/auth/login/login_screen.dart';
import 'package:qrmark/screens/auth/profile/profile_screen.dart';
import 'package:qrmark/screens/auth/register/register_screen.dart';
import 'package:qrmark/screens/auth/splash/splash_screen.dart';
import 'package:qrmark/screens/moderator/events/events_tab.dart';
import 'package:qrmark/screens/moderator/events/scan/scan_qr.dart';
import 'package:qrmark/screens/moderator/moderator_tabs.dart';
import 'package:qrmark/screens/moderator/stats/stats_tab.dart';
import 'package:qrmark/screens/organizer/distribution_list/distribution_list_tab.dart';
import 'package:qrmark/screens/organizer/distribution_list/members/add_members.dart';
import 'package:qrmark/screens/organizer/events/%5Bid%5D/details/event_details_screen.dart';
import 'package:qrmark/screens/organizer/events/create/events_create_screen.dart';
import 'package:qrmark/screens/organizer/events/events_tab.dart';
import 'package:qrmark/screens/organizer/invitations/invitations_tab.dart';
import 'package:qrmark/screens/organizer/invitations/send-invitations/send_invitation_screen.dart';
import 'package:qrmark/screens/organizer/moderators/moderator_tab.dart';
import 'package:qrmark/screens/organizer/organizer_tabs.dart';

class AppRouter {
  // Expone las rutas de manera estática para fácil acceso
  static const String splashPath = SplashScreen.path;
  static const String loginPath = LoginScreen.path;
  static const String registerPath = RegisterScreen.path;
  static const String profilePath = ProfileScreen.path;

  static final ROUTES = {
    SplashScreen.path: (c) => const SplashScreen(),
    LoginScreen.path: (c) => const LoginScreen(),
    RegisterScreen.path: (c) => const RegisterScreen(),
    ProfileScreen.path: (c) => const ProfileScreen(),
    // attendee
    AttendeeTabs().path: (c) => const AttendeeTabs(),
    AttendeeEventsTab().path: (c) => const AttendeeEventsTab(),
    // organizer
    OrganizerTabs().path: (c) => const OrganizerTabs(),
    OrganizerEventsTab().path: (c) => const OrganizerEventsTab(),
    OrganizerInvitationsTab().path: (c) => const OrganizerInvitationsTab(),
    OrganizerModeratorsTab().path: (c) => const OrganizerModeratorsTab(),
    OrganizerDistributionListTab().path: (c) => const OrganizerDistributionListTab(),
    OrganizerEventCreateScreen.path: (c) => const OrganizerEventCreateScreen(),
    OrganizerEventDetailsScreen.path: (c) {
      final args = ModalRoute.of(c)!.settings.arguments as Map<String, dynamic>;
      return OrganizerEventDetailsScreen(eventId: args['eventId']);
    },

    OrganizerSendInvitationsScreen.path: (c) {
      final args = ModalRoute.of(c)!.settings.arguments as Map<String, dynamic>;
      return OrganizerSendInvitationsScreen(eventId: args['eventId']);
    },

    OrganizerManageMembers.path: (c) {
      final args = ModalRoute.of(c)!.settings.arguments as Map<String, dynamic>;
      return OrganizerManageMembers(listId: args['listId']);
    },

    AttendeeInvitationDetails.path: (c) {
      final args = ModalRoute.of(c)!.settings.arguments as Map<String, dynamic>;
      return AttendeeInvitationDetails(
        eventId: args['eventId'],
        invitationId: args['invitationId'],
      );
    },

    AttendeeQRScreen.path: (c) {
      final args = ModalRoute.of(c)!.settings.arguments as Map<String, dynamic>;
      return AttendeeQRScreen(eventId: args['eventId']);
    },

    // moderator
    ModeratorTabs().path: (c) => const ModeratorTabs(),
    ModeratorEventsTab().path: (c) => const ModeratorEventsTab(),
    ModeratorStatsTab().path: (c) => const ModeratorStatsTab(),
    ModeratorScanQrScreen.path: (c) {
      final args = ModalRoute.of(c)!.settings.arguments as Map<String, dynamic>;
      return ModeratorScanQrScreen(eventId: args['eventId']);
    },
  };

  static router() {
    return ROUTES;
  }

  static String getRouter(UserRole role) {
    switch (role) {
      case UserRole.user:
        return AttendeeTabs().path;
      case UserRole.moderator:
        return ModeratorTabs().path;
      default:
        return OrganizerTabs().path;
    }
  }
}
