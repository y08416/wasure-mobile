import 'package:flutter/material.dart';

class AnimatedReminderCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const AnimatedReminderCard({
    Key? key,
    required this.child,
    required this.onTap,
  }) : super(key: key);

  @override
  _AnimatedReminderCardState createState() => _AnimatedReminderCardState();
}

class _AnimatedReminderCardState extends State<AnimatedReminderCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        transform: Matrix4.identity()
          ..scale(_isPressed ? 1.03 : 1.0),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}