import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class SwitchRow extends StatelessWidget {
  final String label;
  final String? helper;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool showDivider;

  const SwitchRow({
    super.key,
    required this.label,
    this.helper,
    required this.value,
    this.onChanged,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final animDuration = disableAnimations ? Duration.zero : AppMotion.fast;
    final isEnabled = onChanged != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: isEnabled ? () => onChanged!(!value) : null,
          splashColor: AppColors.transparent,
          highlightColor: AppColors.petrolTint,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.x16,
              vertical: AppSpace.x12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: isEnabled
                            ? AppText.body
                            : AppText.body.copyWith(color: AppColors.muted),
                      ),
                      if (helper != null && helper!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          helper!,
                          style: AppText.secondary,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.x16),
                // Custom toggle track and thumb
                AnimatedContainer(
                  duration: animDuration,
                  width: 44,
                  height: 24,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: !isEnabled
                        ? AppColors.disabledBg
                        : (value ? AppColors.petrol : AppColors.outline),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: AnimatedAlign(
                    duration: animDuration,
                    alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 1,
            color: AppColors.hairline,
            indent: AppSpace.x16,
          ),
      ],
    );
  }
}

