import 'package:flutter/material.dart';

class CustomOverlay extends StatefulWidget {
  final Widget child;

  CustomOverlay({Key? key, required this.child}) : super(key: key);

  @override
  _CustomOverlayState createState() => _CustomOverlayState();

  static OverlayEntry? _overlay;

  static void start(BuildContext context, Widget overlayWidget) {
    if (_overlay != null) return;
    _overlay = OverlayEntry(builder: (BuildContext context) {
      return overlayWidget;
    });
    Overlay.of(context).insert(_overlay!);
  }

  static void stop() {
    if (_overlay == null) return;
    _overlay!.remove();
    _overlay = null;
  }
}

class _CustomOverlayState extends State<CustomOverlay> {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
