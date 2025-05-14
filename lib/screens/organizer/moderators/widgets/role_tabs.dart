import 'package:flutter/material.dart';
import 'package:qrmark/core/models/user.dart';

class UserRoleTabs extends StatefulWidget {
  final ValueChanged<UserRole> onStatusChanged;
  final UserRole initialStatus;

  const UserRoleTabs({super.key, required this.onStatusChanged, required this.initialStatus});

  @override
  State<UserRoleTabs> createState() => _UserRoleTabsState();
}

class _UserRoleTabsState extends State<UserRoleTabs> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // exclude 'organizer' role from the list of tabs
  final List<UserRole> _tabValues =
      UserRole.values.where((role) => role != UserRole.organizer).toList();

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
      tabs: _tabValues.map((status) => Tab(text: status.displayName)).toList(),
      dividerColor: Colors.transparent,
      indicatorSize: TabBarIndicatorSize.label,
    );
  }
}
