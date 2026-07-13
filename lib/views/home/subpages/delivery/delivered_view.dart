import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marketing/bloc/chalan-deleiver/block/chalan_bloc_list.dart';
import 'package:marketing/bloc/chalan-deleiver/repository/get_chalan_repo.dart';
import 'package:marketing/services/models/chalan_bill_model.dart';
import 'package:marketing/services/provider/current_user.dart';
import 'package:marketing/views/home/subpages/delivery/details/chalan_detail_view.dart';

// ── accent colours for this page ────────────────────────────────────────────
const _kAccent = Color(0xFF009688);
const _kStatus = Color(0xFF4CAF50);

class DeliveredView extends StatelessWidget {
  const DeliveredView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          DeliveryListBloc(repository: ChallanRepository())
            ..add(FetchChallanBill(types: 2, partyId: CurrentUser.customerID)),
      child: const _DeliveredBody(),
    );
  }
}

class _DeliveredBody extends StatelessWidget {
  const _DeliveredBody();

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
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Challan & Delivery',
                        style: TextStyle(fontSize: 12, color: Colors.black45),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Delivered',
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
            BlocBuilder<DeliveryListBloc, ChallanState>(
              builder: (context, state) {
                final count = state is ChallanLoaded
                    ? state.challans.length
                    : 0;
                final totalDelivered = state is ChallanLoaded
                    ? state.challans.fold<int>(0, (s, e) => s + e.deliverdQty)
                    : 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        _SummaryChip(
                          label: 'Total Challans',
                          value: '$count',
                          icon: Icons.receipt_long_rounded,
                          color: _kAccent,
                        ),
                        const SizedBox(width: 10),
                        _SummaryChip(
                          label: 'Delivered Qty',
                          value: '$totalDelivered',
                          icon: Icons.check_circle_rounded,
                          color: _kStatus,
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
              child: BlocBuilder<DeliveryListBloc, ChallanState>(
                builder: (context, state) {
                  if (state is ChallanLoading) return const _ChallanShimmer();
                  if (state is ChallanError) {
                    return _ErrorView(
                      message: state.message,
                      onRetry: () => context.read<DeliveryListBloc>().add(
                        FetchChallanBill(
                          types: 2,
                          partyId: CurrentUser.customerID,
                        ),
                      ),
                    );
                  }
                  if (state is ChallanLoaded) {
                    if (state.challans.isEmpty) {
                      return const _EmptyView(
                        label: 'No delivered orders yet',
                        icon: Icons.check_circle_outline_rounded,
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: state.challans.length,
                      itemBuilder: (_, i) =>
                          _ChallanCard(item: state.challans[i]),
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
// CHALLAN CARD
// ════════════════════════════════════════════════════════════════════════════

class _ChallanCard extends StatelessWidget {
  final ChallanBillModel item;

  const _ChallanCard({required this.item});

  String _formatDate(String raw) {
    if (raw.length != 8) return raw;
    const months = [
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
    final pendingQty = item.untitQty - item.deliverdQty;
    final progress = item.untitQty > 0
        ? (item.deliverdQty / item.untitQty).clamp(0.0, 1.0)
        : 0.0;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        log(name: 'challanId', item.challanId.toString());
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChallanDetailsView(
              challanId: item.challanId,
              orderNo: item.orderNo,
              accentColor: _kAccent,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: const Border(left: BorderSide(color: _kAccent, width: 3)),
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
                      color: _kStatus.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Delivered',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _kStatus,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
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
                  const Icon(
                    Icons.tag_rounded,
                    size: 12,
                    color: Colors.black38,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Challan #${item.challanId}',
                    style: const TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: _kAccent.withValues(alpha: 0.12),
                  valueColor: const AlwaysStoppedAnimation<Color>(_kAccent),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _QtyBadge(
                    label: 'Ordered',
                    value: '${item.untitQty}',
                    color: Colors.black54,
                  ),
                  const SizedBox(width: 8),
                  _QtyBadge(
                    label: 'Delivered',
                    value: '${item.deliverdQty}',
                    color: _kStatus,
                  ),
                  const SizedBox(width: 8),
                  _QtyBadge(
                    label: 'Remaining',
                    value: '$pendingQty',
                    color: pendingQty > 0
                        ? const Color(0xFFFF5722)
                        : Colors.black26,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SHARED SMALL WIDGETS
// ════════════════════════════════════════════════════════════════════════════

class _QtyBadge extends StatelessWidget {
  final String label, value;
  final Color color;
  const _QtyBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.7)),
        ),
      ],
    ),
  );
}

class _SummaryChip extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
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
                const SizedBox(height: 12),
                _bar(double.infinity, 5, radius: 4),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _bar(70, 28, radius: 8),
                    const SizedBox(width: 8),
                    _bar(70, 28, radius: 8),
                    const SizedBox(width: 8),
                    _bar(70, 28, radius: 8),
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

class _EmptyView extends StatelessWidget {
  final String label;
  final IconData icon;
  const _EmptyView({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) => Center(
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

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
