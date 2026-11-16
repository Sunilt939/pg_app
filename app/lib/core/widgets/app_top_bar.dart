import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_icons.dart';
import '../theme/tokens.dart';

enum AppTopBarLeading { none, back, close }

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final AppTopBarLeading leadingType;
  final Widget? leading;
  final VoidCallback? onLeadingPressed;
  final List<Widget>? actions;
  final bool isPhotoVariant;

  const AppTopBar({
    super.key,
    this.title,
    this.titleWidget,
    this.leadingType = AppTopBarLeading.none,
    this.leading,
    this.onLeadingPressed,
    this.actions,
    this.isPhotoVariant = false,
  });

  const AppTopBar.back({
    super.key,
    this.title,
    this.titleWidget,
    this.onLeadingPressed,
    this.actions,
    this.isPhotoVariant = false,
  })  : leadingType = AppTopBarLeading.back,
        leading = null;

  const AppTopBar.close({
    super.key,
    this.title,
    this.titleWidget,
    this.onLeadingPressed,
    this.actions,
    this.isPhotoVariant = false,
  })  : leadingType = AppTopBarLeading.close,
        leading = null;

  const AppTopBar.photo({
    super.key,
    this.title,
    this.titleWidget,
    this.leadingType = AppTopBarLeading.back,
    this.leading,
    this.onLeadingPressed,
    this.actions,
  }) : isPhotoVariant = true;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isPhotoVariant ? AppColors.surface : AppColors.ink;
    final statusBarOverlay = isPhotoVariant
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    Widget? leadingWidget;
    if (leading != null) {
      leadingWidget = leading;
    } else if (leadingType == AppTopBarLeading.back) {
      leadingWidget = Semantics(
        button: true,
        label: 'Back',
        child: InkWell(
          onTap: onLeadingPressed ?? () => Navigator.maybePop(context),
          splashColor: AppColors.transparent,
          highlightColor: isPhotoVariant
              ? AppColors.surface.withValues(alpha: 0.12)
              : AppColors.petrolTint,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(
              AppIcons.back,
              size: 24,
              color: effectiveColor,
            ),
          ),
        ),
      );
    } else if (leadingType == AppTopBarLeading.close) {
      leadingWidget = Semantics(
        button: true,
        label: 'Close',
        child: InkWell(
          onTap: onLeadingPressed ?? () => Navigator.maybePop(context),
          splashColor: AppColors.transparent,
          highlightColor: isPhotoVariant
              ? AppColors.surface.withValues(alpha: 0.12)
              : AppColors.petrolTint,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(
              AppIcons.close,
              size: 24,
              color: effectiveColor,
            ),
          ),
        ),
      );
    }

    final hasLeading = leadingWidget != null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: statusBarOverlay,
      child: Container(
        height: preferredSize.height + MediaQuery.paddingOf(context).top,
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
        decoration: BoxDecoration(
          color: isPhotoVariant ? AppColors.transparent : AppColors.surface,
          border: isPhotoVariant
              ? null
              : const Border(
                  bottom: BorderSide(
                    color: AppColors.hairline,
                    width: 1.0,
                  ),
                ),
        ),
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              if (hasLeading)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: leadingWidget,
                )
              else
                const SizedBox(width: AppSpace.x16),
              Expanded(
                child: titleWidget ??
                    (title != null
                        ? Text(
                            title!,
                            style: AppText.title.copyWith(color: effectiveColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : const SizedBox.shrink()),
              ),
              if (actions != null && actions!.isNotEmpty) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions!,
                ),
                const SizedBox(width: AppSpace.x4),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

