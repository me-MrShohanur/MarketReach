import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marketing/bloc/pending-delivery/get_pending.dart';
import 'package:marketing/services/models/getpening_model.dart';
import 'package:marketing/services/provider/pending_order_repo.dart';

class PendingOrderDetailView extends StatelessWidget {
  final int orderId;
  final int partyId;
  final String orderNo;

  const PendingOrderDetailView({
    super.key,
    required this.orderId,
    required this.partyId,
    required this.orderNo,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // orderId / partyId are exactly what was passed in when this page
      // was pushed — nothing here is hardcoded.
      create: (_) =>
          PendingOrderDetailBloc(repository: PendingOrderDetailRepository())
            ..add(FetchPendingOrderDetail(orderId: orderId, partyId: partyId)),
      child: _PendingOrderDetailBody(
        orderId: orderId,
        partyId: partyId,
        orderNo: orderNo,
      ),
    );
  }
}

class _PendingOrderDetailBody extends StatelessWidget {
  final int orderId;
  final int partyId;
  final String orderNo;

  const _PendingOrderDetailBody({
    required this.orderId,
    required this.partyId,
    required this.orderNo,
  });

  void _refetch(BuildContext context) {
    context.read<PendingOrderDetailBloc>().add(
      FetchPendingOrderDetail(orderId: orderId, partyId: partyId),
    );
  }

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
                    children: [
                      const Text(
                        'Order Details',
                        style: TextStyle(fontSize: 12, color: Colors.black45),
                      ),
                      const SizedBox(height: 2),
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
            ),

            const SizedBox(height: 16),

            // ── Summary Strip ─────────────────────────────────────
            BlocBuilder<PendingOrderDetailBloc, PendingOrderDetailState>(
              builder: (context, state) {
                final items = state is PendingOrderDetailLoaded
                    ? state.items
                    : <PendingOrderDetailModel>[];

                final totalPendingQty = items.fold<double>(
                  0,
                  (s, e) => s + e.pendingQty,
                );

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _SummaryChip(
                    label: 'Pending Qty',
                    value: totalPendingQty.toStringAsFixed(0),
                    icon: Icons.hourglass_bottom_rounded,
                    color: totalPendingQty > 0
                        ? const Color(0xFFFF5722)
                        : Colors.black26,
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // ── List ─────────────────────────────────────────────
            Expanded(
              child:
                  BlocBuilder<PendingOrderDetailBloc, PendingOrderDetailState>(
                    builder: (context, state) {
                      if (state is PendingOrderDetailLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (state is PendingOrderDetailError) {
                        return _ErrorView(
                          message: state.message,
                          onRetry: () => _refetch(context),
                        );
                      }
                      if (state is PendingOrderDetailLoaded) {
                        if (state.items.isEmpty) {
                          return const Center(
                            child: Text(
                              'No items found for this order',
                              style: TextStyle(color: Colors.black38),
                            ),
                          );
                        }
                        return RefreshIndicator(
                          onRefresh: () async => _refetch(context),
                          color: Colors.black,
                          backgroundColor: Colors.white,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            itemCount: state.items.length,
                            itemBuilder: (_, i) =>
                                _OrderItemCard(item: state.items[i]),
                          ),
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
// SUMMARY CHIP
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
    return Container(
      width: double.infinity,
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
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Colors.black45),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ORDER ITEM CARD
// ════════════════════════════════════════════════════════════════════════════

class _OrderItemCard extends StatelessWidget {
  final PendingOrderDetailModel item;
  const _OrderItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          left: BorderSide(color: Color(0xFF2196F3), width: 3),
        ),
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
            Text(
              item.itemName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.itemDescription,
              style: const TextStyle(fontSize: 12, color: Colors.black45),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _QtyBadge(
                  label: 'Ordered',
                  value: item.orderQty.toStringAsFixed(0),
                  color: Colors.black54,
                ),
                const SizedBox(width: 8),
                _QtyBadge(
                  label: 'Delivered',
                  value: item.delivaryQty.toStringAsFixed(0),
                  color: const Color(0xFF4CAF50),
                ),
                const SizedBox(width: 8),
                _QtyBadge(
                  label: 'Pending',
                  value: item.pendingQty.toStringAsFixed(0),
                  color: item.pendingQty > 0
                      ? const Color(0xFFFF5722)
                      : Colors.black26,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '৳${item.netAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4CAF50),
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

// ════════════════════════════════════════════════════════════════════════════
// ERROR VIEW
// ════════════════════════════════════════════════════════════════════════════

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
