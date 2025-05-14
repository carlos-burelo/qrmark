import 'package:flutter/material.dart';
import 'package:qrmark/core/models/event.dart';

class EventStatusTabs extends StatefulWidget {
  final ValueChanged<EventStatus?> onStatusChanged;
  final EventStatus? initialStatus;

  const EventStatusTabs({super.key, required this.onStatusChanged, this.initialStatus});

  @override
  State<EventStatusTabs> createState() => _EventStatusTabsState();
}

class _EventStatusTabsState extends State<EventStatusTabs> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<EventStatus?> _tabValues = [null, ...EventStatus.values];

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: _tabValues.length,
      vsync: this,
      initialIndex: _getInitialIndex(),
    );

    _tabController.addListener(_handleTabSelection);
  }

  int _getInitialIndex() {
    if (widget.initialStatus == null) return 0;
    return !_tabValues.contains(widget.initialStatus)
        ? 0
        : _tabValues.indexOf(widget.initialStatus);
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;
    final status = _tabValues[_tabController.index];
    widget.onStatusChanged(status);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: _tabController,
      isScrollable: false,
      tabs:
          _tabValues
              .map((status) => Tab(text: status != null ? status.displayName : "Todos"))
              .toList(),
      dividerColor: Colors.transparent,
      indicatorSize: TabBarIndicatorSize.label,
    );
  }
}
