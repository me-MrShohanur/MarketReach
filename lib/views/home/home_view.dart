import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marketing/bloc/chalan-deleiver/repository/get_chalan_repo.dart';
import 'package:marketing/bloc/order/pending_order_block.dart';
import 'package:marketing/constants/routes.dart';
import 'package:marketing/services/auth_service.dart';
import 'package:marketing/services/provider/current_user.dart';
import 'package:marketing/views/home/subpages/delivery/bill_view.dart';
import 'package:marketing/views/home/subpages/delivery/delivered_view.dart';
import 'package:marketing/views/home/subpages/delivery/pending_delivery.dart';
import 'package:marketing/views/home/subpages/pending_order.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late final OrderListBloc _bloc;
  final ChallanRepository _challanRepository = ChallanRepository();

  bool _isRefreshing = false;

  // Challan counts fetched from the dedicated API
  int _pendingDeliveryCount = 0;
  int _deliveredCount = 0;
  int _billCount = 0;
  bool _challanLoading = true;
  String? _challanError;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _loadChallanCounts();
  }

  void _loadInitialData() {
    final now = DateTime.now();
    final from = now.subtract(const Duration(days: 30));
    _bloc = OrderListBloc()
      ..add(
        LoadOrderList(
          fromDate: _fmt(from),
          toDate: _fmt(now),
          statusFilter: const [],
        ),
      );
  }

  /// Fetches all three challan type counts in parallel from the Challan API.
  Future<void> _loadChallanCounts() async {
    setState(() {
      _challanLoading = true;
      _challanError = null;
    });
    try {
      final results = await Future.wait([
        _challanRepository.getChallanBill(
          partyId: 222,
          compId: CurrentUser.compId,
          types: 1, // Pending Delivery
          token: CurrentUser.token,
        ),
        _challanRepository.getChallanBill(
          partyId: 222,
          compId: CurrentUser.compId,
          types: 2, // Delivered (Chalan)
          token: CurrentUser.token,
        ),
        _challanRepository.getChallanBill(
          partyId: 222,
          compId: CurrentUser.compId,
          types: 3, // Bill
          token: CurrentUser.token,
        ),
      ]);

      if (mounted) {
        setState(() {
          _pendingDeliveryCount = results[0].length;
          _deliveredCount = results[1].length;
          _billCount = results[2].length;
          _challanLoading = false;
        });
      }
    } catch (e, st) {
      // Print to debug console so the exact cause is visible during development
      debugPrint('[HomeView] Challan load error: $e\n$st');
      if (mounted) {
        // Strip the generic "Exception: " prefix so the banner message is readable
        final msg = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
        setState(() {
          _challanError = msg;
          _challanLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      final now = DateTime.now();
      final from = now.subtract(const Duration(days: 30));
      _bloc.add(
        LoadOrderList(
          fromDate: _fmt(from),
          toDate: _fmt(now),
          statusFilter: const [],
        ),
      );
      // Also refresh challan counts
      await _loadChallanCounts();
      await Future.delayed(const Duration(milliseconds: 500));
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Logout',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.black45),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await AuthService().logout();
      CurrentUser.clear();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          loginRoute,
          (route) => false,
        );
      }
    }
  }

  void _openOrders(
    BuildContext context, {
    required List<int> statusFilter,
    required String title,
    required String subtitle,
    required Color accentColor,
    required List<OrderListItem> allOrders,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PendingOrdersView(
          statusFilter: statusFilter,
          title: title,
          subtitle: subtitle,
          accentColor: accentColor,
          preloadedOrders: allOrders,
        ),
      ),
    );
  }

  void _openPendingDelivery(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PendingDeliveryView()),
    );
  }

  void _openDelivered(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DeliveredView()),
    );
  }

  void _openBill(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BillView()),
    );
  }

  /// Renders a count value for the delivery section cards.
  /// Shows a small spinner while challan data is loading,
  /// and a dash on error — matching the card's accent color.
  Widget _challanValue(String value, Color accentColor) {
    if (_challanLoading) {
      return SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: accentColor),
      );
    }
    if (_challanError != null) {
      return Text(
        '–',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: accentColor,
          letterSpacing: -0.5,
        ),
      );
    }
    return Text(
      value,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: accentColor,
        letterSpacing: -0.5,
      ),
    );
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
            child: BlocBuilder<OrderListBloc, OrderListState>(
              builder: (context, state) {
                final isLoading = state is OrderListLoading && !_isRefreshing;
                final isError = state is OrderListError;
                final orders = state is OrderListLoaded
                    ? state.orders
                    : <OrderListItem>[];

                if (isLoading) return const _HomeShimmer();

                // ── Pending section counts (from order list API) ─────
                final pendingCount = orders
                    .where((o) => o.status == -1 || o.status == 0)
                    .length;
                final verifyCount = orders.where((o) => o.status == 2).length;
                final approveCount = orders.where((o) => o.status == 3).length;
                final toDeliverCount = orders
                    .where((o) => o.status == 5)
                    .length;

                return RefreshIndicator(
                  onRefresh: _refresh,
                  color: Colors.black,
                  backgroundColor: Colors.white,
                  strokeWidth: 2.5,
                  triggerMode: RefreshIndicatorTriggerMode.onEdge,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Header ───────────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _greeting,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black45,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Light',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => _logout(context),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.red.shade100,
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.logout_rounded,
                                      color: Colors.red.shade400,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.trending_up_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // ── Error Banner (order list) ─────────────────
                        if (isError) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF0F0),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.red.shade100,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.wifi_off_rounded,
                                  color: Colors.red.shade400,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'Failed to load data. Pull down to retry.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _refresh,
                                  child: const Text(
                                    'Retry',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // ── Challan Error Banner ──────────────────────
                        if (_challanError != null && !_challanLoading) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF0F0),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.red.shade100,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.wifi_off_rounded,
                                  color: Colors.red.shade400,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'Delivery data failed. Pull down to retry.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _loadChallanCounts,
                                  child: const Text(
                                    'Retry',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // ── Refresh Banner ───────────────────────────
                        if (_isRefreshing) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blue.shade100,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.blue.shade400,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Refreshing data...',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // ════════════════════════════════════════════
                        // SECTION 1 — PENDING  (order list API)
                        // ════════════════════════════════════════════
                        _SectionHeader(
                          label: 'Pending',
                          icon: Icons.hourglass_top_rounded,
                          color: const Color(0xFFFFC107),
                        ),
                        const SizedBox(height: 12),

                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _StatCard(
                                  value: '$pendingCount',
                                  label: 'Pending Orders',
                                  accentColor: const Color(0xFFFFC107),
                                  onTap: () => _openOrders(
                                    context,
                                    statusFilter: const [-1, 0],
                                    title: 'Pending',
                                    subtitle: 'Drafted & Pending Orders',
                                    accentColor: const Color(0xFFFFC107),
                                    allOrders: orders,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _StatCard(
                                  value: '$verifyCount',
                                  label: 'To Verify',
                                  accentColor: const Color(0xFF9C27B0),
                                  onTap: () => _openOrders(
                                    context,
                                    statusFilter: const [2],
                                    title: 'Verify',
                                    subtitle: 'Orders to Verify',
                                    accentColor: const Color(0xFF9C27B0),
                                    allOrders: orders,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _StatCard(
                                  value: '$approveCount',
                                  label: 'To Approve',
                                  accentColor: const Color(0xFF2196F3),
                                  onTap: () => _openOrders(
                                    context,
                                    statusFilter: const [3],
                                    title: 'Approve',
                                    subtitle: 'Orders to Approve',
                                    accentColor: const Color(0xFF2196F3),
                                    allOrders: orders,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _StatCard(
                                  value: '$toDeliverCount',
                                  label: 'To Deliver',
                                  accentColor: const Color(0xFF4CAF50),
                                  onTap: () => _openOrders(
                                    context,
                                    statusFilter: const [5],
                                    title: 'Deliver',
                                    subtitle: 'Orders to Deliver',
                                    accentColor: const Color(0xFF4CAF50),
                                    allOrders: orders,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // ════════════════════════════════════════════
                        // SECTION 2 — DELIVERY  (Challan API, types 1/2/3)
                        // ════════════════════════════════════════════
                        _SectionHeader(
                          label: 'Delivery',
                          icon: Icons.local_shipping_rounded,
                          color: const Color(0xFF4CAF50),
                        ),
                        const SizedBox(height: 12),

                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _ChallanStatCard(
                                  valueWidget: _challanValue(
                                    '$_pendingDeliveryCount',
                                    const Color(0xFFFF5722),
                                  ),
                                  label: 'Pending Delivery',
                                  accentColor: const Color(0xFFFF5722),
                                  onTap: () => _openPendingDelivery(context),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _ChallanStatCard(
                                  valueWidget: _challanValue(
                                    '$_deliveredCount',
                                    const Color(0xFF009688),
                                  ),
                                  label: 'Chalan',
                                  accentColor: const Color(0xFF009688),
                                  onTap: () => _openDelivered(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Expanded(
                              child: _ChallanStatCard(
                                valueWidget: _challanValue(
                                  '$_billCount',
                                  const Color(0xFF607D8B),
                                ),
                                label: 'Bill',
                                accentColor: const Color(0xFF607D8B),
                                onTap: () => _openBill(context),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // ── Quick Actions ────────────────────────────
                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _ActionCard(
                                  icon: Icons.add_shopping_cart_rounded,
                                  label: 'Create Order',
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    createOrderRoute,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ActionCard(
                                  icon: Icons.add_box_rounded,
                                  label: 'Add Product',
                                  onTap: () {},
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SECTION HEADER
// ════════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _SectionHeader({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Divider(color: color.withValues(alpha: 0.2), thickness: 1),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// STAT CARD  — used for order-list counts (string value)
// ════════════════════════════════════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color accentColor;
  final VoidCallback? onTap;

  const _StatCard({
    required this.value,
    required this.label,
    required this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: accentColor, width: 3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: accentColor,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// CHALLAN STAT CARD  — used for delivery-section counts (widget value so we
//                      can swap in a spinner or a dash while loading/error)
// ════════════════════════════════════════════════════════════════════════════

class _ChallanStatCard extends StatelessWidget {
  final Widget valueWidget;
  final String label;
  final Color accentColor;
  final VoidCallback? onTap;

  const _ChallanStatCard({
    required this.valueWidget,
    required this.label,
    required this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: accentColor, width: 3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Minimum height keeps the card stable during the loading state
            SizedBox(
              height: 28,
              child: Align(alignment: Alignment.centerLeft, child: valueWidget),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SHIMMER
// ════════════════════════════════════════════════════════════════════════════

class _HomeShimmer extends StatefulWidget {
  const _HomeShimmer();

  @override
  State<_HomeShimmer> createState() => _HomeShimmerState();
}

class _HomeShimmerState extends State<_HomeShimmer>
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
      builder: (_, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _bar(80, 13),
                      const SizedBox(height: 6),
                      _bar(120, 26),
                    ],
                  ),
                  Row(
                    children: [
                      _box(44, 44, radius: 12),
                      const SizedBox(width: 10),
                      _box(44, 44, radius: 12),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _bar(80, 15),
              const SizedBox(height: 12),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _cardShimmer()),
                    const SizedBox(width: 10),
                    Expanded(child: _cardShimmer()),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _cardShimmer()),
                    const SizedBox(width: 10),
                    Expanded(child: _cardShimmer()),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _bar(80, 15),
              const SizedBox(height: 12),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _cardShimmer()),
                    const SizedBox(width: 10),
                    Expanded(child: _cardShimmer()),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _cardShimmer(),
              const SizedBox(height: 28),
              _bar(120, 17),
              const SizedBox(height: 12),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _actionShimmer()),
                    const SizedBox(width: 12),
                    Expanded(child: _actionShimmer()),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _cardShimmer() => Opacity(
    opacity: _anim.value,
    child: Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: Colors.grey.shade200, width: 3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [_bar(60, 26), const SizedBox(height: 8), _bar(90, 12)],
      ),
    ),
  );

  Widget _actionShimmer() => Opacity(
    opacity: _anim.value,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _box(28, 28, radius: 6),
          const SizedBox(height: 10),
          _bar(80, 13),
        ],
      ),
    ),
  );

  Widget _bar(double w, double h) => Opacity(
    opacity: _anim.value,
    child: Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
      ),
    ),
  );

  Widget _box(double w, double h, {double radius = 8}) => Opacity(
    opacity: _anim.value,
    child: Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(radius),
      ),
    ),
  );
}

// ════════════════════════════════════════════════════════════════════════════
// ACTION CARD
// ════════════════════════════════════════════════════════════════════════════

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// // lib/views/home/home_view.dart

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:marketing/bloc/order/pending_order_block.dart';
// import 'package:marketing/constants/routes.dart';
// import 'package:marketing/services/auth_service.dart';
// import 'package:marketing/services/provider/current_user.dart';
// import 'package:marketing/views/home/subpages/pending_order.dart';

// class HomeView extends StatefulWidget {
//   const HomeView({super.key});

//   @override
//   State<HomeView> createState() => _HomeViewState();
// }

// class _HomeViewState extends State<HomeView> {
//   late final OrderListBloc _bloc;
//   bool _isRefreshing = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadInitialData();
//   }

//   void _loadInitialData() {
//     final now = DateTime.now();
//     final from = now.subtract(const Duration(days: 30));
//     _bloc = OrderListBloc()
//       ..add(
//         LoadOrderList(
//           fromDate: _fmt(from),
//           toDate: _fmt(now),
//           statusFilter: const [],
//         ),
//       );
//   }

//   @override
//   void dispose() {
//     _bloc.close();
//     super.dispose();
//   }

//   String _fmt(DateTime d) =>
//       '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

//   String get _greeting {
//     final hour = DateTime.now().hour;
//     if (hour < 12) return 'Good Morning';
//     if (hour < 17) return 'Good Afternoon';
//     return 'Good Evening';
//   }

//   Future<void> _refresh() async {
//     if (_isRefreshing) return;

//     setState(() {
//       _isRefreshing = true;
//     });

//     try {
//       final now = DateTime.now();
//       final from = now.subtract(const Duration(days: 30));
//       _bloc.add(
//         LoadOrderList(
//           fromDate: _fmt(from),
//           toDate: _fmt(now),
//           statusFilter: const [],
//         ),
//       );

//       // Wait for the bloc to complete loading
//       await Future.delayed(const Duration(milliseconds: 500));
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isRefreshing = false;
//         });
//       }
//     }
//   }

//   Future<void> _logout(BuildContext context) async {
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: const Text(
//           'Logout',
//           style: TextStyle(fontWeight: FontWeight.w700),
//         ),
//         content: const Text('Are you sure you want to logout?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx, false),
//             child: const Text(
//               'Cancel',
//               style: TextStyle(color: Colors.black45),
//             ),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(ctx, true),
//             child: const Text(
//               'Logout',
//               style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
//             ),
//           ),
//         ],
//       ),
//     );
//     if (confirm == true) {
//       await AuthService().logout();
//       CurrentUser.clear();
//       if (context.mounted) {
//         Navigator.pushNamedAndRemoveUntil(
//           context,
//           loginRoute,
//           (route) => false,
//         );
//       }
//     }
//   }

//   void _openOrders(
//     BuildContext context, {
//     required List<int> statusFilter,
//     required String title,
//     required String subtitle,
//     required Color accentColor,
//     required List<OrderListItem> allOrders,
//   }) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => PendingOrdersView(
//           statusFilter: statusFilter,
//           title: title,
//           subtitle: subtitle,
//           accentColor: accentColor,
//           preloadedOrders: allOrders,
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider.value(
//       value: _bloc,
//       child: AnnotatedRegion<SystemUiOverlayStyle>(
//         value: SystemUiOverlayStyle.dark,
//         child: Scaffold(
//           backgroundColor: const Color(0xFFF5F5F5),
//           body: SafeArea(
//             child: BlocBuilder<OrderListBloc, OrderListState>(
//               builder: (context, state) {
//                 final isLoading = state is OrderListLoading && !_isRefreshing;
//                 final isError = state is OrderListError;
//                 final orders = state is OrderListLoaded
//                     ? state.orders
//                     : <OrderListItem>[];

//                 // Show shimmer only on initial load, not during refresh
//                 if (isLoading) return const _HomeShimmer();

//                 final pendingCount = orders
//                     .where((o) => o.status == -1 || o.status == 0)
//                     .length;
//                 final verifyCount = orders.where((o) => o.status == 2).length;
//                 final approveCount = orders.where((o) => o.status == 3).length;
//                 final deliverCount = orders.where((o) => o.status == 5).length;

//                 return RefreshIndicator(
//                   onRefresh: _refresh,
//                   color: Colors.black,
//                   backgroundColor: Colors.white,
//                   strokeWidth: 2.5,
//                   triggerMode: RefreshIndicatorTriggerMode.onEdge,
//                   child: SingleChildScrollView(
//                     physics: const AlwaysScrollableScrollPhysics(),
//                     padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // ── Header ──────────────────────────────────
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   _greeting,
//                                   style: const TextStyle(
//                                     fontSize: 13,
//                                     color: Colors.black45,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 2),
//                                 const Text(
//                                   'Light',
//                                   style: TextStyle(
//                                     fontSize: 26,
//                                     fontWeight: FontWeight.w700,
//                                     letterSpacing: -0.5,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             Row(
//                               children: [
//                                 GestureDetector(
//                                   onTap: () => _logout(context),
//                                   child: Container(
//                                     width: 44,
//                                     height: 44,
//                                     decoration: BoxDecoration(
//                                       color: Colors.red.shade50,
//                                       borderRadius: BorderRadius.circular(12),
//                                       border: Border.all(
//                                         color: Colors.red.shade100,
//                                         width: 1,
//                                       ),
//                                     ),
//                                     child: Icon(
//                                       Icons.logout_rounded,
//                                       color: Colors.red.shade400,
//                                       size: 20,
//                                     ),
//                                   ),
//                                 ),
//                                 const SizedBox(width: 10),
//                                 Container(
//                                   width: 44,
//                                   height: 44,
//                                   decoration: BoxDecoration(
//                                     color: Colors.black,
//                                     borderRadius: BorderRadius.circular(12),
//                                   ),
//                                   child: const Icon(
//                                     Icons.trending_up_rounded,
//                                     color: Colors.white,
//                                     size: 22,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),

//                         const SizedBox(height: 28),

//                         // ── Error Banner ─────────────────────────────
//                         if (isError) ...[
//                           Container(
//                             width: double.infinity,
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 16,
//                               vertical: 12,
//                             ),
//                             decoration: BoxDecoration(
//                               color: const Color(0xFFFFF0F0),
//                               borderRadius: BorderRadius.circular(12),
//                               border: Border.all(
//                                 color: Colors.red.shade100,
//                                 width: 1,
//                               ),
//                             ),
//                             child: Row(
//                               children: [
//                                 Icon(
//                                   Icons.wifi_off_rounded,
//                                   color: Colors.red.shade400,
//                                   size: 18,
//                                 ),
//                                 const SizedBox(width: 10),
//                                 const Expanded(
//                                   child: Text(
//                                     'Failed to load data. Pull down to retry.',
//                                     style: TextStyle(
//                                       fontSize: 13,
//                                       color: Colors.redAccent,
//                                     ),
//                                   ),
//                                 ),
//                                 GestureDetector(
//                                   onTap: _refresh,
//                                   child: const Text(
//                                     'Retry',
//                                     style: TextStyle(
//                                       fontSize: 13,
//                                       fontWeight: FontWeight.w700,
//                                       color: Colors.redAccent,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           const SizedBox(height: 16),
//                         ],

//                         // Show loading indicator during refresh
//                         if (_isRefreshing) ...[
//                           Container(
//                             margin: const EdgeInsets.only(bottom: 16),
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 16,
//                               vertical: 12,
//                             ),
//                             decoration: BoxDecoration(
//                               color: Colors.blue.shade50,
//                               borderRadius: BorderRadius.circular(12),
//                               border: Border.all(
//                                 color: Colors.blue.shade100,
//                                 width: 1,
//                               ),
//                             ),
//                             child: Row(
//                               children: [
//                                 SizedBox(
//                                   width: 18,
//                                   height: 18,
//                                   child: CircularProgressIndicator(
//                                     strokeWidth: 2,
//                                     color: Colors.blue.shade400,
//                                   ),
//                                 ),
//                                 const SizedBox(width: 10),
//                                 Expanded(
//                                   child: Text(
//                                     'Refreshing data...',
//                                     style: TextStyle(
//                                       fontSize: 13,
//                                       color: Colors.blue.shade700,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],

//                         // ── Stats Grid ───────────────────────────────
//                         GridView.count(
//                           crossAxisCount: 2,
//                           shrinkWrap: true,
//                           physics: const NeverScrollableScrollPhysics(),
//                           crossAxisSpacing: 12,
//                           mainAxisSpacing: 12,
//                           childAspectRatio: 1.45,
//                           children: [
//                             _StatCard(
//                               value: '$deliverCount',
//                               label: 'To Deliver',
//                               accentColor: const Color(0xFF4CAF50),
//                               onTap: () => _openOrders(
//                                 context,
//                                 statusFilter: const [5],
//                                 title: 'Deliver',
//                                 subtitle: 'Orders to Deliver',
//                                 accentColor: const Color(0xFF4CAF50),
//                                 allOrders: orders,
//                               ),
//                             ),
//                             _StatCard(
//                               value: '$pendingCount',
//                               label: 'Pending Orders',
//                               accentColor: const Color(0xFFFFC107),
//                               onTap: () => _openOrders(
//                                 context,
//                                 statusFilter: const [-1, 0],
//                                 title: 'Pending',
//                                 subtitle: 'Drafted & Pending Orders',
//                                 accentColor: const Color(0xFFFFC107),
//                                 allOrders: orders,
//                               ),
//                             ),
//                             _StatCard(
//                               value: '$verifyCount',
//                               label: 'To Verify',
//                               accentColor: const Color(0xFF9C27B0),
//                               onTap: () => _openOrders(
//                                 context,
//                                 statusFilter: const [2],
//                                 title: 'Verify',
//                                 subtitle: 'Orders to Verify',
//                                 accentColor: const Color(0xFF9C27B0),
//                                 allOrders: orders,
//                               ),
//                             ),
//                             _StatCard(
//                               value: '$approveCount',
//                               label: 'To Approve',
//                               accentColor: const Color(0xFF2196F3),
//                               onTap: () => _openOrders(
//                                 context,
//                                 statusFilter: const [3],
//                                 title: 'Approve',
//                                 subtitle: 'Orders to Approve',
//                                 accentColor: const Color(0xFF2196F3),
//                                 allOrders: orders,
//                               ),
//                             ),
//                           ],
//                         ),

//                         const SizedBox(height: 28),

//                         // ── Quick Actions ────────────────────────────
//                         const Text(
//                           'Quick Actions',
//                           style: TextStyle(
//                             fontSize: 17,
//                             fontWeight: FontWeight.w700,
//                             letterSpacing: -0.3,
//                           ),
//                         ),
//                         const SizedBox(height: 12),
//                         Row(
//                           children: [
//                             Expanded(
//                               child: _ActionCard(
//                                 icon: Icons.add_shopping_cart_rounded,
//                                 label: 'Create Order',
//                                 onTap: () => Navigator.pushNamed(
//                                   context,
//                                   createOrderRoute,
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(width: 12),
//                             Expanded(
//                               child: _ActionCard(
//                                 icon: Icons.add_box_rounded,
//                                 label: 'Add Product',
//                                 onTap: () {},
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ── Full Page Shimmer ─────────────────────────────────────────────────────────

// class _HomeShimmer extends StatefulWidget {
//   const _HomeShimmer();

//   @override
//   State<_HomeShimmer> createState() => _HomeShimmerState();
// }

// class _HomeShimmerState extends State<_HomeShimmer>
//     with SingleTickerProviderStateMixin {
//   late final AnimationController _ctrl;
//   late final Animation<double> _anim;

//   @override
//   void initState() {
//     super.initState();
//     _ctrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1200),
//     )..repeat(reverse: true);
//     _anim = Tween<double>(
//       begin: 0.4,
//       end: 1.0,
//     ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
//   }

//   @override
//   void dispose() {
//     _ctrl.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: _anim,
//       builder: (_, _) {
//         return SingleChildScrollView(
//           padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // ── Header shimmer ───────────────────────────────────
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       _bar(80, 13),
//                       const SizedBox(height: 6),
//                       _bar(120, 26),
//                     ],
//                   ),
//                   Row(
//                     children: [
//                       _box(44, 44, radius: 12),
//                       const SizedBox(width: 10),
//                       _box(44, 44, radius: 12),
//                     ],
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 28),

//               // ── Grid shimmer ─────────────────────────────────────
//               GridView.count(
//                 crossAxisCount: 2,
//                 shrinkWrap: true,
//                 physics: const NeverScrollableScrollPhysics(),
//                 crossAxisSpacing: 12,
//                 mainAxisSpacing: 12,
//                 childAspectRatio: 1.45,
//                 children: List.generate(4, (_) => _cardShimmer()),
//               ),

//               const SizedBox(height: 28),

//               // ── Quick Actions label shimmer ───────────────────────
//               _bar(120, 17),
//               const SizedBox(height: 12),

//               // ── Action cards shimmer ─────────────────────────────
//               Row(
//                 children: [
//                   Expanded(child: _actionShimmer()),
//                   const SizedBox(width: 12),
//                   Expanded(child: _actionShimmer()),
//                 ],
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   // Shimmer stat card
//   Widget _cardShimmer() {
//     return Opacity(
//       opacity: _anim.value,
//       child: Container(
//         padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           border: Border(
//             left: BorderSide(color: Colors.grey.shade200, width: 3),
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withValues(alpha: 0.05),
//               blurRadius: 10,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [_bar(60, 26), const SizedBox(height: 8), _bar(90, 12)],
//         ),
//       ),
//     );
//   }

//   // Shimmer action card
//   Widget _actionShimmer() {
//     return Opacity(
//       opacity: _anim.value,
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 24),
//         decoration: BoxDecoration(
//           color: Colors.grey.shade200,
//           borderRadius: BorderRadius.circular(16),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             _box(28, 28, radius: 6),
//             const SizedBox(height: 10),
//             _bar(80, 13),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _bar(double w, double h) => Opacity(
//     opacity: _anim.value,
//     child: Container(
//       width: w,
//       height: h,
//       decoration: BoxDecoration(
//         color: Colors.grey.shade200,
//         borderRadius: BorderRadius.circular(6),
//       ),
//     ),
//   );

//   Widget _box(double w, double h, {double radius = 8}) => Opacity(
//     opacity: _anim.value,
//     child: Container(
//       width: w,
//       height: h,
//       decoration: BoxDecoration(
//         color: Colors.grey.shade200,
//         borderRadius: BorderRadius.circular(radius),
//       ),
//     ),
//   );
// }

// // ── Stat Card ─────────────────────────────────────────────────────────────────

// class _StatCard extends StatelessWidget {
//   final String value;
//   final String label;
//   final Color accentColor;
//   final VoidCallback? onTap;

//   const _StatCard({
//     required this.value,
//     required this.label,
//     required this.accentColor,
//     this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(16),
//       child: Container(
//         padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           border: Border(left: BorderSide(color: accentColor, width: 3)),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withValues(alpha: 0.05),
//               blurRadius: 10,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               value,
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.w700,
//                 color: accentColor,
//                 letterSpacing: -0.5,
//               ),
//             ),
//             const SizedBox(height: 5),
//             Text(
//               label,
//               style: const TextStyle(
//                 fontSize: 12,
//                 color: Colors.black45,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ── Action Card ───────────────────────────────────────────────────────────────
// class _ActionCard extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final VoidCallback onTap;

//   const _ActionCard({
//     required this.icon,
//     required this.label,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 24),
//         decoration: BoxDecoration(
//           color: Colors.black,
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withValues(alpha: 0.15),
//               blurRadius: 12,
//               offset: const Offset(0, 6),
//             ),
//           ],
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, color: Colors.white, size: 28),
//             const SizedBox(height: 10),
//             Text(
//               label,
//               style: const TextStyle(
//                 fontSize: 13,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.white,
//                 letterSpacing: -0.1,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
