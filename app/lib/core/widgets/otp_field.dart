import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/tokens.dart';

class OtpField extends StatefulWidget {
  final int length;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool hasError;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;

  const OtpField({
    super.key,
    this.length = 6,
    this.controller,
    this.focusNode,
    this.hasError = false,
    this.autofocus = true,
    this.onChanged,
    this.onCompleted,
  });

  @override
  State<OtpField> createState() => _OtpFieldState();
}

class _OtpFieldState extends State<OtpField> with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isSelfController = false;
  bool _isSelfFocusNode = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController();
      _isSelfController = true;
    }

    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _isSelfFocusNode = true;
    }

    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);

    _shakeController = AnimationController(
      vsync: this,
      duration: AppMotion.shake,
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: -3.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -3.0, end: 3.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 3.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));

    if (widget.hasError) {
      _shakeController.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(covariant OtpField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.hasError && widget.hasError) {
      final disableMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (!disableMotion) {
        _shakeController.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    if (_isSelfController) {
      _controller.dispose();
    }
    if (_isSelfFocusNode) {
      _focusNode.dispose();
    }
    _shakeController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
    widget.onChanged?.call(_controller.text);
    if (_controller.text.length == widget.length) {
      widget.onCompleted?.call(_controller.text);
    }
  }

  void _onFocusChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final text = _controller.text;
    final isFocused = _focusNode.hasFocus;

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: Stack(
        children: [
          // Visual Boxes
          Row(
            children: List.generate(widget.length, (index) {
              final isBoxFilled = index < text.length;
              final isCurrent = isFocused && index == text.length;
              final digit = isBoxFilled ? text[index] : '';

              Color borderColor;
              double borderWidth;

              if (widget.hasError) {
                borderColor = AppColors.overdueFg;
                borderWidth = 2.0;
              } else if (isCurrent) {
                borderColor = AppColors.petrol;
                borderWidth = 2.0;
              } else {
                borderColor = AppColors.outline;
                borderWidth = 1.0;
              }

              return Expanded(
                child: Container(
                  height: 56,
                  margin: EdgeInsets.only(
                    right: index == widget.length - 1 ? 0 : AppSpace.x8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.button,
                    border: Border.all(
                      color: borderColor,
                      width: borderWidth,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    digit,
                    style: AppText.display,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }),
          ),
          // Hidden TextField over the boxes
          Positioned.fill(
            child: Opacity(
              opacity: 0.0,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: widget.autofocus,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(widget.length),
                ],
                enableInteractiveSelection: false,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

