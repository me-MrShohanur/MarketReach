import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marketing/bloc/order/order_details.dart';
import 'package:marketing/bloc/order/save_aproval.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// ENTRY POINT
// ═══════════════════════════════════════════════════════════════════════════════

class OrderDetailView extends StatelessWidget {
  final int? id;
  final int? orderId;
  final String? orderNo;

  const OrderDetailView({
    super.key,
    required this.orderId,
    required this.orderNo,
    required this.id,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => OrderDetailBloc()..add(LoadOrderDetail(id!)),
        ),
        BlocProvider(create: (_) => OrderApprovalBloc()),
      ],
      child: _OrderDetailScaffold(orderNo: orderNo!, orderId: orderId!),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SCAFFOLD
// ═══════════════════════════════════════════════════════════════════════════════

class _OrderDetailScaffold extends StatelessWidget {
  final String orderNo;
  final int orderId;

  const _OrderDetailScaffold({required this.orderNo, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: BlocListener<OrderApprovalBloc, OrderApprovalState>(
        listener: (context, state) {
          if (state is OrderApprovalSuccess) {
            debugPrint(
              '✅ [OrderApproval] SUCCESS — orderId: $orderId | msg: ${state.message}',
            );
            _showResultSheet(context, success: true, message: state.message);
          } else if (state is OrderApprovalFailure) {
            debugPrint(
              '❌ [OrderApproval] FAILED — orderId: $orderId | error: ${state.error}',
            );
            _showResultSheet(context, success: false, message: state.error);
          } else if (state is OrderApprovalLoading) {
            debugPrint('⏳ [OrderApproval] LOADING — orderId: $orderId');
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          body: SafeArea(
            child: Column(
              children: [
                _Header(orderNo: orderNo),
                const SizedBox(height: 16),
                Expanded(
                  child: BlocBuilder<OrderDetailBloc, OrderDetailState>(
                    builder: (context, state) {
                      if (state is OrderDetailLoading) {
                        return const _LoadingView();
                      }
                      if (state is OrderDetailError) {
                        return _ErrorView(
                          message: state.message,
                          onRetry: () => context.read<OrderDetailBloc>().add(
                            LoadOrderDetail(orderId),
                          ),
                        );
                      }
                      if (state is OrderDetailLoaded) {
                        return _DetailBody(
                          order: state.order,
                          orderId: orderId,
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showResultSheet(
    BuildContext context, {
    required bool success,
    required String message,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (_) => _ApprovalResultSheet(success: success, message: message),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// HEADER
// ═══════════════════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  final String orderNo;
  const _Header({required this.orderNo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0F000000),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Details',
                    style: TextStyle(fontSize: 13, color: Colors.black45),
                  ),
                  Text(
                    orderNo,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          BlocBuilder<OrderDetailBloc, OrderDetailState>(
            builder: (_, state) {
              if (state is! OrderDetailLoaded) return const SizedBox.shrink();
              return _StatusBadge(
                label:
                    state.order.statusName ?? _statusLabel(state.order.status),
                color: _statusColor(state.order.status),
              );
            },
          ),
        ],
      ),
    );
  }

  String _statusLabel(int s) {
    switch (s) {
      case 0:
        return 'Pending';
      case 1:
        return 'Processing';
      case 2:
        return 'Completed';
      case 3:
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  Color _statusColor(int s) {
    switch (s) {
      case 0:
        return const Color(0xFFFFC107);
      case 1:
        return const Color(0xFF2196F3);
      case 2:
        return const Color(0xFF4CAF50);
      case 3:
        return Colors.redAccent;
      default:
        return Colors.black26;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DETAIL BODY
// ═══════════════════════════════════════════════════════════════════════════════

class _DetailBody extends StatelessWidget {
  final OrderDetailMaster order;
  final int orderId;

  const _DetailBody({required this.order, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      children: [
        // ── Order Image ──────────────────────────────────────────────────────
        if (order.base64File != null && order.base64File!.isNotEmpty)
          GestureDetector(
            onTap: () => _showFullScreenImage(context, order.base64File!),
            child: _OrderImage(base64Image: order.base64File!),
          ),

        const SizedBox(height: 12),

        // ── Customer Card ────────────────────────────────────────────────────
        _SectionCard(
          accent: const Color(0xFF2196F3),
          title: 'Customer',
          icon: Icons.person_outline_rounded,
          child: Column(
            children: [
              _InfoRow(label: 'Bill To', value: order.billTo ?? '—'),
              _InfoRow(label: 'Address', value: order.billAddress ?? '—'),
              _InfoRow(label: 'Contact', value: order.billContactNo ?? '—'),
              _InfoRow(label: 'Order Date', value: order.formattedDate),
              if (order.chequeDate != null && order.chequeDate!.isNotEmpty)
                _InfoRow(
                  label: 'Cheque Date',
                  value: order.chequeDate!,
                  isLast: true,
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Financials Card ──────────────────────────────────────────────────
        _SectionCard(
          accent: const Color(0xFF4CAF50),
          title: 'Financials',
          icon: Icons.account_balance_wallet_outlined,
          child: Column(
            children: [
              _InfoRow(
                label: 'Net Amount',
                value: '৳${order.netAmount.toStringAsFixed(2)}',
              ),
              _InfoRow(
                label: 'Discount',
                value: '৳${order.discountAmount.toStringAsFixed(2)}',
              ),
              _InfoRow(
                label: 'VAT',
                value: '৳${order.vatAmount.toStringAsFixed(2)}',
              ),
              _InfoRow(
                label: 'Other Addition',
                value: '৳${order.otherAddition.toStringAsFixed(2)}',
              ),
              _InfoRow(
                label: 'Other Deduction',
                value: '৳${order.otherDeduction.toStringAsFixed(2)}',
              ),
              _InfoRow(
                label: 'Deposit',
                value: '৳${order.deposite.toStringAsFixed(2)}',
              ),
              _InfoRow(
                label: 'Paid Amount',
                value: '৳${order.paidAmount.toStringAsFixed(2)}',
              ),
              if (order.creditLimit != null && order.creditLimit! > 0)
                _InfoRow(
                  label: 'Credit Limit',
                  value: '৳${order.creditLimit!.toStringAsFixed(2)}',
                ),
              if (order.balance != null)
                _InfoRow(
                  label: 'Balance',
                  value: '৳${order.balance!.toStringAsFixed(2)}',
                  isLast: true,
                ),
              const Divider(height: 20, color: Color(0xFFF0F0F0)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Net Payable',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '৳${order.netPayable.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4CAF50),
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Payment Card ─────────────────────────────────────────────────────
        _SectionCard(
          accent: const Color(0xFFFFC107),
          title: 'Payment',
          icon: Icons.payments_outlined,
          child: Column(
            children: [
              _InfoRow(label: 'Payment Type', value: order.paymentType ?? '—'),
              _InfoRow(label: 'Ref No', value: order.refNo ?? '—'),
              _InfoRow(
                label: 'Narration',
                value: order.narration ?? '—',
                isLast: true,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Products Card ────────────────────────────────────────────────────
        _SectionCard(
          accent: Colors.black,
          title: 'Products (${order.details.length})',
          icon: Icons.inventory_2_outlined,
          child: order.details.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No product details available',
                    style: TextStyle(fontSize: 13, color: Colors.black38),
                  ),
                )
              : Column(
                  children: [
                    for (int i = 0; i < order.details.length; i++) ...[
                      if (i > 0)
                        const Divider(height: 20, color: Color(0xFFF0F0F0)),
                      _ProductItem(item: order.details[i], index: i),
                    ],
                  ],
                ),
        ),

        const SizedBox(height: 24),

        // ── Confirm Approval Button ──────────────────────────────────────────
        _ConfirmApprovalButton(orderId: orderId),

        const SizedBox(height: 8),
      ],
    );
  }

  void _showFullScreenImage(BuildContext context, String base64Image) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenImageViewer(base64Image: base64Image),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CONFIRM APPROVAL BUTTON
// ═══════════════════════════════════════════════════════════════════════════════

class _ConfirmApprovalButton extends StatelessWidget {
  final int orderId;
  const _ConfirmApprovalButton({required this.orderId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderApprovalBloc, OrderApprovalState>(
      builder: (context, state) {
        final isLoading = state is OrderApprovalLoading;

        return GestureDetector(
          onTap: isLoading
              ? null
              : () {
                  debugPrint(
                    '🟡 [OrderApproval] Confirm button tapped — orderId: $orderId',
                  );
                  _showConfirmDialog(context);
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: isLoading ? Colors.black45 : Colors.black,
              borderRadius: BorderRadius.circular(14),
              boxShadow: isLoading
                  ? []
                  : const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Confirm Approval',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  void _showConfirmDialog(BuildContext context) {
    // Capture the bloc before the async dialog gap
    final approvalBloc = context.read<OrderApprovalBloc>();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Confirm Approval',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        content: Text(
          'Are you sure you want to approve Order #$orderId?',
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () {
              debugPrint(
                '🔴 [OrderApproval] Dialog cancelled — orderId: $orderId',
              );
              Navigator.pop(dialogCtx);
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.black45),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pop(dialogCtx);
              debugPrint(
                '🟢 [OrderApproval] Dispatching ConfirmOrderApproval — orderId: $orderId',
              );
              approvalBloc.add(ConfirmOrderApproval(orderId));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Approve',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// APPROVAL RESULT BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════════════════════

class _ApprovalResultSheet extends StatelessWidget {
  final bool success;
  final String message;

  const _ApprovalResultSheet({required this.success, required this.message});

  @override
  Widget build(BuildContext context) {
    final color = success ? const Color(0xFF4CAF50) : Colors.redAccent;
    final icon = success ? Icons.check_circle_rounded : Icons.cancel_rounded;
    final title = success ? 'Approval Successful' : 'Approval Failed';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(fontSize: 13, color: Colors.black45),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'Done',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// FULL SCREEN IMAGE VIEWER
// ═══════════════════════════════════════════════════════════════════════════════

class FullScreenImageViewer extends StatelessWidget {
  final String base64Image;

  const FullScreenImageViewer({required this.base64Image, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Order Image', style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5.0,
          child: Image.memory(
            base64Decode(base64Image.split(',').last),
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) =>
                const Icon(Icons.error, color: Colors.white, size: 80),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ORDER IMAGE THUMBNAIL
// ═══════════════════════════════════════════════════════════════════════════════

class _OrderImage extends StatelessWidget {
  final String base64Image;
  const _OrderImage({required this.base64Image});

  @override
  Widget build(BuildContext context) {
    try {
      final bytes = base64Decode(base64Image.split(',').last);
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.memory(
          bytes,
          height: 220,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    } catch (e) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Text('Image Load Failed')),
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PRODUCT ITEM
// ═══════════════════════════════════════════════════════════════════════════════

class _ProductItem extends StatelessWidget {
  final OrderDetailItem item;
  final int index;

  const _ProductItem({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black45,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.productDesc ?? 'Product #${item.productId}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _Chip(
                    label: 'Qty',
                    value: '${item.unitQty}',
                    color: const Color(0xFF2196F3),
                  ),
                  if (item.pcsQty != null && item.pcsQty! > 0)
                    _Chip(
                      label: 'Pcs',
                      value: '${item.pcsQty}',
                      color: Colors.teal,
                    ),
                  _Chip(
                    label: 'Rate',
                    value: '৳${item.unitPrice.toStringAsFixed(2)}',
                    color: Colors.black,
                  ),
                  if (item.discountAmt > 0)
                    _Chip(
                      label: 'Disc',
                      value: '৳${item.discountAmt.toStringAsFixed(2)}',
                      color: Colors.orangeAccent,
                    ),
                  if (item.vat > 0)
                    _Chip(
                      label: 'VAT',
                      value: '${item.vat}%',
                      color: Colors.purple,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Net Amount',
                    style: TextStyle(fontSize: 12, color: Colors.black38),
                  ),
                  Text(
                    '৳${item.netAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4CAF50),
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              if (item.remarks != null && item.remarks!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  '📝 ${item.remarks}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black38,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SECTION CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _SectionCard extends StatelessWidget {
  final Color accent;
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.accent,
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: accent, width: 3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: accent, size: 16),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black54,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFF5F5F5)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// INFO ROW
// ═══════════════════════════════════════════════════════════════════════════════

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.black45),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CHIP
// ═══════════════════════════════════════════════════════════════════════════════

class _Chip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Chip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(
              fontSize: 11,
              color: color.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// STATUS BADGE
// ═══════════════════════════════════════════════════════════════════════════════

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.2,
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// LOADING VIEW
// ═══════════════════════════════════════════════════════════════════════════════

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
    children: const [
      _ShimmerBox(height: 100),
      SizedBox(height: 12),
      _ShimmerBox(height: 180),
      SizedBox(height: 12),
      _ShimmerBox(height: 100),
      SizedBox(height: 12),
      _ShimmerBox(height: 160),
    ],
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHIMMER BOX
// ═══════════════════════════════════════════════════════════════════════════════

class _ShimmerBox extends StatefulWidget {
  final double height;
  const _ShimmerBox({required this.height});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (_, _) => Opacity(
      opacity: _anim.value,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(color: Colors.grey.shade200, width: 3),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// ERROR VIEW
// ═══════════════════════════════════════════════════════════════════════════════

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              color: Colors.redAccent,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Failed to load details',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(fontSize: 13, color: Colors.black45),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 13),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
