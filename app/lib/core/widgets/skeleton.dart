import 'package:flutter/widgets.dart';
import '../theme/tokens.dart';

class SkeletonBlock extends StatefulWidget {
  final double? width;
  final double height;
  final BorderRadiusGeometry borderRadius;

  const SkeletonBlock({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = AppRadius.chip,
  });

  @override
  State<SkeletonBlock> createState() => _SkeletonBlockState();
}

class _SkeletonBlockState extends State<SkeletonBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.shimmer,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment(-1.5 + 3.0 * value, -0.2),
              end: Alignment(-0.5 + 3.0 * value, 0.2),
              colors: const [
                AppColors.skeletonBase,
                AppColors.skeletonHighlight,
                AppColors.skeletonBase,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

class SkeletonList extends StatelessWidget {
  final int itemCount;

  const SkeletonList({
    super.key,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(itemCount, (index) {
        return const Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpace.x16,
            vertical: AppSpace.x12,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SkeletonBlock(
                width: AppSize.tile,
                height: AppSize.tile,
                borderRadius: AppRadius.tile,
              ),
              SizedBox(width: AppSpace.x12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FractionallySizedBox(
                      widthFactor: 0.60,
                      child: SkeletonBlock(
                        height: 14,
                      ),
                    ),
                    SizedBox(height: AppSpace.x8),
                    FractionallySizedBox(
                      widthFactor: 0.40,
                      child: SkeletonBlock(
                        height: 14,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: AppSpace.x12),
              SkeletonBlock(
                width: 56,
                height: 16,
              ),
            ],
          ),
        );
      }),
    );
  }
}

