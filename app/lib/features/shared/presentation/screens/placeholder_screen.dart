import 'package:flutter/material.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_top_bar.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;
  final bool hasBack;

  const PlaceholderScreen({
    super.key,
    required this.title,
    this.hasBack = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ground,
      appBar: hasBack
          ? AppTopBar.back(title: title)
          : AppTopBar(title: title),
      body: const SizedBox.expand(),
    );
  }
}

