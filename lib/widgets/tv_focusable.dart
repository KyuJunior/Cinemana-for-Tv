import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/tv_theme.dart';

class TVFocusable extends StatefulWidget {
  final Widget Function(BuildContext context, bool isFocused) builder;
  final VoidCallback? onPressed;
  final ValueChanged<bool>? onFocusChange;
  final VoidCallback? onKeyLeft;
  final VoidCallback? onKeyRight;
  final FocusNode? focusNode;
  final bool autoFocus;
  final double scaleOnFocus;
  final BorderRadius? borderRadius;
  final bool showGlow;
  final Color? glowColor;

  const TVFocusable({
    super.key,
    required this.builder,
    this.onPressed,
    this.onFocusChange,
    this.onKeyLeft,
    this.onKeyRight,
    this.focusNode,
    this.autoFocus = false,
    this.scaleOnFocus = 1.05,
    this.borderRadius,
    this.showGlow = true,
    this.glowColor,
  });

  @override
  State<TVFocusable> createState() => _TVFocusableState();
}

class _TVFocusableState extends State<TVFocusable> {
  late FocusNode _node;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _node = widget.focusNode ?? FocusNode();
    _node.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(TVFocusable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      _node.removeListener(_handleFocusChange);
      if (oldWidget.focusNode == null) {
        _node.dispose();
      }
      _node = widget.focusNode ?? FocusNode();
      _node.addListener(_handleFocusChange);
    }
  }

  @override
  void dispose() {
    _node.removeListener(_handleFocusChange);
    if (widget.focusNode == null) {
      _node.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    if (_isFocused != _node.hasFocus) {
      setState(() {
        _isFocused = _node.hasFocus;
      });
      widget.onFocusChange?.call(_isFocused);
      if (_isFocused) {
        // Auto scroll into viewport when focused
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Scrollable.ensureVisible(
              context,
              alignment: 0.5,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
            );
          }
        });
      }
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (widget.onKeyLeft != null && event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        widget.onKeyLeft!();
        return KeyEventResult.handled;
      }
      if (widget.onKeyRight != null && event.logicalKey == LogicalKeyboardKey.arrowRight) {
        widget.onKeyRight!();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.select ||
          event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.space ||
          event.logicalKey == LogicalKeyboardKey.numpadEnter ||
          event.logicalKey == LogicalKeyboardKey.gameButtonA) {
        widget.onPressed?.call();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext dynamicContext) {
    final effectiveBorderRadius = widget.borderRadius ?? BorderRadius.circular(12);
    final glow = widget.glowColor ?? TVColors.focusGlow;

    return Focus(
      focusNode: _node,
      autofocus: widget.autoFocus,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: () {
          _node.requestFocus();
          widget.onPressed?.call();
        },
        child: AnimatedScale(
          scale: _isFocused ? widget.scaleOnFocus : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.fastOutSlowIn,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.fastOutSlowIn,
            decoration: BoxDecoration(
              borderRadius: effectiveBorderRadius,
              boxShadow: _isFocused && widget.showGlow
                  ? [
                      BoxShadow(
                        color: glow,
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: widget.builder(context, _isFocused),
          ),
        ),
      ),
    );
  }
}
