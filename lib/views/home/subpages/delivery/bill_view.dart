import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marketing/bloc/chalan-deleiver/block/chalan_bloc.dart';

import 'package:marketing/bloc/chalan-deleiver/repository/get_chalan_repo.dart';
import 'package:marketing/services/models/chalan_bill.dart';

class BillView extends StatelessWidget {
  const BillView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ChallanBloc(repository: ChallanRepository())
            ..add(FetchChallanBill(types: 3)),
      child: const _BillBody(),
    );
  }
}

class _BillBody extends StatelessWidget {
  const _BillBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Challan & Delivery',
                        style: TextStyle(fontSize: 12, color: Colors.black45),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Bill',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Summary Strip ────────────────────────────────────
            BlocBuilder<ChallanBloc, ChallanState>(
              builder: (context, state) {
                final count = state is ChallanLoaded
                    ? state.challans.length
                    : 0;
                final totalBilled = state is ChallanLoaded
                    ? state.challans.fold<int>(0, (s, e) => s + e.deliverdQty)
                    : 0;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        _SummaryChip(
                          label: 'Total Bills',
                          value: '$count',
                          icon: Icons.receipt_rounded,
                          color: const Color(0xFF607D8B),
                        ),
                        const SizedBox(width: 10),
                        _SummaryChip(
                          label: 'Billed Qty',
                          value: '$totalBilled',
                          icon: Icons.inventory_rounded,
                          color: const Color(0xFF455A64),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // ── List ─────────────────────────────────────────────
            Expanded(
              child: BlocBuilder<ChallanBloc, ChallanState>(
                builder: (context, state) {
                  if (state is ChallanLoading) {
                    return const _ChallanShimmer();
                  }
                  if (state is ChallanError) {
                    return _ErrorView(
                      message: state.message,
                      onRetry: () => context.read<ChallanBloc>().add(
                        FetchChallanBill(types: 3),
                      ),
                    );
                  }
                  if (state is ChallanLoaded) {
                    if (state.challans.isEmpty) {
                      return const _EmptyView(
                        label: 'No bills available',
                        icon: Icons.receipt_long_outlined,
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: state.challans.length,
                      itemBuilder: (_, i) => _BillCard(item: state.challans[i]),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// BILL CARD  (slightly different from challan card — shows bill-specific info)
// ════════════════════════════════════════════════════════════════════════════

class _BillCard extends StatelessWidget {
  final ChallanBill item;

  const _BillCard({required this.item});

  static const _accentColor = Color(0xFF607D8B);

  String _formatDate(String raw) {
    if (raw.length != 8) return raw;
    final months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    try {
      final y = raw.substring(0, 4);
      final m = int.parse(raw.substring(4, 6));
      final d = raw.substring(6, 8);
      return '$d ${months[m]} $y';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFull = item.deliverdQty >= item.untitQty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: const Border(left: BorderSide(color: _accentColor, width: 3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Row ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.orderNo,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isFull
                        ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                        : _accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isFull
                            ? Icons.check_circle_rounded
                            : Icons.pending_rounded,
                        size: 11,
                        color: isFull ? const Color(0xFF4CAF50) : _accentColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isFull ? 'Billed' : 'Partial',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isFull
                              ? const Color(0xFF4CAF50)
                              : _accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ── Meta Row ──
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 12,
                  color: Colors.black38,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(item.orderDate),
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
                const SizedBox(width: 14),
                Icon(Icons.tag_rounded, size: 12, color: Colors.black38),
                const SizedBox(width: 4),
                Text(
                  'Bill #${item.challanId}',
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Divider ──
            Divider(height: 1, color: Colors.grey.shade100, thickness: 1),

            const SizedBox(height: 12),

            // ── Qty summary — bill style (row with labels above) ──
            Row(
              children: [
                Expanded(
                  child: _BillQtyColumn(
                    label: 'Order Qty',
                    value: '${item.untitQty}',
                    color: Colors.black54,
                  ),
                ),
                Container(width: 1, height: 36, color: Colors.grey.shade100),
                Expanded(
                  child: _BillQtyColumn(
                    label: 'Billed Qty',
                    value: '${item.deliverdQty}',
                    color: _accentColor,
                  ),
                ),
                Container(width: 1, height: 36, color: Colors.grey.shade100),
                Expanded(
                  child: _BillQtyColumn(
                    label: 'Balance',
                    value: '${item.untitQty - item.deliverdQty}',
                    color: isFull
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFFF5722),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BillQtyColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _BillQtyColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.black38),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ════════════════════════════════════════════════════════════════════════════

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border(left: BorderSide(color: color, width: 3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Colors.black45),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shimmer ───────────────────────────────────────────────────────────────────

class _ChallanShimmer extends StatefulWidget {
  const _ChallanShimmer();

  @override
  State<_ChallanShimmer> createState() => _ChallanShimmerState();
}

class _ChallanShimmerState extends State<_ChallanShimmer>
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
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        itemCount: 5,
        itemBuilder: (_, _) => Opacity(
          opacity: _anim.value,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [_bar(120, 14), _bar(60, 22, radius: 20)],
                ),
                const SizedBox(height: 10),
                _bar(160, 11),
                const SizedBox(height: 14),
                _bar(double.infinity, 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _bar(double.infinity, 36, radius: 8)),
                    const SizedBox(width: 1),
                    Expanded(child: _bar(double.infinity, 36, radius: 8)),
                    const SizedBox(width: 1),
                    Expanded(child: _bar(double.infinity, 36, radius: 8)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bar(double w, double h, {double radius = 6}) => Container(
    width: w == double.infinity ? null : w,
    height: h,
    decoration: BoxDecoration(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

// ── Empty / Error ─────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final String label;
  final IconData icon;

  const _EmptyView({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Colors.black12),
          const SizedBox(height: 14),
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black38,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.black45),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
