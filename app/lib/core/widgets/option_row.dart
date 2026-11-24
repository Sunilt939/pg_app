import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class OptionRowItem<T> {
  final T value;
  final String label;
  final bool isEnabled;
  final String? subtitle;

  const OptionRowItem({
    required this.value,
    required this.label,
    this.isEnabled = true,
    this.subtitle,
  });
}

class OptionRow<T> extends StatelessWidget {
  final List<OptionRowItem<T>> options;
  final T? selectedValue;
  final ValueChanged<T>? onChanged;

  const OptionRow({
    super.key,
    required this.options,
    this.selectedValue,
    this.onChanged,
  });

  Widget _buildItem(OptionRowItem<T> item) {
    final isSelected = item.value == selectedValue;
    final isEnabled = item.isEnabled;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isEnabled ? () => onChanged?.call(item.value) : null,
      child: Container(
        height: item.subtitle != null ? 52 : 44,
        decoration: BoxDecoration(
          color: !isEnabled
              ? AppColors.disabledBg
              : isSelected
                  ? AppColors.petrolTint
                  : AppColors.surface,
          borderRadius: AppRadius.button,
          border: Border.all(
            color: !isEnabled
                ? AppColors.hairline
                : isSelected
                    ? AppColors.petrol
                    : AppColors.outline,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.x8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              item.label,
              style: !isEnabled
                  ? AppText.label.copyWith(color: AppColors.muted)
                  : isSelected
                      ? AppText.buttonSmall.copyWith(color: AppColors.petrol)
                      : AppText.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (item.subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                item.subtitle!,
                style: AppText.caption,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();

    if (options.length <= 3) {
      return Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpace.x8),
            Expanded(child: _buildItem(options[i])),
          ],
        ],
      );
    }

    // 2-column grid when more than 3 options
    final rows = <Widget>[];
    for (var i = 0; i < options.length; i += 2) {
      final first = options[i];
      final second = (i + 1 < options.length) ? options[i + 1] : null;

      if (rows.isNotEmpty) {
        rows.add(const SizedBox(height: AppSpace.x8));
      }

      rows.add(
        Row(
          children: [
            Expanded(child: _buildItem(first)),
            const SizedBox(width: AppSpace.x8),
            Expanded(
              child: second != null
                  ? _buildItem(second)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: rows,
    );
  }
}

