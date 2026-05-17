/// Staggered fade + slide entrance animation wrapper for list and grid items.
/// Wrap individual items with this to get a cascading reveal as data loads.
/// Respects MediaQuery.disableAnimations — renders statically when reduced motion is on.
library;

import 'package:flutter/material.dart';

/// Wraps [child] with a staggered fade-in + upward-slide entrance animation.
/// [index] drives the stagger delay: item 0 starts immediately, later items wait.
class AnimatedListItem extends StatefulWidget {
  const AnimatedListItem({
    super.key,
    required this.index,
    required this.child,
    this.baseDelay = const Duration(milliseconds: 55),
    this.duration = const Duration(milliseconds: 380),
  });

  final int index;
  final Widget child;

  /// Per-item delay multiplier — effective delay = index × baseDelay.
  final Duration baseDelay;

  /// Duration of the entrance animation for each item.
  final Duration duration;

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    final delay = widget.baseDelay * widget.index;
    if (delay == Duration.zero) {
      _ctrl.forward();
    } else {
      Future.delayed(delay, () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return widget.child;
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
