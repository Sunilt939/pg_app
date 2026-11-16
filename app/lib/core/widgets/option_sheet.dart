import 'package:flutter/material.dart';
import '../theme/app_icons.dart';
import '../theme/tokens.dart';
import 'app_bottom_sheet.dart';

class OptionSheetItem<T> {
  final T value;
  final String title;
  final String? subtitle;

  const OptionSheetItem({
    required this.value,
    required this.title,
    this.subtitle,
  });
}

class OptionSheet<T> extends StatefulWidget {
  final String title;
  final List<OptionSheetItem<T>> options;
  final T? selectedValue;
  final bool showSearch;
  final String? searchHint;

  const OptionSheet({
    super.key,
    required this.title,
    required this.options,
    this.selectedValue,
    this.showSearch = false,
    this.searchHint = 'Search',
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required List<OptionSheetItem<T>> options,
    T? selectedValue,
    bool showSearch = false,
    String? searchHint,
  }) {
    return AppBottomSheet.show<T>(
      context: context,
      builder: (context) => OptionSheet<T>(
        title: title,
        options: options,
        selectedValue: selectedValue,
        showSearch: showSearch,
        searchHint: searchHint,
      ),
    );
  }

  @override
  State<OptionSheet<T>> createState() => _OptionSheetState<T>();
}

class _OptionSheetState<T> extends State<OptionSheet<T>> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.options.where((opt) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      final titleMatch = opt.title.toLowerCase().contains(q);
      final subMatch = opt.subtitle?.toLowerCase().contains(q) ?? false;
      return titleMatch || subMatch;
    }).toList();

    return AppBottomSheet(
      title: widget.title,
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showSearch) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.x16,
                vertical: AppSpace.x8,
              ),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.ground,
                  borderRadius: AppRadius.button,
                  border: Border.all(
                    color: AppColors.hairline,
                    width: 1.0,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.x12),
                child: Row(
                  children: [
                    const Icon(
                      AppIcons.search,
                      size: 20,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: AppSpace.x8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _query = val.trim()),
                        style: AppText.body,
                        cursorColor: AppColors.petrol,
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: widget.searchHint,
                          hintStyle: AppText.body.copyWith(color: AppColors.muted),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              thickness: 1,
              color: AppColors.hairline,
              indent: AppSpace.x16,
            ),
            itemBuilder: (context, index) {
              final item = filtered[index];
              final isSelected = item.value == widget.selectedValue;

              return InkWell(
                onTap: () => Navigator.of(context).pop(item.value),
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
                              item.title,
                              style: AppText.body,
                            ),
                            if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                item.subtitle!,
                                style: AppText.secondary,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: AppSpace.x12),
                        const Icon(
                          AppIcons.check,
                          size: 20,
                          color: AppColors.petrol,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpace.x16),
        ],
      ),
    );
  }
}

