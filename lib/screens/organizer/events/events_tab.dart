import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qrmark/core/libs/service_hub.dart';
import 'package:qrmark/core/models/event.dart';
import 'package:qrmark/core/utils/navigation.dart';
import 'package:qrmark/core/widgets/appbar.dart';
import 'package:qrmark/core/widgets/await.dart';
import 'package:qrmark/core/widgets/event_card.dart';
import 'package:qrmark/core/widgets/scaffold.dart';
import 'package:qrmark/core/widgets/tabs.dart';
import 'package:qrmark/screens/organizer/events/%5Bid%5D/details/event_details_screen.dart';
import 'package:qrmark/screens/organizer/events/create/events_create_screen.dart';
import 'package:qrmark/screens/organizer/events/widgets/event_actions.dart';
import 'package:qrmark/screens/organizer/events/widgets/event_status_tabs.dart';

class OrganizerEventsTab extends ScreenWithState {
  final IconData icon = LucideIcons.calendarRange;
  final String label = 'Eventos';
  final String path = '/organizer/events';
  const OrganizerEventsTab({super.key});

  @override
  State<OrganizerEventsTab> createState() => OrganizerEventsScreenState();
}

class OrganizerEventsScreenState extends State<OrganizerEventsTab> {
  EventStatus? _selectedStatus;
  Key _listKey = UniqueKey();

  Future<List<Event>> _getFilteredEvents() async {
    final events = await service.event.getMyEvents(_selectedStatus);

    if (_selectedStatus == null) {
      return events;
    }

    return events.where((event) {
      return event.status == _selectedStatus;
    }).toList();
  }

  void _onStatusChanged(EventStatus? status) {
    setState(() {
      _selectedStatus = status;
      _listKey = UniqueKey();
    });
  }

  void _onRefresh() {
    setState(() {
      _listKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Body(
      appBar: AppBarWidget(title: 'Eventos'),
      body: Column(
        children: [
          EventStatusTabs(onStatusChanged: _onStatusChanged, initialStatus: _selectedStatus),
          Expanded(
            child: SearchableAsyncList(
              key: _listKey,
              wait: _getFilteredEvents,
              enableSearch: true,
              enablePullToRefresh: true,
              emptyBuilder: Center(
                child: Text(
                  _selectedStatus == null
                      ? 'No tienes eventos creados.'
                      : 'No tienes eventos ${(_selectedStatus?.displayName)}.',
                ),
              ),
              builder: (ctx, event, index) {
                return EventCard(
                  event: event,
                  actions:
                      EventActions(event: event, context: context, onRefresh: _onRefresh).build(),
                  onTap: () {
                    Navigate.to(OrganizerEventDetailsScreen.path, arguments: {'eventId': event.id});
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'create-event',
        onPressed: () async {
          final result = await Navigate.to(OrganizerEventCreateScreen.path);
          if (result == true) {
            _onRefresh();
          }
        },
        tooltip: 'Crear evento',
        child: const Icon(LucideIcons.plus),
      ),
    );
  }
}
