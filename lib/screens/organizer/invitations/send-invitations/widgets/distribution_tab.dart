import 'package:flutter/material.dart';
import 'package:qrmark/core/models/distribution_list.dart';

class DistributionTabs extends StatefulWidget {
  final ValueChanged<DistributionMode?> onStatusChanged;
  final DistributionMode? initialStatus;

  const DistributionTabs({super.key, required this.onStatusChanged, this.initialStatus});

  @override
  State<DistributionTabs> createState() => _DistributionTabsState();
}

class _DistributionTabsState extends State<DistributionTabs> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<DistributionMode?> _tabValues = DistributionMode.values;

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
      tabs: _tabValues.map((status) => Tab(icon: Icon(status!.icon), text: status.label)).toList(),
      dividerColor: Colors.transparent,
      indicatorSize: TabBarIndicatorSize.label,
    );
  }
}
