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
            // Determine if it was approve or cancel from the slider's state
            final bool isApprove = _ApprovalSliderState.lastActionWasApprove;
            _showResultSheet(
              context,
              success: true,
              message: state.message,
              isApprove: isApprove,
            );
          } else if (state is OrderApprovalFailure) {
            debugPrint(
              '❌ [OrderApproval] FAILED — orderId: $orderId | error: ${state.error}',
            );
            final bool isApprove = _ApprovalSliderState.lastActionWasApprove;
            _showResultSheet(
              context,
              success: false,
              message: state.error,
              isApprove: isApprove,
            );
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
    required bool isApprove,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (_) => _ApprovalResultSheet(
        success: success,
        message: message,
        isApprove: isApprove,
      ),
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

        // ── Approve / Cancel Slider (hold-to-confirm) ────────────────────────
        _ApprovalSlider(orderId: orderId),

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
// APPROVAL SLIDER — swipe to either edge and HOLD for 1s to confirm
//   Right edge (alignment > 0) → Approve  → status: 1
//   Left  edge (alignment < 0) → Cancel   → status: -3
// ═══════════════════════════════════════════════════════════════════════════════

class _ApprovalSlider extends StatefulWidget {
  final int orderId;
  const _ApprovalSlider({required this.orderId});

  @override
  State<_ApprovalSlider> createState() => _ApprovalSliderState();
}

class _ApprovalSliderState extends State<_ApprovalSlider>
    with TickerProviderStateMixin {
  double _alignmentX = 0.0; // -1 (Cancel) .. 0 (Center) .. 1 (Approve)
  bool _isDragging = false;
  bool _holding = false; // past threshold, hold-timer running
  bool _actionFired = false; // 1s hold completed, event already dispatched
  int _holdSide = 0; // -1 = cancel side, 1 = approve side

  double _dragStartAlignment = 0.0;
  double _dragStartDx = 0.0;

  final GlobalKey _trackKey = GlobalKey();

  static const double _threshold = 0.82;
  static const double _sliderHeight = 62.0;
  static const double _handleSize = 50.0;

  // ✅ Static variable to track the last action
  static bool lastActionWasApprove = true;

  // 🔥 CHANGED: Hold duration from 2s to 1s
  late final AnimationController _holdCtrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1), // ✅ Now 1 second
  )..addStatusListener(_onHoldStatusChanged);

  @override
  void dispose() {
    _holdCtrl.dispose();
    super.dispose();
  }

  void _onHoldStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_actionFired) {
      _actionFired = true;
      HapticFeedback.heavyImpact();
      final status_ = _holdSide == 1 ? 1 : -3;
      // ✅ Store the action type in static variable
      lastActionWasApprove = _holdSide == 1;
      debugPrint(
        '🚀 [OrderApproval] Hold complete — orderId: ${widget.orderId} | status: $status_ | isApprove: $lastActionWasApprove',
      );
      context.read<OrderApprovalBloc>().add(
        ConfirmOrderApproval(widget.orderId, status: status_),
      );
    }
  }

  void _startHold(int side) {
    if (_holding) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _holding = true;
      _holdSide = side;
    });
    _holdCtrl.forward(from: 0);
  }

  void _cancelHold() {
    if (!_holding || _actionFired) return;
    setState(() => _holding = false);
    _holdCtrl.stop();
    _holdCtrl.value = 0;
  }

  void _resetAll() {
    _holdCtrl.stop();
    _holdCtrl.value = 0;
    setState(() {
      _alignmentX = 0.0;
      _isDragging = false;
      _holding = false;
      _actionFired = false;
      _holdSide = 0;
    });
  }

  void _onPointerDown(PointerDownEvent event, bool isLoading) {
    if (isLoading || _actionFired) return;
    _isDragging = true;
    _dragStartAlignment = _alignmentX;
    _dragStartDx = event.position.dx;
  }

  void _onPointerMove(PointerMoveEvent event, bool isLoading) {
    if (isLoading || _actionFired || !_isDragging) return;
    final box = _trackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final maxTravel = (box.size.width - _handleSize) / 2;
    final dx = event.position.dx - _dragStartDx;

    setState(() {
      _alignmentX = (_dragStartAlignment + dx / maxTravel).clamp(-1.0, 1.0);
    });

    if (_alignmentX.abs() >= _threshold) {
      final side = _alignmentX > 0 ? 1 : -1;
      if (!_holding) {
        _startHold(side);
      } else if (_holdSide != side) {
        _cancelHold();
        _startHold(side);
      }
    } else {
      _cancelHold();
    }
  }

  void _handleRelease(bool isLoading) {
    if (isLoading) return;
    _isDragging = false;
    if (_actionFired)
      return; // let the handle sit at the edge while the API call runs
    _cancelHold();
    setState(() => _alignmentX = 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrderApprovalBloc, OrderApprovalState>(
      listener: (context, state) {
        if (state is OrderApprovalSuccess || state is OrderApprovalFailure) {
          // Let the result sheet appear first, then reset the slider underneath it.
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) _resetAll();
          });
        }
      },
      builder: (context, state) {
        final isLoading = state is OrderApprovalLoading;

        return Listener(
          onPointerDown: (e) => _onPointerDown(e, isLoading),
          onPointerMove: (e) => _onPointerMove(e, isLoading),
          onPointerUp: (_) => _handleRelease(isLoading),
          onPointerCancel: (_) => _handleRelease(isLoading),
          child: Container(
            key: _trackKey,
            width: double.infinity,
            height: _sliderHeight,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: isLoading ? Colors.grey.shade200 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (!isLoading) ...[
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: (1.0 - _alignmentX.abs() * 1.6).clamp(0.0, 0.4),
                    child: const Text(
                      '⟪  Hold at Edge to Confirm  ⟫',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),

                  // Left text (Cancel indicator)
                  Positioned(
                    left: 24,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 100),
                      opacity: _alignmentX < 0
                          ? _alignmentX.abs().clamp(0.5, 1.0)
                          : 0.15,
                      child: Row(
                        children: [
                          Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: Colors.red.shade600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Right text (Approve indicator)
                  Positioned(
                    right: 24,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 100),
                      opacity: _alignmentX > 0
                          ? _alignmentX.clamp(0.5, 1.0)
                          : 0.15,
                      child: Row(
                        children: [
                          Text(
                            'Approve',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: Colors.green.shade700,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                if (isLoading)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.black87,
                          strokeWidth: 2.5,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _holdSide == 1 ? 'Approving…' : 'Rejecting…',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),

                // Draggable handle with hold-progress ring
                if (!isLoading)
                  AnimatedAlign(
                    duration: _isDragging
                        ? Duration.zero
                        : const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment(_alignmentX, 0.0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: SizedBox(
                        width: _handleSize + 10,
                        height: _handleSize + 10,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (_holding)
                              AnimatedBuilder(
                                animation: _holdCtrl,
                                builder: (_, _) => SizedBox(
                                  width: _handleSize + 10,
                                  height: _handleSize + 10,
                                  child: CircularProgressIndicator(
                                    value: _holdCtrl.value,
                                    strokeWidth: 3,
                                    backgroundColor: Colors.black.withOpacity(
                                      0.06,
                                    ),
                                    valueColor: AlwaysStoppedAnimation(
                                      _holdSide == 1
                                          ? Colors.green.shade600
                                          : Colors.red.shade600,
                                    ),
                                  ),
                                ),
                              ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              width: _handleSize,
                              height: _handleSize,
                              decoration: BoxDecoration(
                                color: _alignmentX == 0
                                    ? const Color(0xFF1E1E1E)
                                    : _alignmentX > 0
                                    ? Color.lerp(
                                        const Color(0xFF1E1E1E),
                                        Colors.green.shade600,
                                        _alignmentX,
                                      )
                                    : Color.lerp(
                                        const Color(0xFF1E1E1E),
                                        Colors.red.shade600,
                                        _alignmentX.abs(),
                                      ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 150),
                                child: Icon(
                                  _alignmentX == 0
                                      ? Icons.drag_handle_rounded
                                      : _alignmentX > 0
                                      ? Icons.check_circle_outline_rounded
                                      : Icons.cancel_outlined,
                                  key: ValueKey<int>(
                                    (_alignmentX * 10).round(),
                                  ),
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// APPROVAL RESULT BOTTOM SHEET — Dynamically shows Approve/Cancel result
// ═══════════════════════════════════════════════════════════════════════════════

class _ApprovalResultSheet extends StatelessWidget {
  final bool success;
  final String message;
  final bool isApprove;

  const _ApprovalResultSheet({
    required this.success,
    required this.message,
    required this.isApprove,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Dynamic styling based on action type
    String title;
    Color color;
    IconData icon;
    String subtitle;

    if (success) {
      if (isApprove) {
        // Approve Success - Green
        title = 'Order Approved Successfully!';
        color = const Color(0xFF4CAF50);
        icon = Icons.check_circle_rounded;
        subtitle = 'Order has been approved successfully.';
      } else {
        // Cancel Success - Red
        title = 'Order Canceled Successfully!';
        color = Colors.redAccent;
        icon = Icons.cancel_rounded;
        subtitle = 'Order has been canceled successfully.';
      }
    } else {
      if (isApprove) {
        // Approve Failed - Red
        title = 'Approval Failed';
        color = Colors.redAccent;
        icon = Icons.error_outline_rounded;
        subtitle = 'Something went wrong. Please try again.';
      } else {
        // Cancel Failed - Red
        title = 'Cancelation Failed';
        color = Colors.redAccent;
        icon = Icons.error_outline_rounded;
        subtitle = 'Something went wrong. Please try again.';
      }
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        // ✅ Border on ALL sides (top, right, bottom, left)
        border: Border.all(color: color, width: 3),
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message.isNotEmpty ? message : subtitle,
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
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:marketing/bloc/order/order_details.dart';
// import 'package:marketing/bloc/order/save_aproval.dart';

// // ═══════════════════════════════════════════════════════════════════════════════
// // ENTRY POINT
// // ═══════════════════════════════════════════════════════════════════════════════

// class OrderDetailView extends StatelessWidget {
//   final int? id;
//   final int? orderId;
//   final String? orderNo;

//   const OrderDetailView({
//     super.key,
//     required this.orderId,
//     required this.orderNo,
//     required this.id,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return MultiBlocProvider(
//       providers: [
//         BlocProvider(
//           create: (_) => OrderDetailBloc()..add(LoadOrderDetail(id!)),
//         ),
//         BlocProvider(create: (_) => OrderApprovalBloc()),
//       ],
//       child: _OrderDetailScaffold(orderNo: orderNo!, orderId: orderId!),
//     );
//   }
// }

// // ═══════════════════════════════════════════════════════════════════════════════
// // SCAFFOLD
// // ═══════════════════════════════════════════════════════════════════════════════

// class _OrderDetailScaffold extends StatelessWidget {
//   final String orderNo;
//   final int orderId;

//   const _OrderDetailScaffold({required this.orderNo, required this.orderId});

//   @override
//   Widget build(BuildContext context) {
//     return AnnotatedRegion<SystemUiOverlayStyle>(
//       value: SystemUiOverlayStyle.dark,
//       child: BlocListener<OrderApprovalBloc, OrderApprovalState>(
//         listener: (context, state) {
//           if (state is OrderApprovalSuccess) {
//             debugPrint(
//               '✅ [OrderApproval] SUCCESS — orderId: $orderId | msg: ${state.message}',
//             );
//             _showResultSheet(context, success: true, message: state.message);
//           } else if (state is OrderApprovalFailure) {
//             debugPrint(
//               '❌ [OrderApproval] FAILED — orderId: $orderId | error: ${state.error}',
//             );
//             _showResultSheet(context, success: false, message: state.error);
//           } else if (state is OrderApprovalLoading) {
//             debugPrint('⏳ [OrderApproval] LOADING — orderId: $orderId');
//           }
//         },
//         child: Scaffold(
//           backgroundColor: const Color(0xFFF5F5F5),
//           body: SafeArea(
//             child: Column(
//               children: [
//                 _Header(orderNo: orderNo),
//                 const SizedBox(height: 16),
//                 Expanded(
//                   child: BlocBuilder<OrderDetailBloc, OrderDetailState>(
//                     builder: (context, state) {
//                       if (state is OrderDetailLoading) {
//                         return const _LoadingView();
//                       }
//                       if (state is OrderDetailError) {
//                         return _ErrorView(
//                           message: state.message,
//                           onRetry: () => context.read<OrderDetailBloc>().add(
//                             LoadOrderDetail(orderId),
//                           ),
//                         );
//                       }
//                       if (state is OrderDetailLoaded) {
//                         return _DetailBody(
//                           order: state.order,
//                           orderId: orderId,
//                         );
//                       }
//                       return const SizedBox.shrink();
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   void _showResultSheet(
//     BuildContext context, {
//     required bool success,
//     required String message,
//   }) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       isDismissible: true,
//       builder: (_) => _ApprovalResultSheet(success: success, message: message),
//     );
//   }
// }

// // ═══════════════════════════════════════════════════════════════════════════════
// // HEADER
// // ═══════════════════════════════════════════════════════════════════════════════

// class _Header extends StatelessWidget {
//   final String orderNo;
//   const _Header({required this.orderNo});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Row(
//             children: [
//               GestureDetector(
//                 onTap: () => Navigator.maybePop(context),
//                 child: Container(
//                   width: 38,
//                   height: 38,
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(10),
//                     boxShadow: const [
//                       BoxShadow(
//                         color: Color(0x0F000000),
//                         blurRadius: 8,
//                         offset: Offset(0, 3),
//                       ),
//                     ],
//                   ),
//                   child: const Icon(
//                     Icons.arrow_back_ios_new_rounded,
//                     size: 16,
//                     color: Colors.black,
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 14),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Order Details',
//                     style: TextStyle(fontSize: 13, color: Colors.black45),
//                   ),
//                   Text(
//                     orderNo,
//                     style: const TextStyle(
//                       fontSize: 22,
//                       fontWeight: FontWeight.w700,
//                       letterSpacing: -0.5,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//           BlocBuilder<OrderDetailBloc, OrderDetailState>(
//             builder: (_, state) {
//               if (state is! OrderDetailLoaded) return const SizedBox.shrink();
//               return _StatusBadge(
//                 label:
//                     state.order.statusName ?? _statusLabel(state.order.status),
//                 color: _statusColor(state.order.status),
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   String _statusLabel(int s) {
//     switch (s) {
//       case 0:
//         return 'Pending';
//       case 1:
//         return 'Processing';
//       case 2:
//         return 'Completed';
//       case 3:
//         return 'Cancelled';
//       default:
//         return 'Unknown';
//     }
//   }

//   Color _statusColor(int s) {
//     switch (s) {
//       case 0:
//         return const Color(0xFFFFC107);
//       case 1:
//         return const Color(0xFF2196F3);
//       case 2:
//         return const Color(0xFF4CAF50);
//       case 3:
//         return Colors.redAccent;
//       default:
//         return Colors.black26;
//     }
//   }
// }

// // ═══════════════════════════════════════════════════════════════════════════════
// // DETAIL BODY
// // ═══════════════════════════════════════════════════════════════════════════════

// class _DetailBody extends StatelessWidget {
//   final OrderDetailMaster order;
//   final int orderId;

//   const _DetailBody({required this.order, required this.orderId});

//   @override
//   Widget build(BuildContext context) {
//     return ListView(
//       padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
//       children: [
//         // ── Order Image ──────────────────────────────────────────────────────
//         if (order.base64File != null && order.base64File!.isNotEmpty)
//           GestureDetector(
//             onTap: () => _showFullScreenImage(context, order.base64File!),
//             child: _OrderImage(base64Image: order.base64File!),
//           ),

//         const SizedBox(height: 12),

//         // ── Customer Card ────────────────────────────────────────────────────
//         _SectionCard(
//           accent: const Color(0xFF2196F3),
//           title: 'Customer',
//           icon: Icons.person_outline_rounded,
//           child: Column(
//             children: [
//               _InfoRow(label: 'Bill To', value: order.billTo ?? '—'),
//               _InfoRow(label: 'Address', value: order.billAddress ?? '—'),
//               _InfoRow(label: 'Contact', value: order.billContactNo ?? '—'),
//               _InfoRow(label: 'Order Date', value: order.formattedDate),
//               if (order.chequeDate != null && order.chequeDate!.isNotEmpty)
//                 _InfoRow(
//                   label: 'Cheque Date',
//                   value: order.chequeDate!,
//                   isLast: true,
//                 ),
//             ],
//           ),
//         ),

//         const SizedBox(height: 12),

//         // ── Financials Card ──────────────────────────────────────────────────
//         _SectionCard(
//           accent: const Color(0xFF4CAF50),
//           title: 'Financials',
//           icon: Icons.account_balance_wallet_outlined,
//           child: Column(
//             children: [
//               _InfoRow(
//                 label: 'Net Amount',
//                 value: '৳${order.netAmount.toStringAsFixed(2)}',
//               ),
//               _InfoRow(
//                 label: 'Discount',
//                 value: '৳${order.discountAmount.toStringAsFixed(2)}',
//               ),
//               _InfoRow(
//                 label: 'VAT',
//                 value: '৳${order.vatAmount.toStringAsFixed(2)}',
//               ),
//               _InfoRow(
//                 label: 'Other Addition',
//                 value: '৳${order.otherAddition.toStringAsFixed(2)}',
//               ),
//               _InfoRow(
//                 label: 'Other Deduction',
//                 value: '৳${order.otherDeduction.toStringAsFixed(2)}',
//               ),
//               _InfoRow(
//                 label: 'Deposit',
//                 value: '৳${order.deposite.toStringAsFixed(2)}',
//               ),
//               _InfoRow(
//                 label: 'Paid Amount',
//                 value: '৳${order.paidAmount.toStringAsFixed(2)}',
//               ),
//               if (order.creditLimit != null && order.creditLimit! > 0)
//                 _InfoRow(
//                   label: 'Credit Limit',
//                   value: '৳${order.creditLimit!.toStringAsFixed(2)}',
//                 ),
//               if (order.balance != null)
//                 _InfoRow(
//                   label: 'Balance',
//                   value: '৳${order.balance!.toStringAsFixed(2)}',
//                   isLast: true,
//                 ),
//               const Divider(height: 20, color: Color(0xFFF0F0F0)),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text(
//                     'Net Payable',
//                     style: TextStyle(
//                       fontSize: 15,
//                       fontWeight: FontWeight.w700,
//                       color: Colors.black87,
//                     ),
//                   ),
//                   Text(
//                     '৳${order.netPayable.toStringAsFixed(2)}',
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w700,
//                       color: Color(0xFF4CAF50),
//                       letterSpacing: -0.3,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),

//         const SizedBox(height: 12),

//         // ── Payment Card ─────────────────────────────────────────────────────
//         _SectionCard(
//           accent: const Color(0xFFFFC107),
//           title: 'Payment',
//           icon: Icons.payments_outlined,
//           child: Column(
//             children: [
//               _InfoRow(label: 'Payment Type', value: order.paymentType ?? '—'),
//               _InfoRow(label: 'Ref No', value: order.refNo ?? '—'),
//               _InfoRow(
//                 label: 'Narration',
//                 value: order.narration ?? '—',
//                 isLast: true,
//               ),
//             ],
//           ),
//         ),

//         const SizedBox(height: 12),

//         // ── Products Card ────────────────────────────────────────────────────
//         _SectionCard(
//           accent: Colors.black,
//           title: 'Products (${order.details.length})',
//           icon: Icons.inventory_2_outlined,
//           child: order.details.isEmpty
//               ? const Padding(
//                   padding: EdgeInsets.symmetric(vertical: 8),
//                   child: Text(
//                     'No product details available',
//                     style: TextStyle(fontSize: 13, color: Colors.black38),
//                   ),
//                 )
//               : Column(
//                   children: [
//                     for (int i = 0; i < order.details.length; i++) ...[
//                       if (i > 0)
//                         const Divider(height: 20, color: Color(0xFFF0F0F0)),
//                       _ProductItem(item: order.details[i], index: i),
//                     ],
//                   ],
//                 ),
//         ),

//         const SizedBox(height: 24),

//         // ── Confirm Approval Button ──────────────────────────────────────────
//         _ConfirmApprovalButton(orderId: orderId),

//         const SizedBox(height: 8),
//       ],
//     );
//   }

//   void _showFullScreenImage(BuildContext context, String base64Image) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => FullScreenImageViewer(base64Image: base64Image),
//       ),
//     );
//   }
// }

// class _ConfirmApprovalButton extends StatefulWidget {
//   final int orderId;
//   const _ConfirmApprovalButton({required this.orderId});

//   @override
//   State<_ConfirmApprovalButton> createState() => _ConfirmApprovalButtonState();
// }

// class _ConfirmApprovalButtonState extends State<_ConfirmApprovalButton> {
//   // -1.0 is far left (Cancel), 0.0 is Center, 1.0 is far right (Confirm)
//   double _alignmentX = 0.0;
//   final double _sliderHeight = 58.0;
//   final double _handleSize = 50.0;

//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<OrderApprovalBloc, OrderApprovalState>(
//       builder: (context, state) {
//         final isLoading = state is OrderApprovalLoading;

//         if (!isLoading &&
//             _alignmentX != 0.0 &&
//             !ModalRoute.of(context)!.isCurrent) {
//           _alignmentX = 0.0;
//         }

//         return Container(
//           width: double.infinity,
//           height: _sliderHeight,
//           clipBehavior: Clip.antiAlias,
//           decoration: BoxDecoration(
//             color: isLoading ? Colors.grey.shade300 : Colors.grey.shade100,
//             borderRadius: BorderRadius.circular(20),
//             border: Border.all(color: Colors.black.withOpacity(0.05), width: 1),
//           ),
//           child: Stack(
//             alignment: Alignment.center,
//             children: [
//               // 1. Sleek Modern Text Indicators
//               if (!isLoading) ...[
//                 AnimatedOpacity(
//                   duration: const Duration(milliseconds: 150),
//                   opacity: (1.0 - _alignmentX.abs() * 2).clamp(0.0, 0.4),
//                   child: const Text(
//                     '⟪  Swipe to Choose  ⟫',
//                     style: TextStyle(
//                       fontSize: 13,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.black,
//                       letterSpacing: 0.5,
//                     ),
//                   ),
//                 ),

//                 // Left Text (Cancel Indicator)
//                 Positioned(
//                   left: 24,
//                   child: AnimatedOpacity(
//                     duration: const Duration(milliseconds: 100),
//                     opacity: _alignmentX < 0
//                         ? (_alignmentX.abs()).clamp(0.5, 1.0)
//                         : 0.15,
//                     child: Row(
//                       children: [
//                         Icon(
//                           Icons.close_rounded,
//                           size: 16,
//                           color: Colors.red.shade600,
//                         ),
//                         const SizedBox(width: 6),
//                         Text(
//                           'Cancel',
//                           style: TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.red.shade600,
//                             letterSpacing: 0.2,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),

//                 // Right Text (Confirm Indicator)
//                 Positioned(
//                   right: 24,
//                   child: AnimatedOpacity(
//                     duration: const Duration(milliseconds: 100),
//                     opacity: _alignmentX > 0
//                         ? _alignmentX.clamp(0.5, 1.0)
//                         : 0.15,
//                     child: Row(
//                       children: [
//                         Text(
//                           'Approve',
//                           style: TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.green.shade700,
//                             letterSpacing: 0.2,
//                           ),
//                         ),
//                         const SizedBox(width: 6),
//                         Icon(
//                           Icons.check_rounded,
//                           size: 16,
//                           color: Colors.green.shade700,
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],

//               if (isLoading)
//                 const SizedBox(
//                   width: 22,
//                   height: 22,
//                   child: CircularProgressIndicator(
//                     color: Colors.black87,
//                     strokeWidth: 2.5,
//                   ),
//                 ),

//               // 2. High-Fidelity Interactive Slider Thumb
//               if (!isLoading)
//                 GestureDetector(
//                   onHorizontalDragUpdate: (details) {
//                     final renderBox = context.findRenderObject() as RenderBox?;
//                     if (renderBox != null) {
//                       setState(() {
//                         _alignmentX +=
//                             details.primaryDelta! / (renderBox.size.width / 2);
//                         _alignmentX = _alignmentX.clamp(-1.0, 1.0);
//                       });
//                     }
//                   },
//                   onHorizontalDragEnd: (details) {
//                     if (_alignmentX > 0.85) {
//                       setState(() => _alignmentX = 1.0);
//                       debugPrint(
//                         '🟢 [OrderApproval] Confirmed — orderId: ${widget.orderId}',
//                       );
//                       context.read<OrderApprovalBloc>().add(
//                         ConfirmOrderApproval(widget.orderId),
//                       );
//                     } else if (_alignmentX < -0.85) {
//                       setState(() => _alignmentX = -1.0);
//                       debugPrint(
//                         '🔴 [OrderApproval] Cancelled — orderId: ${widget.orderId}',
//                       );
//                       Navigator.of(context).pop();
//                     } else {
//                       setState(() => _alignmentX = 0.0);
//                     }
//                   },
//                   child: Align(
//                     alignment: Alignment(_alignmentX, 0.0),
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 4.0),
//                       child: AnimatedContainer(
//                         duration: const Duration(milliseconds: 100),
//                         width: _handleSize,
//                         height: _handleSize,
//                         decoration: BoxDecoration(
//                           color: _alignmentX == 0
//                               ? const Color(0xFF1E1E1E)
//                               : _alignmentX > 0
//                               ? Color.lerp(
//                                   const Color(0xFF1E1E1E),
//                                   Colors.green.shade600,
//                                   _alignmentX,
//                                 )
//                               : Color.lerp(
//                                   const Color(0xFF1E1E1E),
//                                   Colors.red.shade600,
//                                   _alignmentX.abs(),
//                                 ),
//                           borderRadius: BorderRadius.circular(16),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.15),
//                               blurRadius: 10,
//                               offset: const Offset(0, 4),
//                             ),
//                           ],
//                         ),
//                         child: AnimatedSwitcher(
//                           duration: const Duration(milliseconds: 150),
//                           child: Icon(
//                             _alignmentX == 0
//                                 ? Icons.drag_handle_rounded
//                                 : _alignmentX > 0
//                                 ? Icons.check_circle_outline_rounded
//                                 : Icons.cancel_outlined,
//                             key: ValueKey<int>((_alignmentX * 10).round()),
//                             color: Colors.white,
//                             size: 22,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }

// // ═══════════════════════════════════════════════════════════════════════════════
// // APPROVAL RESULT BOTTOM SHEET
// // ═══════════════════════════════════════════════════════════════════════════════

// class _ApprovalResultSheet extends StatelessWidget {
//   final bool success;
//   final String message;

//   const _ApprovalResultSheet({required this.success, required this.message});

//   @override
//   Widget build(BuildContext context) {
//     final color = success ? const Color(0xFF4CAF50) : Colors.redAccent;
//     final icon = success ? Icons.check_circle_rounded : Icons.cancel_rounded;
//     final title = success ? 'Approval Successful' : 'Approval Failed';

//     return Container(
//       margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         border: Border(left: BorderSide(color: color, width: 4)),
//         boxShadow: const [
//           BoxShadow(
//             color: Color(0x1A000000),
//             blurRadius: 20,
//             offset: Offset(0, -4),
//           ),
//         ],
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             width: 60,
//             height: 60,
//             decoration: BoxDecoration(
//               color: color.withValues(alpha: 0.1),
//               shape: BoxShape.circle,
//             ),
//             child: Icon(icon, color: color, size: 32),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             title,
//             style: const TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.w700,
//               letterSpacing: -0.3,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             message,
//             style: const TextStyle(fontSize: 13, color: Colors.black45),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 24),
//           GestureDetector(
//             onTap: () => Navigator.pop(context),
//             child: Container(
//               width: double.infinity,
//               height: 48,
//               decoration: BoxDecoration(
//                 color: Colors.black,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: const Center(
//                 child: Text(
//                   'Done',
//                   style: TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w700,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ═══════════════════════════════════════════════════════════════════════════════
// // FULL SCREEN IMAGE VIEWER
// // ═══════════════════════════════════════════════════════════════════════════════

// class FullScreenImageViewer extends StatelessWidget {
//   final String base64Image;

//   const FullScreenImageViewer({required this.base64Image, super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         backgroundColor: Colors.black,
//         iconTheme: const IconThemeData(color: Colors.white),
//         title: const Text('Order Image', style: TextStyle(color: Colors.white)),
//       ),
//       body: Center(
//         child: InteractiveViewer(
//           minScale: 0.5,
//           maxScale: 5.0,
//           child: Image.memory(
//             base64Decode(base64Image.split(',').last),
//             fit: BoxFit.contain,
//             errorBuilder: (_, _, _) =>
//                 const Icon(Icons.error, color: Colors.white, size: 80),
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ═══════════════════════════════════════════════════════════════════════════════
// // ORDER IMAGE THUMBNAIL
// // ═══════════════════════════════════════════════════════════════════════════════

// class _OrderImage extends StatelessWidget {
//   final String base64Image;
//   const _OrderImage({required this.base64Image});

//   @override
//   Widget build(BuildContext context) {
//     try {
//       final bytes = base64Decode(base64Image.split(',').last);
//       return ClipRRect(
//         borderRadius: BorderRadius.circular(16),
//         child: Image.memory(
//           bytes,
//           height: 220,
//           width: double.infinity,
//           fit: BoxFit.cover,
//         ),
//       );
//     } catch (e) {
//       return Container(
//         height: 220,
//         decoration: BoxDecoration(
//           color: Colors.grey[300],
//           borderRadius: BorderRadius.circular(16),
//         ),
//         child: const Center(child: Text('Image Load Failed')),
//       );
//     }
//   }
// }

// // ═══════════════════════════════════════════════════════════════════════════════
// // PRODUCT ITEM
// // ═══════════════════════════════════════════════════════════════════════════════

// class _ProductItem extends StatelessWidget {
//   final OrderDetailItem item;
//   final int index;

//   const _ProductItem({required this.item, required this.index});

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Container(
//           width: 32,
//           height: 32,
//           decoration: BoxDecoration(
//             color: const Color(0xFFF5F5F5),
//             borderRadius: BorderRadius.circular(9),
//           ),
//           child: Center(
//             child: Text(
//               '${index + 1}',
//               style: const TextStyle(
//                 fontSize: 13,
//                 fontWeight: FontWeight.w700,
//                 color: Colors.black45,
//               ),
//             ),
//           ),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 item.productDesc ?? 'Product #${item.productId}',
//                 style: const TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w600,
//                   letterSpacing: -0.2,
//                 ),
//               ),
//               const SizedBox(height: 6),
//               Wrap(
//                 spacing: 8,
//                 runSpacing: 6,
//                 children: [
//                   _Chip(
//                     label: 'Qty',
//                     value: '${item.unitQty}',
//                     color: const Color(0xFF2196F3),
//                   ),
//                   if (item.pcsQty != null && item.pcsQty! > 0)
//                     _Chip(
//                       label: 'Pcs',
//                       value: '${item.pcsQty}',
//                       color: Colors.teal,
//                     ),
//                   _Chip(
//                     label: 'Rate',
//                     value: '৳${item.unitPrice.toStringAsFixed(2)}',
//                     color: Colors.black,
//                   ),
//                   if (item.discountAmt > 0)
//                     _Chip(
//                       label: 'Disc',
//                       value: '৳${item.discountAmt.toStringAsFixed(2)}',
//                       color: Colors.orangeAccent,
//                     ),
//                   if (item.vat > 0)
//                     _Chip(
//                       label: 'VAT',
//                       value: '${item.vat}%',
//                       color: Colors.purple,
//                     ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text(
//                     'Net Amount',
//                     style: TextStyle(fontSize: 12, color: Colors.black38),
//                   ),
//                   Text(
//                     '৳${item.netAmount.toStringAsFixed(2)}',
//                     style: const TextStyle(
//                       fontSize: 15,
//                       fontWeight: FontWeight.w700,
//                       color: Color(0xFF4CAF50),
//                       letterSpacing: -0.3,
//                     ),
//                   ),
//                 ],
//               ),
//               if (item.remarks != null && item.remarks!.isNotEmpty) ...[
//                 const SizedBox(height: 4),
//                 Text(
//                   '📝 ${item.remarks}',
//                   style: const TextStyle(
//                     fontSize: 12,
//                     color: Colors.black38,
//                     fontStyle: FontStyle.italic,
//                   ),
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }

// // ═══════════════════════════════════════════════════════════════════════════════
// // SECTION CARD
// // ═══════════════════════════════════════════════════════════════════════════════

// class _SectionCard extends StatelessWidget {
//   final Color accent;
//   final String title;
//   final IconData icon;
//   final Widget child;

//   const _SectionCard({
//     required this.accent,
//     required this.title,
//     required this.icon,
//     required this.child,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border(left: BorderSide(color: accent, width: 3)),
//         boxShadow: const [
//           BoxShadow(
//             color: Color(0x0D000000),
//             blurRadius: 10,
//             offset: Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Container(
//                   width: 30,
//                   height: 30,
//                   decoration: BoxDecoration(
//                     color: accent.withValues(alpha: 0.1),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Icon(icon, color: accent, size: 16),
//                 ),
//                 const SizedBox(width: 10),
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 13,
//                     fontWeight: FontWeight.w700,
//                     color: Colors.black54,
//                     letterSpacing: 0.2,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 14),
//             const Divider(height: 1, color: Color(0xFFF5F5F5)),
//             const SizedBox(height: 12),
//             child,
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ═══════════════════════════════════════════════════════════════════════════════
// // INFO ROW
// // ═══════════════════════════════════════════════════════════════════════════════

// class _InfoRow extends StatelessWidget {
//   final String label;
//   final String value;
//   final bool isLast;

//   const _InfoRow({
//     required this.label,
//     required this.value,
//     this.isLast = false,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             label,
//             style: const TextStyle(fontSize: 13, color: Colors.black45),
//           ),
//           const SizedBox(width: 16),
//           Flexible(
//             child: Text(
//               value,
//               style: const TextStyle(
//                 fontSize: 13,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.black87,
//               ),
//               textAlign: TextAlign.right,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ═══════════════════════════════════════════════════════════════════════════════
// // CHIP
// // ═══════════════════════════════════════════════════════════════════════════════

// class _Chip extends StatelessWidget {
//   final String label;
//   final String value;
//   final Color color;

//   const _Chip({required this.label, required this.value, required this.color});

//   @override
//   Widget build(BuildContext context) => Container(
//     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//     decoration: BoxDecoration(
//       color: color.withValues(alpha: 0.08),
//       borderRadius: BorderRadius.circular(8),
//       border: Border.all(color: color.withValues(alpha: 0.2)),
//     ),
//     child: RichText(
//       text: TextSpan(
//         children: [
//           TextSpan(
//             text: '$label: ',
//             style: TextStyle(
//               fontSize: 11,
//               color: color.withValues(alpha: 0.7),
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           TextSpan(
//             text: value,
//             style: TextStyle(
//               fontSize: 12,
//               color: color,
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//         ],
//       ),
//     ),
//   );
// }

// // ═══════════════════════════════════════════════════════════════════════════════
// // STATUS BADGE
// // ═══════════════════════════════════════════════════════════════════════════════

// class _StatusBadge extends StatelessWidget {
//   final String label;
//   final Color color;
//   const _StatusBadge({required this.label, required this.color});

//   @override
//   Widget build(BuildContext context) => Container(
//     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//     decoration: BoxDecoration(
//       color: color.withValues(alpha: 0.12),
//       borderRadius: BorderRadius.circular(20),
//     ),
//     child: Text(
//       label,
//       style: TextStyle(
//         fontSize: 12,
//         fontWeight: FontWeight.w700,
//         color: color,
//         letterSpacing: 0.2,
//       ),
//     ),
//   );
// }

// // ═══════════════════════════════════════════════════════════════════════════════
// // LOADING VIEW
// // ═══════════════════════════════════════════════════════════════════════════════

// class _LoadingView extends StatelessWidget {
//   const _LoadingView();

//   @override
//   Widget build(BuildContext context) => ListView(
//     padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
//     children: const [
//       _ShimmerBox(height: 100),
//       SizedBox(height: 12),
//       _ShimmerBox(height: 180),
//       SizedBox(height: 12),
//       _ShimmerBox(height: 100),
//       SizedBox(height: 12),
//       _ShimmerBox(height: 160),
//     ],
//   );
// }

// // ═══════════════════════════════════════════════════════════════════════════════
// // SHIMMER BOX
// // ═══════════════════════════════════════════════════════════════════════════════

// class _ShimmerBox extends StatefulWidget {
//   final double height;
//   const _ShimmerBox({required this.height});

//   @override
//   State<_ShimmerBox> createState() => _ShimmerBoxState();
// }

// class _ShimmerBoxState extends State<_ShimmerBox>
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
//   Widget build(BuildContext context) => AnimatedBuilder(
//     animation: _anim,
//     builder: (_, _) => Opacity(
//       opacity: _anim.value,
//       child: Container(
//         height: widget.height,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           border: Border(
//             left: BorderSide(color: Colors.grey.shade200, width: 3),
//           ),
//           boxShadow: const [
//             BoxShadow(
//               color: Color(0x0D000000),
//               blurRadius: 10,
//               offset: Offset(0, 4),
//             ),
//           ],
//         ),
//       ),
//     ),
//   );
// }

// // ═══════════════════════════════════════════════════════════════════════════════
// // ERROR VIEW
// // ═══════════════════════════════════════════════════════════════════════════════

// class _ErrorView extends StatelessWidget {
//   final String message;
//   final VoidCallback onRetry;

//   const _ErrorView({required this.message, required this.onRetry});

//   @override
//   Widget build(BuildContext context) => Center(
//     child: Padding(
//       padding: const EdgeInsets.all(32),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             width: 64,
//             height: 64,
//             decoration: BoxDecoration(
//               color: const Color(0xFFFFF0F0),
//               borderRadius: BorderRadius.circular(16),
//             ),
//             child: const Icon(
//               Icons.wifi_off_rounded,
//               color: Colors.redAccent,
//               size: 32,
//             ),
//           ),
//           const SizedBox(height: 16),
//           const Text(
//             'Failed to load details',
//             style: TextStyle(
//               fontSize: 17,
//               fontWeight: FontWeight.w700,
//               letterSpacing: -0.3,
//             ),
//           ),
//           const SizedBox(height: 6),
//           Text(
//             message,
//             style: const TextStyle(fontSize: 13, color: Colors.black45),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 24),
//           GestureDetector(
//             onTap: onRetry,
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 13),
//               decoration: BoxDecoration(
//                 color: Colors.black,
//                 borderRadius: BorderRadius.circular(12),
//                 boxShadow: const [
//                   BoxShadow(
//                     color: Color(0x26000000),
//                     blurRadius: 12,
//                     offset: Offset(0, 6),
//                   ),
//                 ],
//               ),
//               child: const Text(
//                 'Retry',
//                 style: TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     ),
//   );
// }
