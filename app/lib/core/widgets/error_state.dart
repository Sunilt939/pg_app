import 'package:flutter/widgets.dart';
import '../theme/app_icons.dart';
import 'empty_state.dart';

class ErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;
  final String retryLabel;

  const ErrorState({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
    this.retryLabel = 'Try again',
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: AppIcons.warning,
      title: title,
      body: message,
      actionLabel: retryLabel,
      onAction: onRetry,
    );
  }
}

