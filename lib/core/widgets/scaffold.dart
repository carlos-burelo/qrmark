import 'package:flutter/material.dart';

class Body extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool scrollable;
  final EdgeInsetsGeometry padding;

  const Body({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.scrollable = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 10.0),
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(
      padding: padding,
      child:
          scrollable
              ? SingleChildScrollView(physics: const BouncingScrollPhysics(), child: body)
              : body,
    );

    return Scaffold(
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: SafeArea(child: content),
    );
  }
}
