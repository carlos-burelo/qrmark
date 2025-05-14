import 'package:flutter/material.dart';
import 'package:qrmark/core/widgets/scaffold.dart';

mixin ScreenMetadata {
  IconData get icon;
  String get label;
  String get path;
}

abstract class Screen extends StatelessWidget with ScreenMetadata {
  const Screen({super.key});
}

abstract class ScreenWithState extends StatefulWidget with ScreenMetadata {
  const ScreenWithState({super.key});
}

class TabContainer extends StatefulWidget {
  final List<Widget> screens;
  final int initialIndex;

  const TabContainer({super.key, required this.screens, this.initialIndex = 0});

  @override
  TabContainerState createState() => TabContainerState();
}

class TabContainerState extends State<TabContainer> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _tabController = TabController(
      length: widget.screens.length,
      vsync: this,
      initialIndex: _currentIndex,
    );
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _currentIndex = _tabController.index;
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Body(
      padding: const EdgeInsets.all(0),
      body: IndexedStack(
        index: _currentIndex,
        sizing: StackFit.expand,
        children:
            widget.screens
                .map(
                  (screen) =>
                      KeyedSubtree(key: ValueKey(widget.screens.indexOf(screen)), child: screen),
                )
                .toList(),
      ),
      bottomNavigationBar: SizedBox(
        height: 70,
        child: BottomNavigationBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          currentIndex: _currentIndex,
          onTap: (index) {
            _tabController.animateTo(index);
            setState(() {
              _currentIndex = index;
            });
          },
          items:
              widget.screens.map((screen) {
                return BottomNavigationBarItem(
                  icon: Icon((screen as dynamic).icon),
                  label: (screen as dynamic).label,
                );
              }).toList(),
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }
}
