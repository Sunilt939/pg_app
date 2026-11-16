import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/assets/app_assets.dart';
import '../../../../core/format/phone.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snack.dart';
import '../../../../core/widgets/otp_field.dart';
import '../../domain/auth_repository.dart';
import '../providers/auth_provider.dart';

class VerifyScreen extends ConsumerStatefulWidget {
  final String? phone;

  const VerifyScreen({super.key, this.phone});

  @override
  ConsumerState<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends ConsumerState<VerifyScreen> {
  final _otpController = TextEditingController();
  final _otpFocusNode = FocusNode();

  String _code = '';
  bool _isSubmitting = false;
  bool _hasError = false;
  String? _errorMessage;

  Timer? _countdownTimer;
  int _countdown = 30;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _countdown = 30;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        setState(() {
          _countdown = 0;
        });
        timer.cancel();
      }
    });
  }

  void _onOtpChanged(String code) {
    setState(() {
      _code = code;
      if (code.isNotEmpty && (_hasError || _errorMessage != null)) {
        _hasError = false;
        _errorMessage = null;
      }
    });
  }

  Future<void> _resendOtp() async {
    final phone = widget.phone ?? '';
    if (phone.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    final authRepo = ref.read(authRepositoryProvider);

    try {
      await authRepo.sendOtp(phone);
      if (!mounted) return;
      _startCountdown();
      AppSnack.show(context, message: l10n.codeSent);
    } on AuthNetworkException {
      if (!mounted) return;
      AppSnack.show(context, message: l10n.errorNetwork);
    } catch (_) {
      if (!mounted) return;
      AppSnack.show(context, message: l10n.errorGeneric);
    }
  }

  Future<void> _submitOtp(String code) async {
    if (_isSubmitting || code.length != 6) return;

    final phone = widget.phone ?? '';
    if (phone.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    final authRepo = ref.read(authRepositoryProvider);

    setState(() {
      _isSubmitting = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      await authRepo.verifyOtp(phone: phone, token: code);

      // Light haptic feedback on successful sign-in
      HapticFeedback.lightImpact();

      final contextNotifier = ref.read(authContextProvider.notifier);
      await contextNotifier.refreshContext();
      final myContext = await authRepo.getMyContext();
      final lastView = await authRepo.getLastView();

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      // Post-sign-in routing logic
      final isOwnerPreferred = myContext.pgs.isNotEmpty &&
          (myContext.stays.isEmpty ||
              lastView == 'owner' ||
              lastView == null ||
              lastView.isEmpty);

      if (isOwnerPreferred) {
        context.go(RoutePaths.ownerHome);
      } else if (myContext.stays.isNotEmpty) {
        context.go(RoutePaths.guestHome);
      } else {
        context.go(RoutePaths.gate);
      }
    } on AuthOtpExpiredException {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _hasError = true;
        _errorMessage = l10n.otpExpired;
        _code = '';
      });
      _otpController.clear();
      _otpFocusNode.requestFocus();
    } on AuthInvalidOtpException {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _hasError = true;
        _errorMessage = l10n.otpInvalid;
        _code = '';
      });
      _otpController.clear();
      _otpFocusNode.requestFocus();
    } on AuthNetworkException {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      AppSnack.show(context, message: l10n.errorNetwork);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _hasError = true;
        _errorMessage = l10n.otpInvalid;
        _code = '';
      });
      _otpController.clear();
      _otpFocusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusBarHeight = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final rawPhone = widget.phone ?? '';
    final formattedPhone = PhoneFormat.format(rawPhone);

    final secondsStr = _countdown.toString().padLeft(2, '0');
    final countdownTime = '0:$secondsStr';

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
              child: Stack(
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
                  // Back arrow below status bar
                  Positioned(
                    top: statusBarHeight,
                    left: 4,
                    child: Semantics(
                      button: true,
                      label: 'Back',
                      child: InkWell(
                        onTap: () => context.pop(),
                        splashColor: AppColors.transparent,
                        highlightColor: AppColors.surface.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(24),
                        child: const SizedBox(
                          width: 48,
                          height: 48,
                          child: Icon(
                            AppIcons.back,
                            size: 24,
                            color: AppColors.surface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
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
                    l10n.verifyTitle,
                    style: AppText.title,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.verifySentTo(formattedPhone),
                    style: AppText.secondary,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AppButton.text(
                      label: l10n.verifyChangeNumber,
                      padding: EdgeInsets.zero,
                      onPressed: () => context.pop(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OtpField(
                    length: 6,
                    controller: _otpController,
                    focusNode: _otpFocusNode,
                    hasError: _hasError,
                    onChanged: _onOtpChanged,
                    onCompleted: (code) {
                      if (!_isSubmitting) {
                        _submitOtp(code);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 20),
                    child: _errorMessage != null
                        ? Text(
                            _errorMessage!,
                            style: AppText.secondary.copyWith(
                              color: AppColors.overdueFg,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),
                  AppButton.primary(
                    label: l10n.verifyAction,
                    expand: true,
                    loading: _isSubmitting,
                    onPressed: _code.length == 6 && !_isSubmitting
                        ? () => _submitOtp(_code)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: _countdown > 0
                        ? Text(
                            l10n.resendIn(countdownTime),
                            style: AppText.secondary,
                          )
                        : AppButton.text(
                            label: l10n.resendAction,
                            padding: EdgeInsets.zero,
                            onPressed: _resendOtp,
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
