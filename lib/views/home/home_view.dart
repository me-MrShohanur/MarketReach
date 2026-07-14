import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marketing/bloc/chalan-deleiver/repository/get_chalan_repo.dart';
import 'package:marketing/bloc/customer/customer_provider.dart';
import 'package:marketing/bloc/order/pending_order_block.dart';
import 'package:marketing/constants/routes.dart';
import 'package:marketing/services/auth_service.dart';
import 'package:marketing/services/models/customer.dart';
import 'package:marketing/services/provider/current_user.dart';
import 'package:marketing/views/home/subpages/delivery/bill_view.dart';
import 'package:marketing/views/home/subpages/delivery/delivered_view.dart';
import 'package:marketing/views/home/subpages/delivery/pending_delivery.dart';
import 'package:marketing/views/home/subpages/pending_order.dart';

// ════════════════════════════════════════════════════════════════════════════
// RESPONSIVE HELPER  (_R)
// ════════════════════════════════════════════════════════════════════════════

class _R {
  static const double _baseWidth = 390.0;
  static const double _minScale = 0.78;
  static const double _maxScale = 1.22;

  static late double _scale;
  static late double screenWidth;
  static late double screenHeight;

  static void init(BuildContext context) {
    final mq = MediaQuery.of(context);
    screenWidth = mq.size.width;
    screenHeight = mq.size.height;
    _scale = (screenWidth / _baseWidth).clamp(_minScale, _maxScale);
  }

  static double dp(double size) => size * _scale;
  static double sp(double size) => size * _scale;
  static double get hPad => (screenWidth * 0.05).clamp(16.0, 28.0);
}

// ════════════════════════════════════════════════════════════════════════════
// HOME VIEW
// ════════════════════════════════════════════════════════════════════════════

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late final OrderListBloc _bloc;
  final ChallanRepository _challanRepository = ChallanRepository();
  bool _isRefreshing = false;

  int _pendingDeliveryCount = 0;
  int _deliveredCount = 0;
  int _billCount = 0;
  bool _challanLoading = true;
  String? _challanError;

  // ✅ Refresh control
  final ScrollController _scrollController = ScrollController();
  double _pullDistance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _loadChallanCounts();
    _scrollController.addListener(_onScroll);
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

  Future<void> _loadChallanCounts() async {
    setState(() {
      _challanLoading = true;
      _challanError = null;
    });
    try {
      final results = await Future.wait([
        _challanRepository.getChallanBill(
          partyId: CurrentUser.customerID,
          compId: CurrentUser.compId,
          types: 1,
          token: CurrentUser.token,
        ),
        _challanRepository.getChallanBill(
          partyId: CurrentUser.customerID,
          compId: CurrentUser.compId,
          types: 2,
          token: CurrentUser.token,
        ),
        _challanRepository.getChallanBill(
          partyId: CurrentUser.customerID,
          compId: CurrentUser.compId,
          types: 3,
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
    } catch (e) {
      debugPrint('[HomeView] Challan load error: $e');
      if (mounted) {
        setState(() {
          _challanError = e.toString().replaceFirst(
            RegExp(r'^Exception:\s*'),
            '',
          );
          _challanLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _bloc.close();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollController.position.pixels;
    if (offset < 0) {
      setState(() {
        _pullDistance = offset.abs();
      });
    } else {
      if (_pullDistance != 0) {
        setState(() {
          _pullDistance = 0;
        });
      }
    }
  }

  String _fmt(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
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

      await _loadChallanCounts();
      await HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('Refresh error: $e');
      await HapticFeedback.heavyImpact();
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_R.dp(16)),
        ),
        title: Text(
          'Logout',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: _R.sp(16)),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(fontSize: _R.sp(14)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.black45, fontSize: _R.sp(14)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Logout',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
                fontSize: _R.sp(14),
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await AuthService().logout();
      CurrentUser.clear();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, loginRoute, (r) => false);
      }
    }
  }

  // ── Navigation helpers ──────────────────────────────────────────────────
  Future<void> _openOrders(
    BuildContext context, {
    required List<int> statusFilter,
    required String title,
    required String subtitle,
    required Color accentColor,
    required List<OrderListItem> allOrders,
  }) async {
    final shouldRefresh = await Navigator.push(
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

    if (shouldRefresh == true) {
      _refresh();
    }
  }

  void _openPendingDelivery(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const PendingDeliveryView()),
  );

  void _openDelivered(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const DeliveredView()),
  );

  void _openBill(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const BillView()),
  );

  Widget _challanValue(String value, Color accentColor) {
    if (_challanLoading) {
      return SizedBox(
        width: _R.dp(18),
        height: _R.dp(18),
        child: CircularProgressIndicator(strokeWidth: 2, color: accentColor),
      );
    }
    if (_challanError != null) {
      return Text(
        '–',
        style: TextStyle(
          fontSize: _R.sp(22),
          fontWeight: FontWeight.w700,
          color: accentColor,
          letterSpacing: -0.5,
        ),
      );
    }
    return Text(
      value,
      style: TextStyle(
        fontSize: _R.sp(22),
        fontWeight: FontWeight.w700,
        color: accentColor,
        letterSpacing: -0.5,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _R.init(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _bloc),
        BlocProvider(create: (context) => CustomerBloc()..add(LoadCustomers())),
      ],
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

                final pendingCount = orders
                    .where((o) => o.status == -1 || o.status == 0)
                    .length;
                final verifyCount = orders.where((o) => o.status == 1).length;
                final approveCount = orders.where((o) => o.status == 3).length;
                final toDeliverCount = orders
                    .where((o) => o.status == 5)
                    .length;

                return RefreshIndicator(
                  onRefresh: _refresh,
                  color: Colors.black,
                  backgroundColor: Colors.white,
                  strokeWidth: 3.0,
                  displacement: _R.dp(60),
                  edgeOffset: _R.dp(20),
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: _CustomRefreshHeader(
                          pullDistance: _pullDistance,
                          isRefreshing: _isRefreshing,
                          maxPullDistance: _R.dp(100),
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            _R.hPad,
                            0,
                            _R.hPad,
                            _R.dp(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Header ─────────────────────────────────
                              _buildHeader(context),

                              SizedBox(height: _R.dp(16)),

                              // ── Banners ────────────────────────────────
                              if (isError || _challanError != null)
                                _buildErrorBanner(),
                              if (_isRefreshing) _buildRefreshBanner(),
                              // ══════════════════════════════════════════
                              // ORDER SECTION
                              // ══════════════════════════════════════════
                              _SectionHeader(
                                label: 'Order',
                                icon: Icons.shopping_cart_rounded,
                                color: const Color(0xFFFFC107),
                              ),
                              SizedBox(height: _R.dp(12)),

                              IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: _StatCard(
                                        value: '$pendingCount',
                                        label: 'Pending Confirm',
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
                                    SizedBox(width: _R.dp(12)),
                                    Expanded(
                                      child: _StatCard(
                                        value: '$verifyCount',
                                        label: 'To Verify',
                                        accentColor: const Color(0xFF9C27B0),
                                        onTap: () => _openOrders(
                                          context,
                                          statusFilter: const [1],
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
                              SizedBox(height: _R.dp(12)),

                              IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
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
                                    SizedBox(width: _R.dp(12)),
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

                              SizedBox(height: _R.dp(20)),

                              // ══════════════════════════════════════════
                              // BILL SECTION
                              // ══════════════════════════════════════════
                              _SectionHeader(
                                label: 'Bill',
                                icon: Icons.receipt_long_rounded,
                                color: const Color(0xFF607D8B),
                              ),
                              SizedBox(height: _R.dp(12)),

                              IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: _ChallanStatCard(
                                        valueWidget: _challanValue(
                                          '$_pendingDeliveryCount',
                                          const Color(0xFFFF5722),
                                        ),
                                        label: 'Pending Delivery',
                                        accentColor: const Color(0xFFFF5722),
                                        onTap: () =>
                                            _openPendingDelivery(context),
                                      ),
                                    ),
                                    SizedBox(width: _R.dp(12)),
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
                              SizedBox(height: _R.dp(12)),

                              _ChallanStatCard(
                                valueWidget: _challanValue(
                                  '$_billCount',
                                  const Color(0xFF607D8B),
                                ),
                                label: 'Bill',
                                accentColor: const Color(0xFF607D8B),
                                onTap: () => _openBill(context),
                              ),

                              SizedBox(height: _R.dp(24)),

                              // ── Quick Actions ──────────────────────────
                              Text(
                                'Quick Actions',
                                style: TextStyle(
                                  fontSize: _R.sp(17),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              SizedBox(height: _R.dp(12)),

                              IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
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
                                    SizedBox(width: _R.dp(12)),
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

                              SizedBox(height: _R.dp(20)),

                              // ✅ Last updated timestamp
                              Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: _R.dp(8),
                                  horizontal: _R.dp(16),
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                    _R.dp(12),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: _R.dp(8),
                                      offset: Offset(0, _R.dp(2)),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.access_time_rounded,
                                      size: _R.dp(14),
                                      color: Colors.black38,
                                    ),
                                    SizedBox(width: _R.dp(6)),
                                    Text(
                                      'Updated ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        fontSize: _R.sp(11),
                                        color: Colors.black38,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: _R.dp(10)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ── Sub-builders ─────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    final btnSize = _R.dp(44);
    final btnRadius = _R.dp(12);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _greeting,
              style: TextStyle(fontSize: _R.sp(13), color: Colors.black45),
            ),
            SizedBox(height: _R.dp(4)),
            BlocBuilder<CustomerBloc, CustomerState>(
              builder: (context, customerState) {
                String openingBalance = '0.00';
                if (customerState is CustomerLoaded) {
                  final balance =
                      customerState.selectedCustomer?.openingBalance ?? 0.0;
                  openingBalance = balance.toStringAsFixed(2);
                }
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: _R.dp(11),
                      color: Colors.black38,
                    ),
                    SizedBox(width: _R.dp(4)),
                    Text(
                      'Balance ৳$openingBalance',
                      style: TextStyle(
                        fontSize: _R.sp(11),
                        color: Colors.black38,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () => _logout(context),
              child: Container(
                width: btnSize,
                height: btnSize,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(btnRadius),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: Colors.red.shade400,
                  size: _R.dp(20),
                ),
              ),
            ),
            SizedBox(width: _R.dp(10)),
            Container(
              width: btnSize,
              height: btnSize,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black, Colors.grey.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(btnRadius),
              ),
              child: Icon(
                Icons.trending_up_rounded,
                color: Colors.white,
                size: _R.dp(22),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorBanner() => Padding(
    padding: EdgeInsets.only(bottom: _R.dp(16)),
    child: Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: _R.dp(16), vertical: _R.dp(12)),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(_R.dp(12)),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, color: Colors.red, size: _R.dp(18)),
          SizedBox(width: _R.dp(10)),
          Expanded(
            child: Text(
              'Failed to load data. Pull down to retry.',
              style: TextStyle(fontSize: _R.sp(13), color: Colors.redAccent),
            ),
          ),
          GestureDetector(
            onTap: _refresh,
            child: Text(
              'Retry',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.redAccent,
                fontSize: _R.sp(13),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildRefreshBanner() => Padding(
    padding: EdgeInsets.only(bottom: _R.dp(16)),
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: _R.dp(16), vertical: _R.dp(12)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(_R.dp(12)),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          SizedBox(
            width: _R.dp(18),
            height: _R.dp(18),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
            ),
          ),
          SizedBox(width: _R.dp(10)),
          Text(
            'Refreshing data...',
            style: TextStyle(
              fontSize: _R.sp(13),
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    ),
  );
}

// ════════════════════════════════════════════════════════════════════════════
// CUSTOM REFRESH HEADER
// ════════════════════════════════════════════════════════════════════════════

class _CustomRefreshHeader extends StatelessWidget {
  final double pullDistance;
  final bool isRefreshing;
  final double maxPullDistance;

  const _CustomRefreshHeader({
    required this.pullDistance,
    required this.isRefreshing,
    required this.maxPullDistance,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (pullDistance / maxPullDistance).clamp(0.0, 1.0);
    final isReady = progress >= 1.0 && !isRefreshing;

    if (pullDistance <= 0 && !isRefreshing) {
      return const SizedBox.shrink();
    }

    return Container(
      height: _R.dp(70),
      alignment: Alignment.center,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: isRefreshing
            ? _RefreshingState()
            : _PullToRefreshState(
                progress: progress,
                isReady: isReady,
                pullDistance: pullDistance,
              ),
      ),
    );
  }
}

// ── Pull to Refresh State ──────────────────────────────────────────────────

class _PullToRefreshState extends StatelessWidget {
  final double progress;
  final bool isReady;
  final double pullDistance;

  const _PullToRefreshState({
    required this.progress,
    required this.isReady,
    required this.pullDistance,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: _R.dp(46),
              height: _R.dp(46),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: _R.dp(10),
                    offset: Offset(0, _R.dp(3)),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: _R.dp(40),
              height: _R.dp(40),
              child: CircularProgressIndicator(
                value: isReady ? 1.0 : progress,
                strokeWidth: 3,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isReady ? Colors.green : Colors.black,
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isReady ? Icons.check_rounded : Icons.arrow_downward_rounded,
                key: ValueKey<bool>(isReady),
                color: isReady ? Colors.green : Colors.black54,
                size: _R.dp(16),
              ),
            ),
          ],
        ),
        if (pullDistance > _R.dp(30)) ...[
          SizedBox(height: _R.dp(6)),
          AnimatedOpacity(
            opacity: progress.clamp(0.0, 1.0),
            duration: const Duration(milliseconds: 200),
            child: Text(
              isReady ? 'Release to refresh ✨' : 'Pull to refresh',
              style: TextStyle(
                fontSize: _R.sp(11),
                fontWeight: FontWeight.w500,
                color: isReady ? Colors.green : Colors.black54,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Refreshing State ──────────────────────────────────────────────────────

class _RefreshingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: _R.dp(46),
              height: _R.dp(46),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: _R.dp(10),
                    offset: Offset(0, _R.dp(3)),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: _R.dp(40),
              height: _R.dp(40),
              child: const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              ),
            ),
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) {
                return Transform.rotate(
                  angle: value * 2 * 3.14159,
                  child: Icon(
                    Icons.refresh_rounded,
                    color: Colors.black87,
                    size: _R.dp(16),
                  ),
                );
              },
            ),
          ],
        ),
        SizedBox(height: _R.dp(6)),
        Text(
          'Refreshing... 🔄',
          style: TextStyle(
            fontSize: _R.sp(11),
            fontWeight: FontWeight.w500,
            color: Colors.black54,
            letterSpacing: 0.2,
          ),
        ),
      ],
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
          padding: EdgeInsets.all(_R.dp(6)),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(_R.dp(8)),
          ),
          child: Icon(icon, size: _R.dp(16), color: color),
        ),
        SizedBox(width: _R.dp(8)),
        Text(
          label,
          style: TextStyle(
            fontSize: _R.sp(15),
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: -0.2,
          ),
        ),
        SizedBox(width: _R.dp(8)),
        Expanded(
          child: Divider(color: color.withValues(alpha: 0.2), thickness: 1),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// STAT CARD
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
      borderRadius: BorderRadius.circular(_R.dp(16)),
      child: Container(
        constraints: BoxConstraints(minHeight: _R.dp(74)),
        padding: EdgeInsets.symmetric(
          horizontal: _R.dp(14),
          vertical: _R.dp(14),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_R.dp(16)),
          border: Border(
            left: BorderSide(color: accentColor, width: _R.dp(3)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: _R.dp(10),
              offset: Offset(0, _R.dp(4)),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: _R.sp(22),
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            SizedBox(height: _R.dp(4)),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: _R.sp(12),
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
// CHALLAN STAT CARD
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
      borderRadius: BorderRadius.circular(_R.dp(16)),
      child: Container(
        constraints: BoxConstraints(minHeight: _R.dp(74)),
        padding: EdgeInsets.symmetric(
          horizontal: _R.dp(14),
          vertical: _R.dp(14),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_R.dp(16)),
          border: Border(
            left: BorderSide(color: accentColor, width: _R.dp(3)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: _R.dp(10),
              offset: Offset(0, _R.dp(4)),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: _R.dp(28),
              child: Align(alignment: Alignment.centerLeft, child: valueWidget),
            ),
            SizedBox(height: _R.dp(4)),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: _R.sp(12),
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
        padding: EdgeInsets.symmetric(vertical: _R.dp(24)),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.grey.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(_R.dp(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: _R.dp(12),
              offset: Offset(0, _R.dp(6)),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: _R.dp(28)),
            SizedBox(height: _R.dp(10)),
            Text(
              label,
              style: TextStyle(
                fontSize: _R.sp(13),
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
    _R.init(context);
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(_R.hPad, _R.dp(20), _R.hPad, _R.dp(16)),
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
                    SizedBox(height: _R.dp(6)),
                    _bar(120, 26),
                  ],
                ),
                Row(
                  children: [
                    _box(44, 44, r: 12),
                    SizedBox(width: _R.dp(10)),
                    _box(44, 44, r: 12),
                  ],
                ),
              ],
            ),
            SizedBox(height: _R.dp(28)),
            _bar(80, 15),
            SizedBox(height: _R.dp(12)),
            _rowCards(),
            SizedBox(height: _R.dp(12)),
            _rowCards(),
            SizedBox(height: _R.dp(20)),
            _bar(80, 15),
            SizedBox(height: _R.dp(12)),
            _rowCards(),
            SizedBox(height: _R.dp(12)),
            _card(),
            SizedBox(height: _R.dp(24)),
            _bar(120, 17),
            SizedBox(height: _R.dp(12)),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _action()),
                  SizedBox(width: _R.dp(12)),
                  Expanded(child: _action()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowCards() => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _card()),
        SizedBox(width: _R.dp(12)),
        Expanded(child: _card()),
      ],
    ),
  );

  Widget _card() => Opacity(
    opacity: _anim.value,
    child: Container(
      constraints: BoxConstraints(minHeight: _R.dp(74)),
      padding: EdgeInsets.all(_R.dp(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_R.dp(16)),
        border: Border(
          left: BorderSide(color: Colors.grey.shade200, width: _R.dp(3)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: _R.dp(10),
            offset: Offset(0, _R.dp(4)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _bar(60, 26),
          SizedBox(height: _R.dp(8)),
          _bar(90, 12),
        ],
      ),
    ),
  );

  Widget _action() => Opacity(
    opacity: _anim.value,
    child: Container(
      padding: EdgeInsets.symmetric(vertical: _R.dp(24)),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(_R.dp(16)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _box(28, 28, r: 6),
          SizedBox(height: _R.dp(10)),
          _bar(80, 13),
        ],
      ),
    ),
  );

  Widget _bar(double w, double h) => Opacity(
    opacity: _anim.value,
    child: Container(
      width: _R.dp(w),
      height: _R.dp(h),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(_R.dp(6)),
      ),
    ),
  );

  Widget _box(double w, double h, {double r = 8}) => Opacity(
    opacity: _anim.value,
    child: Container(
      width: _R.dp(w),
      height: _R.dp(h),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(_R.dp(r)),
      ),
    ),
  );
}
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:marketing/bloc/chalan-deleiver/repository/get_chalan_repo.dart';
// import 'package:marketing/bloc/order/pending_order_block.dart';
// import 'package:marketing/constants/routes.dart';
// import 'package:marketing/services/auth_service.dart';
// import 'package:marketing/services/provider/current_user.dart';
// import 'package:marketing/views/home/subpages/delivery/bill_view.dart';
// import 'package:marketing/views/home/subpages/delivery/delivered_view.dart';
// import 'package:marketing/views/home/subpages/delivery/pending_delivery.dart';
// import 'package:marketing/views/home/subpages/pending_order.dart';

// // ════════════════════════════════════════════════════════════════════════════
// // RESPONSIVE HELPER  (_R)
// // ════════════════════════════════════════════════════════════════════════════

// class _R {
//   static const double _baseWidth = 390.0;
//   static const double _minScale = 0.78;
//   static const double _maxScale = 1.22;

//   static late double _scale;
//   static late double screenWidth;
//   static late double screenHeight;

//   static void init(BuildContext context) {
//     final mq = MediaQuery.of(context);
//     screenWidth = mq.size.width;
//     screenHeight = mq.size.height;
//     _scale = (screenWidth / _baseWidth).clamp(_minScale, _maxScale);
//   }

//   static double dp(double size) => size * _scale;
//   static double sp(double size) => size * _scale;
//   static double get hPad => (screenWidth * 0.05).clamp(16.0, 28.0);
// }

// // ════════════════════════════════════════════════════════════════════════════
// // HOME VIEW
// // ════════════════════════════════════════════════════════════════════════════

// class HomeView extends StatefulWidget {
//   const HomeView({super.key});

//   @override
//   State<HomeView> createState() => _HomeViewState();
// }

// class _HomeViewState extends State<HomeView> {
//   late final OrderListBloc _bloc;
//   final ChallanRepository _challanRepository = ChallanRepository();
//   bool _isRefreshing = false;

//   int _pendingDeliveryCount = 0;
//   int _deliveredCount = 0;
//   int _billCount = 0;
//   bool _challanLoading = true;
//   String? _challanError;

//   // ✅ Refresh control
//   final ScrollController _scrollController = ScrollController();
//   double _pullDistance = 0.0;

//   @override
//   void initState() {
//     super.initState();
//     _loadInitialData();
//     _loadChallanCounts();
//     _scrollController.addListener(_onScroll);
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

//   Future<void> _loadChallanCounts() async {
//     setState(() {
//       _challanLoading = true;
//       _challanError = null;
//     });
//     try {
//       final results = await Future.wait([
//         _challanRepository.getChallanBill(
//           partyId: CurrentUser.customerID,
//           compId: CurrentUser.compId,
//           types: 1,
//           token: CurrentUser.token,
//         ),
//         _challanRepository.getChallanBill(
//           partyId: CurrentUser.customerID,
//           compId: CurrentUser.compId,
//           types: 2,
//           token: CurrentUser.token,
//         ),
//         _challanRepository.getChallanBill(
//           partyId: CurrentUser.customerID,
//           compId: CurrentUser.compId,
//           types: 3,
//           token: CurrentUser.token,
//         ),
//       ]);
//       if (mounted) {
//         setState(() {
//           _pendingDeliveryCount = results[0].length;
//           _deliveredCount = results[1].length;
//           _billCount = results[2].length;
//           _challanLoading = false;
//         });
//       }
//     } catch (e) {
//       debugPrint('[HomeView] Challan load error: $e');
//       if (mounted) {
//         setState(() {
//           _challanError = e.toString().replaceFirst(
//             RegExp(r'^Exception:\s*'),
//             '',
//           );
//           _challanLoading = false;
//         });
//       }
//     }
//   }

//   @override
//   void dispose() {
//     _bloc.close();
//     _scrollController.removeListener(_onScroll);
//     _scrollController.dispose();
//     super.dispose();
//   }

//   void _onScroll() {
//     // ✅ Track pull distance for custom refresh
//     final offset = _scrollController.position.pixels;
//     if (offset < 0) {
//       setState(() {
//         _pullDistance = offset.abs();
//       });
//     } else {
//       if (_pullDistance != 0) {
//         setState(() {
//           _pullDistance = 0;
//         });
//       }
//     }
//   }

//   String _fmt(DateTime d) =>
//       '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

//   String get _greeting {
//     final h = DateTime.now().hour;
//     if (h < 12) return 'Good Morning';
//     if (h < 17) return 'Good Afternoon';
//     return 'Good Evening';
//   }

//   // ✅ Refresh the whole page
//   Future<void> _refresh() async {
//     if (_isRefreshing) return;

//     setState(() => _isRefreshing = true);
//     try {
//       final now = DateTime.now();
//       final from = now.subtract(const Duration(days: 30));

//       // Refresh orders
//       _bloc.add(
//         LoadOrderList(
//           fromDate: _fmt(from),
//           toDate: _fmt(now),
//           statusFilter: const [],
//         ),
//       );

//       // Refresh challan counts
//       await _loadChallanCounts();

//       // Haptic feedback
//       await HapticFeedback.lightImpact();
//     } catch (e) {
//       debugPrint('Refresh error: $e');
//       await HapticFeedback.heavyImpact();
//     } finally {
//       if (mounted) {
//         setState(() => _isRefreshing = false);
//         // Animate back to top
//         _scrollController.animateTo(
//           0,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       }
//     }
//   }

//   Future<void> _logout(BuildContext context) async {
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(_R.dp(16)),
//         ),
//         title: Text(
//           'Logout',
//           style: TextStyle(fontWeight: FontWeight.w700, fontSize: _R.sp(16)),
//         ),
//         content: Text(
//           'Are you sure you want to logout?',
//           style: TextStyle(fontSize: _R.sp(14)),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx, false),
//             child: Text(
//               'Cancel',
//               style: TextStyle(color: Colors.black45, fontSize: _R.sp(14)),
//             ),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(ctx, true),
//             child: Text(
//               'Logout',
//               style: TextStyle(
//                 color: Colors.red,
//                 fontWeight: FontWeight.w600,
//                 fontSize: _R.sp(14),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//     if (confirm == true) {
//       await AuthService().logout();
//       CurrentUser.clear();
//       if (context.mounted) {
//         Navigator.pushNamedAndRemoveUntil(context, loginRoute, (r) => false);
//       }
//     }
//   }

//   // ── Navigation helpers ──────────────────────────────────────────────────

//   Future<void> _openOrders(
//     BuildContext context, {
//     required List<int> statusFilter,
//     required String title,
//     required String subtitle,
//     required Color accentColor,
//     required List<OrderListItem> allOrders,
//   }) async {
//     final shouldRefresh = await Navigator.push(
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

//     if (shouldRefresh == true) {
//       _refresh();
//     }
//   }

//   void _openPendingDelivery(BuildContext context) => Navigator.push(
//     context,
//     MaterialPageRoute(builder: (_) => const PendingDeliveryView()),
//   );

//   void _openDelivered(BuildContext context) => Navigator.push(
//     context,
//     MaterialPageRoute(builder: (_) => const DeliveredView()),
//   );

//   void _openBill(BuildContext context) => Navigator.push(
//     context,
//     MaterialPageRoute(builder: (_) => const BillView()),
//   );

//   Widget _challanValue(String value, Color accentColor) {
//     if (_challanLoading) {
//       return SizedBox(
//         width: _R.dp(18),
//         height: _R.dp(18),
//         child: CircularProgressIndicator(strokeWidth: 2, color: accentColor),
//       );
//     }
//     if (_challanError != null) {
//       return Text(
//         '–',
//         style: TextStyle(
//           fontSize: _R.sp(22),
//           fontWeight: FontWeight.w700,
//           color: accentColor,
//           letterSpacing: -0.5,
//         ),
//       );
//     }
//     return Text(
//       value,
//       style: TextStyle(
//         fontSize: _R.sp(22),
//         fontWeight: FontWeight.w700,
//         color: accentColor,
//         letterSpacing: -0.5,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     _R.init(context);

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

//                 if (isLoading) return const _HomeShimmer();

//                 final pendingCount = orders
//                     .where((o) => o.status == -1 || o.status == 0)
//                     .length;
//                 final verifyCount = orders.where((o) => o.status == 1).length;
//                 final approveCount = orders.where((o) => o.status == 3).length;
//                 final toDeliverCount = orders
//                     .where((o) => o.status == 5)
//                     .length;

//                 // ✅ Using RefreshIndicator for reliable pull-to-refresh
//                 return RefreshIndicator(
//                   onRefresh: _refresh,
//                   color: Colors.black,
//                   backgroundColor: Colors.white,
//                   strokeWidth: 3.0,
//                   displacement: _R.dp(60),
//                   edgeOffset: _R.dp(20),
//                   child: CustomScrollView(
//                     controller: _scrollController,
//                     physics: const AlwaysScrollableScrollPhysics(),
//                     slivers: [
//                       // ✅ Beautiful refresh header that shows during pull
//                       SliverToBoxAdapter(
//                         child: _CustomRefreshHeader(
//                           pullDistance: _pullDistance,
//                           isRefreshing: _isRefreshing,
//                           maxPullDistance: _R.dp(100),
//                         ),
//                       ),

//                       SliverToBoxAdapter(
//                         child: Padding(
//                           padding: EdgeInsets.fromLTRB(
//                             _R.hPad,
//                             0,
//                             _R.hPad,
//                             _R.dp(20),
//                           ),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               // ── Header ─────────────────────────────────
//                               _buildHeader(context),
//                               SizedBox(height: _R.dp(20)),

//                               // ── Banners ────────────────────────────────
//                               if (isError || _challanError != null)
//                                 _buildErrorBanner(),
//                               if (_isRefreshing) _buildRefreshBanner(),

//                               // ══════════════════════════════════════════
//                               // ORDER SECTION
//                               // ══════════════════════════════════════════
//                               _SectionHeader(
//                                 label: 'Order',
//                                 icon: Icons.shopping_cart_rounded,
//                                 color: const Color(0xFFFFC107),
//                               ),
//                               SizedBox(height: _R.dp(12)),

//                               IntrinsicHeight(
//                                 child: Row(
//                                   crossAxisAlignment:
//                                       CrossAxisAlignment.stretch,
//                                   children: [
//                                     Expanded(
//                                       child: _StatCard(
//                                         value: '$pendingCount',
//                                         label: 'Pending Confirm',
//                                         accentColor: const Color(0xFFFFC107),
//                                         onTap: () => _openOrders(
//                                           context,
//                                           statusFilter: const [-1, 0],
//                                           title: 'Pending',
//                                           subtitle: 'Drafted & Pending Orders',
//                                           accentColor: const Color(0xFFFFC107),
//                                           allOrders: orders,
//                                         ),
//                                       ),
//                                     ),
//                                     SizedBox(width: _R.dp(12)),
//                                     Expanded(
//                                       child: _StatCard(
//                                         value: '$verifyCount',
//                                         label: 'To Verify',
//                                         accentColor: const Color(0xFF9C27B0),
//                                         onTap: () => _openOrders(
//                                           context,
//                                           statusFilter: const [1],
//                                           title: 'Verify',
//                                           subtitle: 'Orders to Verify',
//                                           accentColor: const Color(0xFF9C27B0),
//                                           allOrders: orders,
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                               SizedBox(height: _R.dp(12)),

//                               IntrinsicHeight(
//                                 child: Row(
//                                   crossAxisAlignment:
//                                       CrossAxisAlignment.stretch,
//                                   children: [
//                                     Expanded(
//                                       child: _StatCard(
//                                         value: '$approveCount',
//                                         label: 'To Approve',
//                                         accentColor: const Color(0xFF2196F3),
//                                         onTap: () => _openOrders(
//                                           context,
//                                           statusFilter: const [3],
//                                           title: 'Approve',
//                                           subtitle: 'Orders to Approve',
//                                           accentColor: const Color(0xFF2196F3),
//                                           allOrders: orders,
//                                         ),
//                                       ),
//                                     ),
//                                     SizedBox(width: _R.dp(12)),
//                                     Expanded(
//                                       child: _StatCard(
//                                         value: '$toDeliverCount',
//                                         label: 'To Deliver',
//                                         accentColor: const Color(0xFF4CAF50),
//                                         onTap: () => _openOrders(
//                                           context,
//                                           statusFilter: const [5],
//                                           title: 'Deliver',
//                                           subtitle: 'Orders to Deliver',
//                                           accentColor: const Color(0xFF4CAF50),
//                                           allOrders: orders,
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),

//                               SizedBox(height: _R.dp(20)),

//                               // ══════════════════════════════════════════
//                               // BILL SECTION
//                               // ══════════════════════════════════════════
//                               _SectionHeader(
//                                 label: 'Bill',
//                                 icon: Icons.receipt_long_rounded,
//                                 color: const Color(0xFF607D8B),
//                               ),
//                               SizedBox(height: _R.dp(12)),

//                               IntrinsicHeight(
//                                 child: Row(
//                                   crossAxisAlignment:
//                                       CrossAxisAlignment.stretch,
//                                   children: [
//                                     Expanded(
//                                       child: _ChallanStatCard(
//                                         valueWidget: _challanValue(
//                                           '$_pendingDeliveryCount',
//                                           const Color(0xFFFF5722),
//                                         ),
//                                         label: 'Pending Delivery',
//                                         accentColor: const Color(0xFFFF5722),
//                                         onTap: () =>
//                                             _openPendingDelivery(context),
//                                       ),
//                                     ),
//                                     SizedBox(width: _R.dp(12)),
//                                     Expanded(
//                                       child: _ChallanStatCard(
//                                         valueWidget: _challanValue(
//                                           '$_deliveredCount',
//                                           const Color(0xFF009688),
//                                         ),
//                                         label: 'Chalan',
//                                         accentColor: const Color(0xFF009688),
//                                         onTap: () => _openDelivered(context),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                               SizedBox(height: _R.dp(12)),

//                               _ChallanStatCard(
//                                 valueWidget: _challanValue(
//                                   '$_billCount',
//                                   const Color(0xFF607D8B),
//                                 ),
//                                 label: 'Bill',
//                                 accentColor: const Color(0xFF607D8B),
//                                 onTap: () => _openBill(context),
//                               ),

//                               SizedBox(height: _R.dp(24)),

//                               // ── Quick Actions ──────────────────────────
//                               Text(
//                                 'Quick Actions',
//                                 style: TextStyle(
//                                   fontSize: _R.sp(17),
//                                   fontWeight: FontWeight.w700,
//                                   letterSpacing: -0.3,
//                                 ),
//                               ),
//                               SizedBox(height: _R.dp(12)),

//                               IntrinsicHeight(
//                                 child: Row(
//                                   crossAxisAlignment:
//                                       CrossAxisAlignment.stretch,
//                                   children: [
//                                     Expanded(
//                                       child: _ActionCard(
//                                         icon: Icons.add_shopping_cart_rounded,
//                                         label: 'Create Order',
//                                         onTap: () => Navigator.pushNamed(
//                                           context,
//                                           createOrderRoute,
//                                         ),
//                                       ),
//                                     ),
//                                     SizedBox(width: _R.dp(12)),
//                                     Expanded(
//                                       child: _ActionCard(
//                                         icon: Icons.add_box_rounded,
//                                         label: 'Add Product',
//                                         onTap: () {},
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),

//                               SizedBox(height: _R.dp(20)),

//                               // ✅ Last updated timestamp
//                               Container(
//                                 padding: EdgeInsets.symmetric(
//                                   vertical: _R.dp(8),
//                                   horizontal: _R.dp(16),
//                                 ),
//                                 decoration: BoxDecoration(
//                                   color: Colors.white,
//                                   borderRadius: BorderRadius.circular(
//                                     _R.dp(12),
//                                   ),
//                                   boxShadow: [
//                                     BoxShadow(
//                                       color: Colors.black.withOpacity(0.03),
//                                       blurRadius: _R.dp(8),
//                                       offset: Offset(0, _R.dp(2)),
//                                     ),
//                                   ],
//                                 ),
//                                 child: Row(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     Icon(
//                                       Icons.access_time_rounded,
//                                       size: _R.dp(14),
//                                       color: Colors.black38,
//                                     ),
//                                     SizedBox(width: _R.dp(6)),
//                                     Text(
//                                       'Updated ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
//                                       style: TextStyle(
//                                         fontSize: _R.sp(11),
//                                         color: Colors.black38,
//                                         fontWeight: FontWeight.w500,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                               SizedBox(height: _R.dp(10)),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // ── Sub-builders ─────────────────────────────────────────────────────────

//   Widget _buildHeader(BuildContext context) {
//     final btnSize = _R.dp(44);
//     final btnRadius = _R.dp(12);
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               _greeting,
//               style: TextStyle(fontSize: _R.sp(13), color: Colors.black45),
//             ),
//             SizedBox(height: _R.dp(2)),
//           ],
//         ),
//         Row(
//           children: [
//             GestureDetector(
//               onTap: () => _logout(context),
//               child: Container(
//                 width: btnSize,
//                 height: btnSize,
//                 decoration: BoxDecoration(
//                   color: Colors.red.shade50,
//                   borderRadius: BorderRadius.circular(btnRadius),
//                   border: Border.all(color: Colors.red.shade100),
//                 ),
//                 child: Icon(
//                   Icons.logout_rounded,
//                   color: Colors.red.shade400,
//                   size: _R.dp(20),
//                 ),
//               ),
//             ),
//             SizedBox(width: _R.dp(10)),
//             Container(
//               width: btnSize,
//               height: btnSize,
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [Colors.black, Colors.grey.shade800],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//                 borderRadius: BorderRadius.circular(btnRadius),
//               ),
//               child: Icon(
//                 Icons.trending_up_rounded,
//                 color: Colors.white,
//                 size: _R.dp(22),
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildErrorBanner() => Padding(
//     padding: EdgeInsets.only(bottom: _R.dp(16)),
//     child: Container(
//       width: double.infinity,
//       padding: EdgeInsets.symmetric(horizontal: _R.dp(16), vertical: _R.dp(12)),
//       decoration: BoxDecoration(
//         color: const Color(0xFFFFF0F0),
//         borderRadius: BorderRadius.circular(_R.dp(12)),
//         border: Border.all(color: Colors.red.shade100),
//       ),
//       child: Row(
//         children: [
//           Icon(Icons.wifi_off_rounded, color: Colors.red, size: _R.dp(18)),
//           SizedBox(width: _R.dp(10)),
//           Expanded(
//             child: Text(
//               'Failed to load data. Pull down to retry.',
//               style: TextStyle(fontSize: _R.sp(13), color: Colors.redAccent),
//             ),
//           ),
//           GestureDetector(
//             onTap: _refresh,
//             child: Text(
//               'Retry',
//               style: TextStyle(
//                 fontWeight: FontWeight.w700,
//                 color: Colors.redAccent,
//                 fontSize: _R.sp(13),
//               ),
//             ),
//           ),
//         ],
//       ),
//     ),
//   );

//   Widget _buildRefreshBanner() => Padding(
//     padding: EdgeInsets.only(bottom: _R.dp(16)),
//     child: Container(
//       padding: EdgeInsets.symmetric(horizontal: _R.dp(16), vertical: _R.dp(12)),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Colors.blue.shade50, Colors.blue.shade100],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(_R.dp(12)),
//         border: Border.all(color: Colors.blue.shade200),
//       ),
//       child: Row(
//         children: [
//           SizedBox(
//             width: _R.dp(18),
//             height: _R.dp(18),
//             child: CircularProgressIndicator(
//               strokeWidth: 2,
//               valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
//             ),
//           ),
//           SizedBox(width: _R.dp(10)),
//           Text(
//             'Refreshing data...',
//             style: TextStyle(
//               fontSize: _R.sp(13),
//               fontWeight: FontWeight.w500,
//               color: Colors.black87,
//             ),
//           ),
//         ],
//       ),
//     ),
//   );
// }

// // ════════════════════════════════════════════════════════════════════════════
// // CUSTOM REFRESH HEADER - Beautiful animated pull-to-refresh
// // ════════════════════════════════════════════════════════════════════════════

// class _CustomRefreshHeader extends StatelessWidget {
//   final double pullDistance;
//   final bool isRefreshing;
//   final double maxPullDistance;

//   const _CustomRefreshHeader({
//     required this.pullDistance,
//     required this.isRefreshing,
//     required this.maxPullDistance,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final progress = (pullDistance / maxPullDistance).clamp(0.0, 1.0);
//     final isReady = progress >= 1.0 && !isRefreshing;

//     // Only show when pulling down or refreshing
//     if (pullDistance <= 0 && !isRefreshing) {
//       return const SizedBox.shrink();
//     }

//     return Container(
//       height: _R.dp(70),
//       alignment: Alignment.center,
//       child: AnimatedSwitcher(
//         duration: const Duration(milliseconds: 300),
//         child: isRefreshing
//             ? _RefreshingState()
//             : _PullToRefreshState(
//                 progress: progress,
//                 isReady: isReady,
//                 pullDistance: pullDistance,
//               ),
//       ),
//     );
//   }
// }

// // ── Pull to Refresh State ──────────────────────────────────────────────────

// class _PullToRefreshState extends StatelessWidget {
//   final double progress;
//   final bool isReady;
//   final double pullDistance;

//   const _PullToRefreshState({
//     required this.progress,
//     required this.isReady,
//     required this.pullDistance,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Stack(
//           alignment: Alignment.center,
//           children: [
//             // Background ring with shadow
//             Container(
//               width: _R.dp(46),
//               height: _R.dp(46),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 shape: BoxShape.circle,
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.06),
//                     blurRadius: _R.dp(10),
//                     offset: Offset(0, _R.dp(3)),
//                   ),
//                 ],
//               ),
//             ),
//             // Progress ring
//             SizedBox(
//               width: _R.dp(40),
//               height: _R.dp(40),
//               child: CircularProgressIndicator(
//                 value: isReady ? 1.0 : progress,
//                 strokeWidth: 3,
//                 backgroundColor: Colors.grey.shade200,
//                 valueColor: AlwaysStoppedAnimation<Color>(
//                   isReady ? Colors.green : Colors.black,
//                 ),
//               ),
//             ),
//             // Center icon
//             AnimatedSwitcher(
//               duration: const Duration(milliseconds: 200),
//               child: Icon(
//                 isReady ? Icons.check_rounded : Icons.arrow_downward_rounded,
//                 key: ValueKey<bool>(isReady),
//                 color: isReady ? Colors.green : Colors.black54,
//                 size: _R.dp(16),
//               ),
//             ),
//           ],
//         ),
//         if (pullDistance > _R.dp(30)) ...[
//           SizedBox(height: _R.dp(6)),
//           AnimatedOpacity(
//             opacity: progress.clamp(0.0, 1.0),
//             duration: const Duration(milliseconds: 200),
//             child: Text(
//               isReady ? 'Release to refresh ✨' : 'Pull to refresh',
//               style: TextStyle(
//                 fontSize: _R.sp(11),
//                 fontWeight: FontWeight.w500,
//                 color: isReady ? Colors.green : Colors.black54,
//                 letterSpacing: 0.2,
//               ),
//             ),
//           ),
//         ],
//       ],
//     );
//   }
// }

// // ── Refreshing State ──────────────────────────────────────────────────────

// class _RefreshingState extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Stack(
//           alignment: Alignment.center,
//           children: [
//             // Background ring with shadow
//             Container(
//               width: _R.dp(46),
//               height: _R.dp(46),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 shape: BoxShape.circle,
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.06),
//                     blurRadius: _R.dp(10),
//                     offset: Offset(0, _R.dp(3)),
//                   ),
//                 ],
//               ),
//             ),
//             // Spinning loader
//             SizedBox(
//               width: _R.dp(40),
//               height: _R.dp(40),
//               child: const CircularProgressIndicator(
//                 strokeWidth: 3,
//                 valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
//               ),
//             ),
//             // Rotating refresh icon
//             TweenAnimationBuilder(
//               tween: Tween<double>(begin: 0, end: 1),
//               duration: const Duration(milliseconds: 800),
//               builder: (context, value, child) {
//                 return Transform.rotate(
//                   angle: value * 2 * 3.14159,
//                   child: Icon(
//                     Icons.refresh_rounded,
//                     color: Colors.black87,
//                     size: _R.dp(16),
//                   ),
//                 );
//               },
//             ),
//           ],
//         ),
//         SizedBox(height: _R.dp(6)),
//         Text(
//           'Refreshing... 🔄',
//           style: TextStyle(
//             fontSize: _R.sp(11),
//             fontWeight: FontWeight.w500,
//             color: Colors.black54,
//             letterSpacing: 0.2,
//           ),
//         ),
//       ],
//     );
//   }
// }

// // ════════════════════════════════════════════════════════════════════════════
// // SECTION HEADER
// // ════════════════════════════════════════════════════════════════════════════

// class _SectionHeader extends StatelessWidget {
//   final String label;
//   final IconData icon;
//   final Color color;
//   const _SectionHeader({
//     required this.label,
//     required this.icon,
//     required this.color,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Container(
//           padding: EdgeInsets.all(_R.dp(6)),
//           decoration: BoxDecoration(
//             color: color.withValues(alpha: 0.12),
//             borderRadius: BorderRadius.circular(_R.dp(8)),
//           ),
//           child: Icon(icon, size: _R.dp(16), color: color),
//         ),
//         SizedBox(width: _R.dp(8)),
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: _R.sp(15),
//             fontWeight: FontWeight.w700,
//             color: color,
//             letterSpacing: -0.2,
//           ),
//         ),
//         SizedBox(width: _R.dp(8)),
//         Expanded(
//           child: Divider(color: color.withValues(alpha: 0.2), thickness: 1.5),
//         ),
//       ],
//     );
//   }
// }

// // ════════════════════════════════════════════════════════════════════════════
// // STAT CARD
// // ════════════════════════════════════════════════════════════════════════════

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
//       borderRadius: BorderRadius.circular(_R.dp(16)),
//       child: Container(
//         constraints: BoxConstraints(minHeight: _R.dp(74)),
//         padding: EdgeInsets.symmetric(
//           horizontal: _R.dp(14),
//           vertical: _R.dp(14),
//         ),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(_R.dp(16)),
//           border: Border(
//             left: BorderSide(color: accentColor, width: _R.dp(3)),
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withValues(alpha: 0.05),
//               blurRadius: _R.dp(10),
//               offset: Offset(0, _R.dp(4)),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             FittedBox(
//               fit: BoxFit.scaleDown,
//               alignment: Alignment.centerLeft,
//               child: Text(
//                 value,
//                 style: TextStyle(
//                   fontSize: _R.sp(22),
//                   fontWeight: FontWeight.w700,
//                   color: accentColor,
//                   letterSpacing: -0.5,
//                 ),
//               ),
//             ),
//             SizedBox(height: _R.dp(4)),
//             Text(
//               label,
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//               style: TextStyle(
//                 fontSize: _R.sp(12),
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

// // ════════════════════════════════════════════════════════════════════════════
// // CHALLAN STAT CARD
// // ════════════════════════════════════════════════════════════════════════════

// class _ChallanStatCard extends StatelessWidget {
//   final Widget valueWidget;
//   final String label;
//   final Color accentColor;
//   final VoidCallback? onTap;

//   const _ChallanStatCard({
//     required this.valueWidget,
//     required this.label,
//     required this.accentColor,
//     this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(_R.dp(16)),
//       child: Container(
//         constraints: BoxConstraints(minHeight: _R.dp(74)),
//         padding: EdgeInsets.symmetric(
//           horizontal: _R.dp(14),
//           vertical: _R.dp(14),
//         ),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(_R.dp(16)),
//           border: Border(
//             left: BorderSide(color: accentColor, width: _R.dp(3)),
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withValues(alpha: 0.05),
//               blurRadius: _R.dp(10),
//               offset: Offset(0, _R.dp(4)),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             SizedBox(
//               height: _R.dp(28),
//               child: Align(alignment: Alignment.centerLeft, child: valueWidget),
//             ),
//             SizedBox(height: _R.dp(4)),
//             Text(
//               label,
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//               style: TextStyle(
//                 fontSize: _R.sp(12),
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

// // ════════════════════════════════════════════════════════════════════════════
// // ACTION CARD
// // ════════════════════════════════════════════════════════════════════════════

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
//         padding: EdgeInsets.symmetric(vertical: _R.dp(24)),
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Colors.black, Colors.grey.shade900],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//           borderRadius: BorderRadius.circular(_R.dp(16)),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withValues(alpha: 0.15),
//               blurRadius: _R.dp(12),
//               offset: Offset(0, _R.dp(6)),
//             ),
//           ],
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, color: Colors.white, size: _R.dp(28)),
//             SizedBox(height: _R.dp(10)),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: _R.sp(13),
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

// // ════════════════════════════════════════════════════════════════════════════
// // SHIMMER
// // ════════════════════════════════════════════════════════════════════════════

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
//     _R.init(context);
//     return AnimatedBuilder(
//       animation: _anim,
//       builder: (_, _) => SingleChildScrollView(
//         padding: EdgeInsets.fromLTRB(_R.hPad, _R.dp(20), _R.hPad, _R.dp(16)),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     _bar(80, 13),
//                     SizedBox(height: _R.dp(6)),
//                     _bar(120, 26),
//                   ],
//                 ),
//                 Row(
//                   children: [
//                     _box(44, 44, r: 12),
//                     SizedBox(width: _R.dp(10)),
//                     _box(44, 44, r: 12),
//                   ],
//                 ),
//               ],
//             ),
//             SizedBox(height: _R.dp(28)),
//             _bar(80, 15),
//             SizedBox(height: _R.dp(12)),
//             _rowCards(),
//             SizedBox(height: _R.dp(12)),
//             _rowCards(),
//             SizedBox(height: _R.dp(20)),
//             _bar(80, 15),
//             SizedBox(height: _R.dp(12)),
//             _rowCards(),
//             SizedBox(height: _R.dp(12)),
//             _card(),
//             SizedBox(height: _R.dp(24)),
//             _bar(120, 17),
//             SizedBox(height: _R.dp(12)),
//             IntrinsicHeight(
//               child: Row(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   Expanded(child: _action()),
//                   SizedBox(width: _R.dp(12)),
//                   Expanded(child: _action()),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _rowCards() => IntrinsicHeight(
//     child: Row(
//       crossAxisAlignment: CrossAxisAlignment.stretch,
//       children: [
//         Expanded(child: _card()),
//         SizedBox(width: _R.dp(12)),
//         Expanded(child: _card()),
//       ],
//     ),
//   );

//   Widget _card() => Opacity(
//     opacity: _anim.value,
//     child: Container(
//       constraints: BoxConstraints(minHeight: _R.dp(74)),
//       padding: EdgeInsets.all(_R.dp(14)),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(_R.dp(16)),
//         border: Border(
//           left: BorderSide(color: Colors.grey.shade200, width: _R.dp(3)),
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.05),
//             blurRadius: _R.dp(10),
//             offset: Offset(0, _R.dp(4)),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           _bar(60, 26),
//           SizedBox(height: _R.dp(8)),
//           _bar(90, 12),
//         ],
//       ),
//     ),
//   );

//   Widget _action() => Opacity(
//     opacity: _anim.value,
//     child: Container(
//       padding: EdgeInsets.symmetric(vertical: _R.dp(24)),
//       decoration: BoxDecoration(
//         color: Colors.grey.shade200,
//         borderRadius: BorderRadius.circular(_R.dp(16)),
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           _box(28, 28, r: 6),
//           SizedBox(height: _R.dp(10)),
//           _bar(80, 13),
//         ],
//       ),
//     ),
//   );

//   Widget _bar(double w, double h) => Opacity(
//     opacity: _anim.value,
//     child: Container(
//       width: _R.dp(w),
//       height: _R.dp(h),
//       decoration: BoxDecoration(
//         color: Colors.grey.shade200,
//         borderRadius: BorderRadius.circular(_R.dp(6)),
//       ),
//     ),
//   );

//   Widget _box(double w, double h, {double r = 8}) => Opacity(
//     opacity: _anim.value,
//     child: Container(
//       width: _R.dp(w),
//       height: _R.dp(h),
//       decoration: BoxDecoration(
//         color: Colors.grey.shade200,
//         borderRadius: BorderRadius.circular(_R.dp(r)),
//       ),
//     ),
//   );
// }
