import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/assets/app_assets.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snack.dart';
import '../../../../core/widgets/phone_field.dart';
import '../../domain/auth_repository.dart';
import '../providers/auth_provider.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _phoneController = TextEditingController();
  final _phoneFocusNode = FocusNode();

  bool _isLoading = false;
  String? _customErrorText;
  bool _lostFocusWithError = false;

  @override
  void initState() {
    super.initState();
    _phoneFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _phoneFocusNode.removeListener(_onFocusChange);
    _phoneFocusNode.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_phoneFocusNode.hasFocus) {
      final digits = _getDigits();
      if (digits.isNotEmpty && digits.length < 10) {
        setState(() {
          _lostFocusWithError = true;
        });
      }
    }
  }

  String _getDigits() {
    return _phoneController.text.replaceAll(RegExp(r'\D'), '');
  }

  bool _isFirstDigitInvalid(String digits) {
    if (digits.isEmpty) return false;
    final first = digits[0];
    return first == '0' ||
        first == '1' ||
        first == '2' ||
        first == '3' ||
        first == '4' ||
        first == '5';
  }

  bool _isPhoneValid(String digits) {
    return digits.length == 10 && RegExp(r'^[6-9]\d{9}$').hasMatch(digits);
  }

  String? _getErrorText(AppLocalizations l10n) {
    if (_customErrorText != null) {
      return _customErrorText;
    }

    final digits = _getDigits();
    if (_isFirstDigitInvalid(digits)) {
      return l10n.phoneInvalid;
    }

    if (_lostFocusWithError && !_isPhoneValid(digits)) {
      return l10n.phoneInvalid;
    }

    return null;
  }

  void _onPhoneChanged(String _) {
    setState(() {
      _customErrorText = null;
      if (_isPhoneValid(_getDigits())) {
        _lostFocusWithError = false;
      }
    });
  }

  Future<void> _handleSendCode() async {
    final digits = _getDigits();
    if (!_isPhoneValid(digits)) return;

    final l10n = AppLocalizations.of(context)!;
    final fullPhone = '${AppConfig.countryCode}$digits';

    setState(() {
      _isLoading = true;
      _customErrorText = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.sendOtp(fullPhone);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      context.push(RoutePaths.verify, extra: fullPhone);
    } on AuthRateLimitException {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _customErrorText = l10n.tooManyAttempts;
      });
    } on AuthNetworkException {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      AppSnack.show(context, message: l10n.errorNetwork);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      AppSnack.show(context, message: l10n.errorGeneric);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusBarHeight = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final digits = _getDigits();
    final isValid = _isPhoneValid(digits);
    final errorText = _getErrorText(l10n);

    final showTerms = AppConfig.termsUrl.isNotEmpty &&
        AppConfig.privacyUrl.isNotEmpty;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.petrol,
        resizeToAvoidBottomInset: true,
        body: Column(
          children: [
            // Photo Area
            Expanded(
              child: LayoutBuilder(
                builder: (context, photoConstraints) {
                  final photoHeight = photoConstraints.maxHeight;
                  final showHeadline = photoHeight >= 120;
                  final showSubline = photoHeight >= 180;

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Photo extends 16 beneath sheet top edge
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        bottom: -16,
                        child: Image.asset(
                          AppAssets.authBackdrop,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const ColoredBox(color: AppColors.petrol),
                        ),
                      ),
                      // Scrim layer at 72% opacity
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        bottom: -16,
                        child: ColoredBox(
                          color: AppColors.scrim.withValues(alpha: 0.72),
                        ),
                      ),
                      // Brand and Headline
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: statusBarHeight + 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              children: [
                                SvgPicture.asset(
                                  AppAssets.logoMarkWhite,
                                  width: 32,
                                  height: 32,
                                  placeholderBuilder: (_) =>
                                      const SizedBox(width: 32, height: 32),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  AppConfig.appName,
                                  style: AppText.title.copyWith(
                                    color: AppColors.surface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          if (showHeadline)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.signInHeadline,
                                    style: AppText.display.copyWith(
                                      color: AppColors.surface,
                                    ),
                                  ),
                                  if (showSubline) ...[
                                    const SizedBox(height: 8),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 280),
                                      child: Text(
                                        l10n.signInSubline,
                                        style: AppText.body.copyWith(
                                          color: AppColors.surface.withValues(alpha: 0.85),
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 32),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),

            // Sheet Area
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.sheetTop,
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: 24 + bottomInset,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.signInTitle,
                    style: AppText.title,
                  ),
                  const SizedBox(height: 16),
                  PhoneField(
                    label: l10n.phoneLabel,
                    hint: l10n.phoneHint,
                    helperText: errorText == null ? l10n.phoneHelper : null,
                    errorText: errorText,
                    controller: _phoneController,
                    focusNode: _phoneFocusNode,
                    onChanged: _onPhoneChanged,
                    onSubmitted: (_) {
                      if (isValid && !_isLoading) {
                        _handleSendCode();
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  AppButton.primary(
                    label: l10n.sendCode,
                    expand: true,
                    loading: _isLoading,
                    onPressed: isValid && !_isLoading
                        ? _handleSendCode
                        : null,
                  ),
                  if (showTerms) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: Text.rich(
                        TextSpan(
                          style: AppText.caption,
                          children: [
                            TextSpan(
                              text: l10n.termsLink,
                              style: AppText.caption.copyWith(
                                color: AppColors.petrol,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () =>
                                    _launchUrl(AppConfig.termsUrl),
                            ),
                            const TextSpan(
                              text: ' & ',
                              style: AppText.caption,
                            ),
                            TextSpan(
                              text: l10n.privacyLink,
                              style: AppText.caption.copyWith(
                                color: AppColors.petrol,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () =>
                                    _launchUrl(AppConfig.privacyUrl),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
