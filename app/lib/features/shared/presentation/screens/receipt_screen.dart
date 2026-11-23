import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/format/dates.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/money.dart';
import '../../../../core/widgets/receipt_paper.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/stamp.dart';
import '../../../../core/widgets/tick_badge.dart';
import '../../domain/receipt_detail.dart';
import '../providers/receipt_provider.dart';

class ReceiptScreen extends ConsumerStatefulWidget {
  final String? paymentId;
  final bool isNew;

  const ReceiptScreen({
    super.key,
    this.paymentId,
    this.isNew = false,
  });

  @override
  ConsumerState<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends ConsumerState<ReceiptScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey _receiptKey = GlobalKey();
  late AnimationController _paperController;
  late Animation<double> _paperAnimation;
  bool _hapticFired = false;

  @override
  void initState() {
    super.initState();
    _paperController = AnimationController(
      vsync: this,
      duration: AppMotion.base,
    );

    _paperAnimation = CurvedAnimation(
      parent: _paperController,
      curve: AppMotion.curve,
    );

    if (widget.isNew) {
      Future.delayed(AppMotion.tick, () {
        if (mounted) {
          if (!_hapticFired) {
            _hapticFired = true;
            HapticFeedback.lightImpact();
          }
          final disableMotion =
              MediaQuery.maybeOf(context)?.disableAnimations ?? false;
          if (disableMotion) {
            _paperController.value = 1.0;
          } else {
            _paperController.forward();
          }
        }
      });
    } else {
      _paperController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _paperController.dispose();
    super.dispose();
  }

  Future<void> _shareReceipt(
    BuildContext context,
    AppLocalizations l10n,
    ReceiptDetail receipt,
  ) async {
    try {
      final boundary = _receiptKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/receipt_${receipt.receiptNo}.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: l10n.receiptShareText(
          receipt.receiptNo.toString().padLeft(6, '0'),
          receipt.pgName,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Widget _buildLoadingSkeleton() {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpace.x16),
      children: const [
        ReceiptPaper(
          padding: EdgeInsets.all(AppSpace.x16),
          header: SkeletonBlock(height: 60),
          body: Column(
            children: [
              SkeletonBlock(height: 100),
              SizedBox(height: AppSpace.x16),
              SkeletonBlock(height: 100),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.x4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: AppText.secondary),
          ),
          const SizedBox(width: AppSpace.x8),
          Expanded(
            child: Text(
              value,
              style: AppText.body,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaperContent(
    BuildContext context,
    AppLocalizations l10n,
    ReceiptDetail receipt,
  ) {
    final addressParts = [
      receipt.pgAddressLine1,
      receipt.pgArea,
      receipt.pgCity,
    ].where((s) => s != null && s.trim().isNotEmpty).join(', ');

    return ReceiptPaper(
      padding: const EdgeInsets.all(20),
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SvgPicture.asset(
                AppAssets.logoMark,
                width: 28,
                height: 28,
              ),
              const SizedBox(width: AppSpace.x8),
              Expanded(
                child: Text(
                  receipt.pgName,
                  style: AppText.heading,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpace.x8),
              Text(
                l10n.receiptNo(
                  receipt.receiptNo.toString().padLeft(6, '0'),
                ),
                style: AppText.label,
              ),
            ],
          ),
          if (addressParts.isNotEmpty) ...[
            const SizedBox(height: AppSpace.x4),
            Text(addressParts, style: AppText.secondary),
          ],
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.receiptAmountLabel, style: AppText.secondary),
          const SizedBox(height: AppSpace.x4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Money(
                  paise: receipt.amountPaise,
                  style: AppText.display,
                ),
              ),
              if (receipt.status == 'confirmed')
                Stamp.paid(label: l10n.receiptStampReceived)
              else if (receipt.status == 'reversed')
                Stamp.overdue(label: l10n.receiptStampReversed),
            ],
          ),
          const SizedBox(height: AppSpace.x4),
          Text(
            '${receipt.methodLabel}${receipt.payerAppLabel != null ? ', ${receipt.payerAppLabel}' : ''}',
            style: AppText.body,
          ),
          const SizedBox(height: AppSpace.x4),
          Text(formatDate(receipt.paidOn), style: AppText.secondary),
          if (receipt.status == 'reversed' &&
              receipt.statusReason != null &&
              receipt.statusReason!.isNotEmpty) ...[
            const SizedBox(height: AppSpace.x4),
            Text(
              l10n.receiptReversedReason(receipt.statusReason!),
              style: AppText.secondary,
            ),
          ],
          const SizedBox(height: AppSpace.x16),
          const Divider(height: 1, color: AppColors.hairline),
          const SizedBox(height: AppSpace.x12),
          _buildDetailRow(l10n.receiptFrom, receipt.guestName),
          if (receipt.roomNumber != null && receipt.bedLabel != null)
            _buildDetailRow(
              l10n.receiptRoom,
              'Room ${receipt.roomNumber}, bed ${receipt.bedLabel}',
            ),
          if (receipt.utr != null && receipt.utr!.isNotEmpty)
            _buildDetailRow(l10n.receiptReference, receipt.utr!),
          _buildDetailRow(l10n.receiptDate, formatDate(receipt.issuedAt)),
          const SizedBox(height: AppSpace.x12),
          const Divider(height: 1, color: AppColors.hairline),
          const SizedBox(height: AppSpace.x16),
          Text(l10n.receiptPaidTowards, style: AppText.sectionHeader),
          const SizedBox(height: AppSpace.x8),
          for (final alloc in receipt.allocations)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.x4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(alloc.description, style: AppText.body),
                  ),
                  const SizedBox(width: AppSpace.x8),
                  Money(paise: alloc.amountPaise, style: AppText.body),
                ],
              ),
            ),
          if (receipt.unallocatedPaise > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.x4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(l10n.receiptAdvance, style: AppText.body),
                  ),
                  const SizedBox(width: AppSpace.x8),
                  Money(
                    paise: receipt.unallocatedPaise,
                    style: AppText.body,
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpace.x12),
          const Divider(height: 1, color: AppColors.hairline),
          const SizedBox(height: AppSpace.x12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.receiptTotal, style: AppText.heading),
              Money(paise: receipt.amountPaise, style: AppText.heading),
            ],
          ),
        ],
      ),
      footer: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            l10n.receiptFooter(AppConfig.appName),
            style: AppText.caption,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final paymentId = widget.paymentId ?? '';
    final receiptAsync = ref.watch(receiptDetailProvider(paymentId));

    return Scaffold(
      backgroundColor: AppColors.ground,
      appBar: AppTopBar.back(
        title: l10n.receiptTitle,
        onLeadingPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/owner/guests');
          }
        },
      ),
      body: receiptAsync.when(
        loading: () => _buildLoadingSkeleton(),
        error: (error, _) => ErrorState(
          title: l10n.errorGeneric,
          message: error.toString(),
          onRetry: () => ref.invalidate(receiptDetailProvider(paymentId)),
        ),
        data: (receipt) {
          if (receipt == null) {
            return Center(
              child: EmptyState(
                icon: AppIcons.payments,
                title: l10n.receiptUnavailableTitle,
                body: l10n.receiptUnavailableBody,
              ),
            );
          }

          final paperWidget = RepaintBoundary(
            key: _receiptKey,
            child: Container(
              color: AppColors.ground,
              padding: const EdgeInsets.all(AppSpace.x16),
              child: _buildPaperContent(context, l10n, receipt),
            ),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSpace.x32),
            child: Column(
              children: [
                if (widget.isNew) ...[
                  const SizedBox(height: AppSpace.x24),
                  const Center(child: TickBadge(size: 64)),
                  const SizedBox(height: AppSpace.x16),
                  Center(
                    child: Text(
                      l10n.receiptRecorded,
                      style: AppText.title,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppSpace.x24),
                  AnimatedBuilder(
                    animation: _paperAnimation,
                    builder: (context, child) {
                      final offset =
                          Offset(0, 12 * (1 - _paperAnimation.value));
                      return Transform.translate(
                        offset: offset,
                        child: Opacity(
                          opacity: _paperAnimation.value,
                          child: child,
                        ),
                      );
                    },
                    child: paperWidget,
                  ),
                ] else ...[
                  paperWidget,
                ],
                const SizedBox(height: AppSpace.x24),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.x16,
                  ),
                  child: Column(
                    children: [
                      AppButton.primary(
                        expand: true,
                        icon: AppIcons.share,
                        label: l10n.receiptShare,
                        onPressed: () =>
                            _shareReceipt(context, l10n, receipt),
                      ),
                      if (widget.isNew) ...[
                        const SizedBox(height: AppSpace.x12),
                        AppButton.secondary(
                          expand: true,
                          label: l10n.actionDone,
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go(
                                '/owner/guests/${receipt.stayId}',
                              );
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
