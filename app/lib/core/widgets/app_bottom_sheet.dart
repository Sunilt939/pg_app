import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import 'app_button.dart';
import 'app_text_field.dart';

class AppBottomSheet extends StatelessWidget {
  final String? title;
  final Widget child;
  final Widget? bottomAction;
  final EdgeInsets? padding;

  const AppBottomSheet({
    super.key,
    this.title,
    required this.child,
    this.bottomAction,
    this.padding,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      barrierColor: AppColors.ink.withValues(alpha: 0.40),
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.sheetTop,
      ),
      builder: builder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.90;
    final bottomInset = mediaQuery.viewInsets.bottom;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: maxHeight,
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 8, bottom: 12),
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.handle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (title != null && title!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16),
                child: Text(
                  title!,
                  style: AppText.title,
                ),
              ),
            if (title != null && title!.isNotEmpty)
              const SizedBox(height: AppSpace.x12),
            Flexible(
              child: SingleChildScrollView(
                padding: padding ?? const EdgeInsets.symmetric(horizontal: AppSpace.x16),
                child: child,
              ),
            ),
            if (bottomAction != null) ...[
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    top: BorderSide(color: AppColors.hairline, width: 1.0),
                  ),
                ),
                padding: EdgeInsets.fromLTRB(
                  AppSpace.x16,
                  AppSpace.x16,
                  AppSpace.x16,
                  AppSpace.x16 + mediaQuery.padding.bottom,
                ),
                child: bottomAction!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ConfirmSheet extends StatefulWidget {
  final String title;
  final String body;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;
  final bool showReasonField;
  final bool isReasonRequired;
  final String? reasonLabel;
  final String? reasonHint;
  final String? reasonError;
  final Future<void> Function(String reason)? onConfirm;

  const ConfirmSheet({
    super.key,
    required this.title,
    required this.body,
    required this.confirmLabel,
    this.cancelLabel = 'Cancel',
    this.isDestructive = false,
    this.showReasonField = false,
    this.isReasonRequired = false,
    this.reasonLabel,
    this.reasonHint,
    this.reasonError,
    this.onConfirm,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String body,
    required String confirmLabel,
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
    bool showReasonField = false,
    bool isReasonRequired = false,
    String? reasonLabel,
    String? reasonHint,
    String? reasonError,
    Future<void> Function(String reason)? onConfirm,
  }) {
    return AppBottomSheet.show<bool>(
      context: context,
      builder: (context) => ConfirmSheet(
        title: title,
        body: body,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
        showReasonField: showReasonField,
        isReasonRequired: isReasonRequired,
        reasonLabel: reasonLabel,
        reasonHint: reasonHint,
        reasonError: reasonError,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<ConfirmSheet> createState() => _ConfirmSheetState();
}

class _ConfirmSheetState extends State<ConfirmSheet> {
  final _reasonController = TextEditingController();
  String? _reasonErrorText;
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    final reason = _reasonController.text.trim();
    if (widget.showReasonField && widget.isReasonRequired && reason.isEmpty) {
      setState(() => _reasonErrorText = widget.reasonError ?? 'Enter a reason.');
      return;
    }

    if (widget.onConfirm != null) {
      setState(() => _isLoading = true);
      try {
        await widget.onConfirm!(reason);
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (_) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheet(
      title: widget.title,
      bottomAction: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.isDestructive)
            AppButton.destructive(
              label: widget.confirmLabel,
              loading: _isLoading,
              onPressed: _handleConfirm,
            )
          else
            AppButton.primary(
              label: widget.confirmLabel,
              loading: _isLoading,
              onPressed: _handleConfirm,
            ),
          const SizedBox(height: AppSpace.x8),
          AppButton.text(
            label: widget.cancelLabel,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.body.isNotEmpty) ...[
            Text(
              widget.body,
              style: AppText.body,
            ),
          ],
          if (widget.showReasonField) ...[
            if (widget.body.isNotEmpty) const SizedBox(height: AppSpace.x16),
            AppTextField(
              label: widget.reasonLabel,
              hint: widget.reasonHint,
              controller: _reasonController,
              errorText: _reasonErrorText,
              maxLines: 3,
              onChanged: (val) {
                if (_reasonErrorText != null && val.trim().isNotEmpty) {
                  setState(() => _reasonErrorText = null);
                }
              },
            ),
          ],
          const SizedBox(height: AppSpace.x16),
        ],
      ),
    );
  }
}

