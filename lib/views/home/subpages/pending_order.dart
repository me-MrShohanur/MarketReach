// lib/views/home/subpages/pending_orders_view.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:marketing/bloc/order/pending_order_block.dart';
import 'package:marketing/views/home/subpages/order_details_view.dart';

class PendingOrdersView extends StatefulWidget {
  final List<int> statusFilter;
  final String title;
  final String subtitle;
  final Color accentColor;
  final List<OrderListItem>? preloadedOrders; // ← cached from home

  const PendingOrdersView({
    super.key,
    this.statusFilter = const [],
    this.title = 'All Orders',
    this.subtitle = 'Sales Orders',
    this.accentColor = Colors.black,
    this.preloadedOrders,
  });

  @override
  State<PendingOrdersView> createState() => _PendingOrdersViewState();
}

class _PendingOrdersViewState extends State<PendingOrdersView> {
  late DateTime _from;
  late DateTime _to;
  late final OrderListBloc _bloc;

  @override
  void initState() {
    super.initState();
    _to = DateTime.now();
    _from = _to.subtract(const Duration(days: 30));
    _bloc = OrderListBloc();

    if (widget.preloadedOrders != null) {
      // ── Instant: filter cached data, no API call ──────────────────
      _bloc.add(
        PreloadOrderList(
          orders: widget.preloadedOrders!,
          statusFilter: widget.statusFilter,
        ),
      );
    } else {
      // ── Fallback: fetch from API ───────────────────────────────────
      _bloc.add(
        LoadOrderList(
          fromDate: _fmt(_from),
          toDate: _fmt(_to),
          statusFilter: widget.statusFilter,
        ),
      );
    }
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

  void _load() {
    // Always re-fetches from API (used on date change or manual refresh)
    _bloc.add(
      LoadOrderList(
        fromDate: _fmt(_from),
        toDate: _fmt(_to),
        statusFilter: widget.statusFilter,
      ),
    );
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _from, end: _to),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: widget.accentColor,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (range != null) {
      setState(() {
        _from = range.start;
        _to = range.end;
      });
      _load(); // date changed → must re-fetch
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          body: SafeArea(
            child: Column(
              children: [
                _Header(
                  from: _from,
                  to: _to,
                  onDateTap: _pickDateRange,
                  title: widget.title,
                  subtitle: widget.subtitle,
                  accentColor: widget.accentColor,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: BlocBuilder<OrderListBloc, OrderListState>(
                    builder: (context, state) {
                      if (state is OrderListLoading) {
                        return const _LoadingView();
                      }
                      if (state is OrderListError) {
                        return _ErrorView(
                          message: state.message,
                          onRetry: _load,
                        );
                      }
                      if (state is OrderListLoaded) {
                        if (state.orders.isEmpty) {
                          return _EmptyView(onRefresh: _load);
                        }
                        return _OrderList(
                          orders: state.orders,
                          onRefresh: () async => _load(),
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
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final DateTime from;
  final DateTime to;
  final ValueChanged<BuildContext> onDateTap;
  final String title;
  final String subtitle;
  final Color accentColor;

  const _Header({
    required this.from,
    required this.to,
    required this.onDateTap,
    required this.title,
    required this.subtitle,
    required this.accentColor,
  });

  String _label(DateTime d) {
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
    return '${d.day} ${months[d.month]} ${d.year}';
  }

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
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 13, color: Colors.black45),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GestureDetector(
            onTap: () => onDateTap(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    size: 16,
                    color: accentColor,
                  ),
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _label(from),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '→ ${_label(to)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Order List ───────────────────────────────────────────────────────────────

class _OrderList extends StatelessWidget {
  final List<OrderListItem> orders;
  final Future<void> Function() onRefresh;

  const _OrderList({required this.orders, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: Colors.black,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        itemCount: orders.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) return _SummaryStrip(orders: orders);
          final order = orders[i - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _OrderCard(
              order: order,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderDetailView(
                    orderId: order.id,
                    orderNo: order.orderNo,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Summary Strip ────────────────────────────────────────────────────────────

class _SummaryStrip extends StatelessWidget {
  final List<OrderListItem> orders;
  const _SummaryStrip({required this.orders});

  String _abbrev(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final total = orders.fold(0.0, (s, o) => s + o.netPayable);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 4),
      child: Row(
        children: [
          Expanded(
            child: _StripTile(
              label: 'Total Orders',
              value: '${orders.length}',
              icon: Icons.receipt_long_rounded,
              color: const Color(0xFF2196F3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StripTile(
              label: 'Total Value',
              value: '৳${_abbrev(total)}',
              icon: Icons.account_balance_wallet_outlined,
              color: const Color(0xFF4CAF50),
            ),
          ),
        ],
      ),
    );
  }
}

class _StripTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StripTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border(left: BorderSide(color: color, width: 3)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D000000),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black45,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ─── Order Card ───────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final OrderListItem order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

  Color get _statusColor {
    switch (order.status) {
      case -1:
        return Colors.black45;
      case 0:
        return const Color(0xFFFFC107);
      case 2:
        return const Color(0xFF9C27B0);
      case 3:
        return const Color(0xFF2196F3);
      case 5:
        return const Color(0xFF4CAF50);
      default:
        return Colors.black26;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: _statusColor, width: 3)),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order.orderNo,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  _StatusBadge(label: order.statusName, color: _statusColor),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.person_outline_rounded,
                    size: 14,
                    color: Colors.black38,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      order.partyName,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        letterSpacing: -0.1,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 13,
                        color: Colors.black38,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        order.formattedDate,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Net Payable',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.black38,
                          letterSpacing: 0.1,
                        ),
                      ),
                      Text(
                        '৳${order.netPayable.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4CAF50),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (order.balance != 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.account_balance_rounded,
                        size: 13,
                        color: Color(0xFFF57F17),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Balance: ৳${order.balance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFF57F17),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.2,
      ),
    ),
  );
}

// ─── Loading / Shimmer ────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
    itemCount: 5,
    itemBuilder: (_, _) => const Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: _ShimmerCard(),
    ),
  );
}

class _ShimmerCard extends StatefulWidget {
  const _ShimmerCard();

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
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
        height: 120,
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [_bar(140, 14), _bar(60, 14)],
            ),
            const SizedBox(height: 10),
            _bar(200, 12),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [_bar(80, 12), _bar(90, 16)],
            ),
          ],
        ),
      ),
    ),
  );

  Widget _bar(double w, double h) => Container(
    width: w,
    height: h,
    decoration: BoxDecoration(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(6),
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
            'Failed to load orders',
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

// ─── Empty View ───────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final VoidCallback onRefresh;
  const _EmptyView({required this.onRefresh});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.receipt_long_outlined,
            size: 36,
            color: Colors.grey.shade300,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'No orders found',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Try a different date range',
          style: TextStyle(fontSize: 13, color: Colors.black45),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: onRefresh,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
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
              'Refresh',
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
  );
}
