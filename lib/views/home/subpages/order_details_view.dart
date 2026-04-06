import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marketing/bloc/order/order_details.dart';

class OrderDetailView extends StatelessWidget {
  final int? orderId;
  final String? orderNo;

  const OrderDetailView({
    super.key,
    required this.orderId,
    required this.orderNo,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OrderDetailBloc()..add(LoadOrderDetail(orderId!)),
      child: _OrderDetailScaffold(orderNo: orderNo!, orderId: orderId!),
    );
  }
}

// ─── Scaffold ─────────────────────────────────────────────────────────────────

class _OrderDetailScaffold extends StatelessWidget {
  final String orderNo;
  final int orderId;

  const _OrderDetailScaffold({required this.orderNo, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
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
                      return _DetailBody(order: state.order);
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

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

// ─── Detail Body ──────────────────────────────────────────────────────────────

class _DetailBody extends StatelessWidget {
  final OrderDetailMaster order;
  const _DetailBody({required this.order});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      children: [
        _SectionCard(
          accent: const Color(0xFF2196F3),
          title: 'Customer',
          icon: Icons.person_outline_rounded,
          child: Column(
            children: [
              _InfoRow(label: 'Bill To', value: order.billTo ?? '—'),
              _InfoRow(label: 'Address', value: order.billAddress ?? '—'),
              _InfoRow(label: 'Contact', value: order.billContactNo ?? '—'),
              _InfoRow(
                label: 'Order Date',
                value: order.formattedDate,
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
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
        _SectionCard(
          accent: Colors.black,
          title: 'Products  (${order.details.length})',
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
      ],
    );
  }
}

// ─── Section Card ─────────────────────────────────────────────────────────────

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
      width: double.infinity,
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

// ─── Info Row ─────────────────────────────────────────────────────────────────

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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

// ─── Product Item ─────────────────────────────────────────────────────────────

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

// ─── Chip ─────────────────────────────────────────────────────────────────────

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

// ─── Status Badge ─────────────────────────────────────────────────────────────

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

// ─── Loading View ─────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      children: [
        _ShimmerBox(height: 100),
        const SizedBox(height: 12),
        _ShimmerBox(height: 180),
        const SizedBox(height: 12),
        _ShimmerBox(height: 100),
        const SizedBox(height: 12),
        _ShimmerBox(height: 160),
      ],
    );
  }
}

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

// ─── Error View ───────────────────────────────────────────────────────────────

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
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
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
