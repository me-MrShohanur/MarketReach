// lib/views/home/home_view.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marketing/bloc/order/pending_order_block.dart';
import 'package:marketing/constants/routes.dart';
import 'package:marketing/services/auth_service.dart';
import 'package:marketing/services/provider/current_user.dart';
import 'package:marketing/views/home/subpages/pending_order.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late final OrderListBloc _bloc;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
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

    setState(() {
      _isRefreshing = true;
    });

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

      // Wait for the bloc to complete loading
      await Future.delayed(const Duration(milliseconds: 500));
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
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

                // Show shimmer only on initial load, not during refresh
                if (isLoading) return const _HomeShimmer();

                final pendingCount = orders
                    .where((o) => o.status == -1 || o.status == 0)
                    .length;
                final verifyCount = orders.where((o) => o.status == 2).length;
                final approveCount = orders.where((o) => o.status == 3).length;
                final deliverCount = orders.where((o) => o.status == 5).length;

                return RefreshIndicator(
                  onRefresh: _refresh,
                  color: Colors.black,
                  backgroundColor: Colors.white,
                  strokeWidth: 2.5,
                  triggerMode: RefreshIndicatorTriggerMode.onEdge,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Header ──────────────────────────────────
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

                        const SizedBox(height: 28),

                        // ── Error Banner ─────────────────────────────
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

                        // Show loading indicator during refresh
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

                        // ── Stats Grid ───────────────────────────────
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.45,
                          children: [
                            _StatCard(
                              value: '$deliverCount',
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
                            _StatCard(
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
                            _StatCard(
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
                            _StatCard(
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
                          ],
                        ),

                        const SizedBox(height: 28),

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
                        Row(
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

// ── Full Page Shimmer ─────────────────────────────────────────────────────────

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
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header shimmer ───────────────────────────────────
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

              // ── Grid shimmer ─────────────────────────────────────
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.45,
                children: List.generate(4, (_) => _cardShimmer()),
              ),

              const SizedBox(height: 28),

              // ── Quick Actions label shimmer ───────────────────────
              _bar(120, 17),
              const SizedBox(height: 12),

              // ── Action cards shimmer ─────────────────────────────
              Row(
                children: [
                  Expanded(child: _actionShimmer()),
                  const SizedBox(width: 12),
                  Expanded(child: _actionShimmer()),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Shimmer stat card
  Widget _cardShimmer() {
    return Opacity(
      opacity: _anim.value,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(color: Colors.grey.shade200, width: 3),
          ),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [_bar(60, 26), const SizedBox(height: 8), _bar(90, 12)],
        ),
      ),
    );
  }

  // Shimmer action card
  Widget _actionShimmer() {
    return Opacity(
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
  }

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

// ── Stat Card ─────────────────────────────────────────────────────────────────

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
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: accentColor,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 5),
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

// ── Action Card ───────────────────────────────────────────────────────────────
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
