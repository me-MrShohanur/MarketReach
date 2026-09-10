import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marketing/bloc/order/order_details.dart';
import 'package:marketing/bloc/order/save_aproval.dart';
import 'package:marketing/services/provider/ordersave_service.dart';
import 'package:marketing/services/models/products_model.dart';

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
                _Header(orderNo: orderNo, orderId: orderId),
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
      isDismissible: false,
      builder: (_) => _ApprovalResultSheet(
        success: success,
        message: message,
        isApprove: isApprove,
        onDone: () {
          Navigator.pop(context);
          Navigator.pop(context, true);
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// HEADER
// ═══════════════════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  final String orderNo;
  final int orderId;

  const _Header({required this.orderNo, required this.orderId});

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
          Row(
            children: [
              BlocBuilder<OrderDetailBloc, OrderDetailState>(
                builder: (_, state) {
                  if (state is! OrderDetailLoaded)
                    return const SizedBox.shrink();
                  return _StatusBadge(
                    label:
                        state.order.statusName ??
                        _statusLabel(state.order.status),
                    color: _statusColor(state.order.status),
                  );
                },
              ),
              const SizedBox(width: 8),
              // ── Edit/Save Button ──
              BlocBuilder<OrderDetailBloc, OrderDetailState>(
                builder: (_, state) {
                  if (state is! OrderDetailLoaded)
                    return const SizedBox.shrink();
                  if (state.order.status != 0) return const SizedBox.shrink();

                  return GestureDetector(
                    onTap: () {
                      if (state.isEditing) {
                        _saveOrder(context, state);
                      } else {
                        context.read<OrderDetailBloc>().add(
                          ToggleEditMode(true),
                        );
                        Future.delayed(const Duration(milliseconds: 300), () {
                          _scrollToProducts(context);
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: state.isEditing
                            ? const Color(0xFF4CAF50)
                            : Colors.black,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            state.isEditing
                                ? Icons.save_rounded
                                : Icons.edit_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            state.isEditing ? 'Save' : 'Edit',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _scrollToProducts(BuildContext context) {
    final productsKey = _DetailBody.productsKey;
    final context2 = productsKey.currentContext;
    if (context2 != null) {
      Scrollable.ensureVisible(
        context2,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    }
  }

  // ─── Save Order Function ────────────────────────────────────────────────────
  void _saveOrder(BuildContext context, OrderDetailLoaded state) async {
    final order = state.order;
    final editedFields = state.editedFields;

    log('════════════════════════════════════════');
    log('📝 UPDATING ORDER QUANTITIES');
    log('════════════════════════════════════════');
    log('Order ID: ${order.orderId}');
    log('Order No: ${order.orderNo}');
    log('Details count: ${order.details.length}');
    // ─── Log all detail IDs before saving ────────────────────────────────────
    for (int i = 0; i < order.details.length; i++) {
      final d = order.details[i];
      log(
        '📌 Detail $i: id=${d.id}, productId=${d.productId}, orderId=${d.orderId}, qty=${d.unitQty}',
      );
    }

    try {
      // ─── Build updated details with the CORRECT ID ──────────────────────────
      final List<Map<String, dynamic>> updatedDetails = order.details.map((d) {
        final newQtyStr = editedFields['qty_${d.productId}'];
        final double qty;
        if (newQtyStr != null && newQtyStr.isNotEmpty) {
          qty = double.tryParse(newQtyStr) ?? d.unitQty.toDouble();
        } else {
          qty = d.unitQty.toDouble();
        }

        final newNetAmount = (qty * d.unitPrice) - d.discountAmt;

        log(
          '🔄 Detail: id=${d.id}, productId=${d.productId}, oldQty=${d.unitQty}, newQty=$qty',
        );

        return {
          'id': d.id, // ← Detail line ID (e.g., 29793)
          'orderId': order.orderId,
          'productId': d.productId,
          'productDesc': d.productDesc ?? '',
          'productTypeId': d.productTypeId,
          'unitId': d.unitId,
          'sizeId': d.sizeId,
          'rdId': d.rdId ?? 0,
          'unitQty': qty,
          'pcsQty': d.pcsQty ?? qty.toInt(),
          'tQty': qty.toInt(),
          'uniqueQty': qty,
          'unitPrice': d.unitPrice,
          'uniquePrice': d.uniquePrice ?? d.unitPrice,
          'discount': d.discount ?? 0,
          'discountAmt': d.discountAmt,
          'netAmount': newNetAmount,
          'vat': d.vat,
          'forfeiture': d.forfeiture ?? 0,
          'factor': d.factor ?? 1.0,
          'boxConv': d.boxConv ?? 0,
          'orderType': d.orderType ?? order.orderType,
          'compId': order.compId,
          'branchId': order.branchId,
          'custRef': d.custRef ?? '',
          'remarks': d.remarks ?? '',
        };
      }).toList();

      // ─── Log detail IDs being sent to the server ─────────────────────────────
      final detailIds = updatedDetails.map((d) => d['id']).toList();
      log('📤 Detail IDs being sent to server: $detailIds');

      // ─── Build master data ────────────────────────────────────────────────────
      final Map<String, dynamic> master = {
        'partyId': order.partyId,
        'compId': order.compId,
        'branchId': order.branchId,
        'userId': order.userId ?? 0,
        'orderType': order.orderType,
        'orderDate': order.orderDate,
        'chequeDate': order.chequeDate ?? '',
        'orderId': order.orderId,
        'quoteId': 0,
        'status': order.status,
        'netAmount': order.netAmount,
        'netPayable': order.netPayable,
        'discountAmount': order.discountAmount,
        'discountRate': order.discountRate,
        'vatAmount': order.vatAmount,
        'vatRate': order.vatRate,
        'paidAmount': order.paidAmount,
        'deposite': order.deposite,
        'percentAmount': 0,
        'bankId': order.bankId ?? 0,
        'currencyId': 0,
        'currencyRate': order.currencyRate,
        'otherAddition': order.otherAddition,
        'otherDeduction': order.otherDeduction,
        'orderNo': order.orderNo,
        'refNo': order.refNo ?? '',
        'narration': order.narration ?? '',
        'paymentType': order.paymentType ?? '',
        'billTo': order.billTo ?? '',
        'billAddress': order.billAddress ?? '',
        'billContactNo': order.billContactNo ?? '',
        'billEmail': '',
        'billTerms': '',
        'shippingAddress': '',
        'shippingContract': '',
        'shippingEmail': '',
        'shippingContractName': '',
        'city': '',
        'postalCode': '',
        'checkedNarration': order.checkedNarration ?? '',
        'verifiedNarration': order.verifiedNarration ?? '',
        'rejectedNarration': order.rejectedNarration ?? '',
        'managementNarration': order.managementNarration ?? '',
      };

      // ─── Convert to ProductModel for the service ────────────────────────────
      final List<ProductModel> cartProducts = updatedDetails.map((d) {
        return ProductModel(
          productId: d['productId'],
          name: d['productDesc'] ?? 'Product ${d['productId']}',
          categoryId: 0,
          salePrice: d['unitPrice'],
          depoDiscount: 0,
          factor: d['factor'] ?? 1.0,
          compId: order.compId,
          discountRate: d['discount'] ?? 0.0,
          cartQty: d['unitQty'].toDouble(),
          cartRate: d['unitPrice'],
          cartDiscount: d['discount'] ?? 0.0,
          cartDiscountAmt: d['discountAmt'],
          cartNetAmount: d['netAmount'],
          cartNotes: d['remarks'] ?? '',
        );
      }).toList();

      // ─── Parse cheque date ────────────────────────────────────────────────────
      DateTime? chequeDate;
      if (order.chequeDate != null && order.chequeDate!.isNotEmpty) {
        try {
          final dateStr = order.chequeDate!;
          if (dateStr.length == 8) {
            final year = int.parse(dateStr.substring(0, 4));
            final month = int.parse(dateStr.substring(4, 6));
            final day = int.parse(dateStr.substring(6, 8));
            chequeDate = DateTime(year, month, day);
          }
        } catch (_) {}
      }

      // ─── Call the save API with orderId ──────────────────────────────────────
      final response = await OrderSaveService.saveOrder(
        partyId: order.partyId,
        cart: cartProducts,
        discount: order.discountAmount,
        tax: order.vatAmount,
        files: null,
        chequeDate: chequeDate,
        shippingAddress: null,
        shippingContact: null,
        netAmount: order.netPayable,
        orderId: order.orderId,
      );

      log('✅ Order updated successfully! Order ID: ${response.orderId}');
      log('════════════════════════════════════════');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Order #${order.orderNo} updated successfully!'),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }

      context.read<OrderDetailBloc>().add(ToggleEditMode(false));
      context.read<OrderDetailBloc>().add(LoadOrderDetail(order.orderId));
    } catch (e) {
      log('❌ Error updating order: $e');
      log('════════════════════════════════════════');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating order: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
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

  static final GlobalKey productsKey = GlobalKey();

  const _DetailBody({required this.order, required this.orderId});

  bool get _isPendingConfirm {
    return order.status == -1 || order.status == 0;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderDetailBloc, OrderDetailState>(
      builder: (context, state) {
        final isEditing = state is OrderDetailLoaded && state.isEditing;

        return Stack(
          children: [
            ListView(
              padding: EdgeInsets.fromLTRB(
                24,
                0,
                24,
                _isPendingConfirm ? 120 : 24,
              ),
              children: [
                if (order.base64File != null && order.base64File!.isNotEmpty)
                  GestureDetector(
                    onTap: () =>
                        _showFullScreenImage(context, order.base64File!),
                    child: _OrderImage(base64Image: order.base64File!),
                  ),
                const SizedBox(height: 12),

                _SectionCard(
                  accent: const Color(0xFF2196F3),
                  title: 'Customer',
                  icon: Icons.person_outline_rounded,
                  child: Column(
                    children: [
                      _InfoRow(label: 'Bill To', value: order.billTo ?? '—'),
                      _InfoRow(
                        label: 'Address',
                        value: order.billAddress ?? '—',
                      ),
                      _InfoRow(
                        label: 'Contact',
                        value: order.billContactNo ?? '—',
                      ),
                      _InfoRow(label: 'Order Date', value: order.formattedDate),
                      if (order.chequeDate != null &&
                          order.chequeDate!.isNotEmpty)
                        _InfoRow(
                          label: 'Cheque Date',
                          value: order.chequeDate!,
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

                _SectionCard(
                  accent: const Color(0xFFFFC107),
                  title: 'Payment',
                  icon: Icons.payments_outlined,
                  child: Column(
                    children: [
                      _InfoRow(
                        label: 'Payment Type',
                        value: order.paymentType ?? '—',
                      ),
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

                Container(
                  key: productsKey,
                  child: _SectionCard(
                    accent: Colors.black,
                    title: 'Products (${order.details.length})',
                    icon: Icons.inventory_2_outlined,
                    child: order.details.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'No product details available',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black38,
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              for (
                                int i = 0;
                                i < order.details.length;
                                i++
                              ) ...[
                                if (i > 0)
                                  const Divider(
                                    height: 20,
                                    color: Color(0xFFF0F0F0),
                                  ),
                                _EditableProductItem(
                                  item: order.details[i],
                                  index: i,
                                  isEditing: isEditing,
                                  shouldFocus: isEditing && i == 0,
                                ),
                              ],
                            ],
                          ),
                  ),
                ),
              ],
            ),
            if (_isPendingConfirm)
              Positioned(
                left: 16,
                right: 16,
                bottom: 24,
                child: _ApprovalSlider(orderId: orderId),
              ),
          ],
        );
      },
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
// EDITABLE PRODUCT ITEM
// ═══════════════════════════════════════════════════════════════════════════════

class _EditableProductItem extends StatefulWidget {
  final OrderDetailItem item;
  final int index;
  final bool isEditing;
  final bool shouldFocus;

  const _EditableProductItem({
    required this.item,
    required this.index,
    required this.isEditing,
    this.shouldFocus = false,
  });

  @override
  State<_EditableProductItem> createState() => _EditableProductItemState();
}

class _EditableProductItemState extends State<_EditableProductItem> {
  final FocusNode _focusNode = FocusNode();

  @override
  void didUpdateWidget(_EditableProductItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldFocus && widget.isEditing) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

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
              '${widget.index + 1}',
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
                widget.item.productDesc ?? 'Product #${widget.item.productId}',
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
                  _EditableChip(
                    label: 'Qty',
                    value: '${widget.item.unitQty}',
                    fieldKey: 'qty_${widget.item.productId}',
                    color: widget.isEditing
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFF2196F3),
                    isEditing: widget.isEditing,
                    focusNode: _focusNode,
                  ),
                  _Chip(
                    label: 'Pcs',
                    value: '${widget.item.pcsQty ?? widget.item.unitQty}',
                    color: Colors.teal,
                  ),
                  _Chip(
                    label: 'Rate',
                    value: '৳${widget.item.unitPrice.toStringAsFixed(2)}',
                    color: Colors.black,
                  ),
                  if (widget.item.discountAmt > 0)
                    _Chip(
                      label: 'Disc',
                      value: '৳${widget.item.discountAmt.toStringAsFixed(2)}',
                      color: Colors.orangeAccent,
                    ),
                  if (widget.item.vat > 0)
                    _Chip(
                      label: 'VAT',
                      value: '${widget.item.vat}%',
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
                    '৳${widget.item.netAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4CAF50),
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              if (widget.item.remarks != null &&
                  widget.item.remarks!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  '📝 ${widget.item.remarks}',
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

// ─── Editable Chip ─────────────────────────────────────────────────────────────

class _EditableChip extends StatefulWidget {
  final String label;
  final String value;
  final String fieldKey;
  final Color color;
  final bool isEditing;
  final FocusNode? focusNode;

  const _EditableChip({
    required this.label,
    required this.value,
    required this.fieldKey,
    required this.color,
    required this.isEditing,
    this.focusNode,
  });

  @override
  State<_EditableChip> createState() => _EditableChipState();
}

class _EditableChipState extends State<_EditableChip> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_EditableChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: widget.isEditing
            ? Colors.green.shade50
            : widget.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.isEditing
              ? Colors.green.shade400
              : widget.color.withValues(alpha: 0.2),
          width: widget.isEditing ? 1.5 : 1,
        ),
      ),
      child: widget.isEditing
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.label}: ',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(
                  width: 50,
                  height: 24,
                  child: TextField(
                    controller: _controller,
                    focusNode: widget.focusNode,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2E7D32),
                    ),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(
                          color: Colors.green.shade300,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(
                          color: Colors.green.shade300,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(
                          color: Colors.green.shade600,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 0,
                      ),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      context.read<OrderDetailBloc>().add(
                        UpdateOrderField(
                          fieldKey: widget.fieldKey,
                          value: value,
                        ),
                      );
                    },
                  ),
                ),
              ],
            )
          : RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${widget.label}: ',
                    style: TextStyle(
                      fontSize: 11,
                      color: widget.color.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: widget.value,
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CHIP (Read-only)
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
// APPROVAL SLIDER
// ═══════════════════════════════════════════════════════════════════════════════

class _ApprovalSlider extends StatefulWidget {
  final int orderId;
  const _ApprovalSlider({required this.orderId});

  @override
  State<_ApprovalSlider> createState() => _ApprovalSliderState();
}

class _ApprovalSliderState extends State<_ApprovalSlider>
    with TickerProviderStateMixin {
  double _alignmentX = 0.0;
  bool _isDragging = false;
  bool _holding = false;
  bool _actionFired = false;
  int _holdSide = 0;

  double _dragStartAlignment = 0.0;
  double _dragStartDx = 0.0;

  final GlobalKey _trackKey = GlobalKey();

  static const double _threshold = 0.80;
  static const double _sliderHeight = 64.0;
  static const double _handleSize = 52.0;

  static bool lastActionWasApprove = true;

  late final AnimationController _holdCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
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
    if (_actionFired) return;
    _cancelHold();
    setState(() => _alignmentX = 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrderApprovalBloc, OrderApprovalState>(
      listener: (context, state) {
        if (state is OrderApprovalSuccess || state is OrderApprovalFailure) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) _resetAll();
          });
        }
      },
      builder: (context, state) {
        final isLoading = state is OrderApprovalLoading;

        return Card(
          color: Colors.transparent,
          elevation: 20,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            key: _trackKey,
            height: _sliderHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Listener(
              onPointerDown: (e) => _onPointerDown(e, isLoading),
              onPointerMove: (e) => _onPointerMove(e, isLoading),
              onPointerUp: (_) => _handleRelease(isLoading),
              onPointerCancel: (_) => _handleRelease(isLoading),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: _sliderHeight - 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: _alignmentX <= 0
                          ? (1.0 - _alignmentX.abs() * 0.6).clamp(0.3, 1.0)
                          : 0.3,
                      child: Row(
                        children: [
                          const SizedBox(width: 6),
                          Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 20,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: _alignmentX >= 0
                          ? (1.0 - _alignmentX.abs() * 0.6).clamp(0.3, 1.0)
                          : 0.3,
                      child: Row(
                        children: [
                          Text(
                            'Confirm',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                      ),
                    ),
                  ),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _alignmentX.abs() < 0.3 ? 0.6 : 0.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '⇄  Slide to act  ⇄',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  if (isLoading)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.black87,
                            strokeWidth: 2.5,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _holdSide == 1 ? 'Approving…' : 'Rejecting…',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
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
                          width: _handleSize + 12,
                          height: _handleSize + 12,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (_holding)
                                AnimatedBuilder(
                                  animation: _holdCtrl,
                                  builder: (_, _) => SizedBox(
                                    width: _handleSize + 12,
                                    height: _handleSize + 12,
                                    child: CircularProgressIndicator(
                                      value: _holdCtrl.value,
                                      strokeWidth: 3.5,
                                      backgroundColor: Colors.black.withValues(
                                        alpha: 0.06,
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
                                duration: const Duration(milliseconds: 150),
                                width: _handleSize,
                                height: _handleSize,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: _alignmentX == 0
                                        ? [
                                            const Color(0xFF2C2C2C),
                                            const Color(0xFF1A1A1A),
                                          ]
                                        : _alignmentX > 0
                                        ? [
                                            Colors.green.shade500,
                                            Colors.green.shade700,
                                          ]
                                        : [
                                            Colors.red.shade500,
                                            Colors.red.shade700,
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _alignmentX == 0
                                          ? Colors.black.withValues(alpha: 0.25)
                                          : _alignmentX > 0
                                          ? Colors.green.withValues(alpha: 0.3)
                                          : Colors.red.withValues(alpha: 0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    _alignmentX == 0
                                        ? Icons.swap_horiz_rounded
                                        : _alignmentX > 0
                                        ? Icons.check_circle_rounded
                                        : Icons.cancel_rounded,
                                    key: ValueKey<int>(
                                      (_alignmentX * 10).round(),
                                    ),
                                    color: Colors.white,
                                    size: 28,
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
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// APPROVAL RESULT BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════════════════════

class _ApprovalResultSheet extends StatelessWidget {
  final bool success;
  final String message;
  final bool isApprove;
  final VoidCallback onDone;

  const _ApprovalResultSheet({
    required this.success,
    required this.message,
    required this.isApprove,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    String title;
    Color color;
    IconData icon;
    String subtitle;

    if (success) {
      if (isApprove) {
        title = 'Order Confirmed!';
        color = const Color(0xFF4CAF50);
        icon = Icons.check_circle_rounded;
        subtitle = 'Order has been confirmed.';
      } else {
        title = 'Order Canceled!';
        color = Colors.redAccent;
        icon = Icons.cancel_rounded;
        subtitle = 'Order has been canceled.';
      }
    } else {
      if (isApprove) {
        title = 'Confirmation Failed';
        color = Colors.redAccent;
        icon = Icons.error_outline_rounded;
        subtitle = 'Something went wrong. Please try again.';
      } else {
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
            onTap: onDone,
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
