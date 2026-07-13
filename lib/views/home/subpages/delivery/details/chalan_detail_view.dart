import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marketing/bloc/chalan-confirm/repo/challan_confirm.dart';
import 'package:marketing/bloc/chalan-deleiver/update_chalan.dart';
import 'package:marketing/bloc/chalan-details/channal_bloc.dart';
import 'package:marketing/bloc/chalan-details/repository/chalan_details_repo.dart';
import 'package:marketing/bloc/chalan-confirm/confirm_challan_bloc.dart';

import 'package:marketing/services/models/chalan_details.dart';

class ChallanDetailsView extends StatelessWidget {
  final int challanId;
  final String orderNo;
  final Color accentColor;

  const ChallanDetailsView({
    super.key,
    required this.challanId,
    required this.orderNo,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              ChallanDetailsBloc(repository: ChallanDetailsRepository())
                ..add(FetchChallanDetails(challanId: challanId)),
        ),
        BlocProvider(
          create: (_) =>
              ConfirmChallanBloc(repository: ConfirmChallanRepository()),
        ),
      ],
      child: _ChallanDetailsBody(
        challanId: challanId,
        orderNo: orderNo,
        accentColor: accentColor,
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// BODY
// ════════════════════════════════════════════════════════════════════════════

class _ChallanDetailsBody extends StatelessWidget {
  final int challanId;
  final String orderNo;
  final Color accentColor;

  const _ChallanDetailsBody({
    required this.challanId,
    required this.orderNo,
    required this.accentColor,
  });

  static String _fmt(String raw) {
    if (raw.length != 8) return raw.isEmpty ? '—' : raw;
    const m = [
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
      return '${raw.substring(6, 8)} ${m[int.parse(raw.substring(4, 6))]} ${raw.substring(0, 4)}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: BlocBuilder<ChallanDetailsBloc, ChallanDetailsState>(
          builder: (context, state) {
            final String headerTitle = state is ChallanDetailsLoaded
                ? (state.details.orderNo.isNotEmpty
                      ? state.details.orderNo
                      : 'Challan No #${state.details.challanNo}')
                : (orderNo.isNotEmpty ? orderNo : 'Challan #$challanId');

            final String badgeLabel = state is ChallanDetailsLoaded
                ? state.details.challanType
                : '';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ───────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Challan Details',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black45,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              headerTitle,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (badgeLabel.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            badgeLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: accentColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                Expanded(child: _buildBody(context, state)),
              ],
            );
          },
        ),
      ),
      // ── Bottom Confirm bar ──────────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: BlocConsumer<ConfirmChallanBloc, ConfirmChallanState>(
            listener: (context, state) {
              if (state is ConfirmChallanSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: const [
                        Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Challan confirmed as received',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFF4CAF50),
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
                // Pop back with `true` so the calling page knows to refresh
                // its list (e.g. remove/relabel this challan).
                Navigator.pop(context, true);
              } else if (state is ConfirmChallanFailure) {
                // wasServerRejection = HTTP 200 but body was `false`
                // (request understood, confirm just didn't go through).
                // false = real error (bad status code / network / bad body).
                final isRejection = state.wasServerRejection;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(
                          isRejection
                              ? Icons.warning_amber_rounded
                              : Icons.error_outline_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            state.error,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    // Amber for "server said no", red for "something broke".
                    backgroundColor: isRejection
                        ? const Color(0xFFFF9800)
                        : Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
            builder: (context, state) {
              final isLoading = state is ConfirmChallanLoading;
              final isDone = state is ConfirmChallanSuccess;
              // Both failure kinds leave the button live again so the user
              // can retry — success is the only state that locks it out.

              return GestureDetector(
                onTap: (isLoading || isDone)
                    ? null
                    : () => context.read<ConfirmChallanBloc>().add(
                        ConfirmChallanRequested(challanId: challanId),
                      ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: (isLoading || isDone)
                        ? Colors.black38
                        : Colors.black,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: (isLoading || isDone)
                        ? []
                        : const [
                            BoxShadow(
                              color: Color(0x26000000),
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isLoading) ...[
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Confirming…',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ] else ...[
                        Icon(
                          isDone
                              ? Icons.check_circle_rounded
                              : Icons.check_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isDone ? 'Confirmed' : 'Confirm',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ChallanDetailsState state) {
    if (state is ChallanDetailsLoading || state is ChallanDetailsInitial) {
      return const _DetailsShimmer();
    }
    if (state is ChallanDetailsError) {
      return _ErrorView(
        message: state.message,
        onRetry: () => context.read<ChallanDetailsBloc>().add(
          FetchChallanDetails(challanId: challanId),
        ),
      );
    }
    if (state is ChallanDetailsLoaded) {
      return _DetailsContent(
        data: state.details,
        accentColor: accentColor,
        fmtDate: _fmt,
      );
    }
    return const SizedBox();
  }
}

// ════════════════════════════════════════════════════════════════════════════
// DETAILS CONTENT
// ════════════════════════════════════════════════════════════════════════════

class _DetailsContent extends StatelessWidget {
  final ChallanDetailsModel data;
  final Color accentColor;
  final String Function(String) fmtDate;

  const _DetailsContent({
    required this.data,
    required this.accentColor,
    required this.fmtDate,
  });

  static String _v(String? v) => (v == null || v.trim().isEmpty) ? '—' : v;

  @override
  Widget build(BuildContext context) {
    final totalQty = data.details.fold(0, (s, d) => s + d.unitQty.abs());
    final totalNet = data.details.fold(
      0.0,
      (s, d) => s + d.unitQty.abs() * d.unitPrice,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary chips
          IntrinsicHeight(
            child: Row(
              children: [
                _SummaryChip(
                  label: 'Products',
                  value: '${data.details.length}',
                  icon: Icons.inventory_2_rounded,
                  color: accentColor,
                ),
                const SizedBox(width: 10),
                _SummaryChip(
                  label: 'Total Qty',
                  value: '$totalQty',
                  icon: Icons.layers_rounded,
                  color: const Color(0xFF607D8B),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Challan Info Card
          _InfoCard(
            icon: Icons.local_shipping_rounded,
            iconColor: accentColor,
            title: 'Challan Info',
            children: [
              _InfoRow(label: 'Challan No', value: '#${data.challanNo}'),
              _InfoRow(label: 'Type', value: _v(data.challanType)),
              _InfoRow(
                label: 'Date',
                value: data.challanDate.isNotEmpty
                    ? fmtDate(data.challanDate)
                    : '—',
              ),
              _InfoRow(label: 'Order No', value: _v(data.orderNo)),
              _InfoRow(label: 'Bill To', value: _v(data.billTo)),
              _InfoRow(
                label: 'Delivery Location',
                value: _v(data.deliveryLocation),
              ),
              _InfoRow(label: 'Transport', value: _v(data.transPortName)),
              _InfoRow(label: 'Driver Name', value: _v(data.driverName)),
              _InfoRow(
                label: 'Contact No',
                value: _v(data.driverContactNo),
                isLast: true,
              ),
            ],
          ),

          const SizedBox(height: 20),

          _SectionLabel(
            icon: Icons.list_alt_rounded,
            label: 'Products (${data.details.length})',
            color: const Color(0xFF607D8B),
          ),
          const SizedBox(height: 12),

          if (data.details.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 40),
                child: Column(
                  children: [
                    Icon(Icons.inbox_rounded, size: 48, color: Colors.black12),
                    SizedBox(height: 12),
                    Text(
                      'No products found',
                      style: TextStyle(fontSize: 14, color: Colors.black38),
                    ),
                  ],
                ),
              ),
            )
          else
            ...data.details.asMap().entries.map(
              (e) => _ProductCard(
                index: e.key + 1,
                item: e.value,
                accentColor: accentColor,
                challanId: data.challanId,
              ),
            ),

          if (data.details.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accentColor.withValues(alpha: 0.15)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Grand Total',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '৳${totalNet.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// PRODUCT CARD  — Edit button wired to UpdateChallanBloc
// ════════════════════════════════════════════════════════════════════════════

class _ProductCard extends StatefulWidget {
  final int index;
  final ChallanDetailItem item;
  final Color accentColor;
  final int challanId;

  const _ProductCard({
    required this.index,
    required this.item,
    required this.accentColor,
    required this.challanId,
  });

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  late String _remarks;
  late int _returnQty;

  @override
  void initState() {
    super.initState();
    _remarks = widget.item.remarks;
    _returnQty = widget.item.returnQty;
  }

  void _showUpdateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider(
        create: (_) => UpdateChallanBloc(),
        child: _UpdateFieldsSheet(
          item: widget.item,
          challanId: widget.challanId,
          initialRemarks: _remarks,
          initialReturnQty: _returnQty,
          accentColor: widget.accentColor,
          onLocalUpdate: (newRemarks, newReturnQty) {
            setState(() {
              _remarks = newRemarks;
              _returnQty = newReturnQty;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final qty = widget.item.unitQty.abs();
    final netAmount = qty * widget.item.unitPrice;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: widget.accentColor, width: 3)),
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
            // ── Header row ──────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: widget.accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${widget.index}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: widget.accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.item.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                // Edit button — only shown when not approved
                if (widget.item.isApproved == 0)
                  GestureDetector(
                    onTap: _showUpdateSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: widget.accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: widget.accentColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit_rounded,
                            size: 14,
                            color: widget.accentColor,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Edit',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: widget.accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size: 13,
                          color: Colors.green,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Approved',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 6),

            // Description tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Text(
                widget.item.description,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black54,
                  fontStyle: widget.item.description.isEmpty
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Qty + Rate badges
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _Badge(label: 'Qty', value: '$qty', color: widget.accentColor),
                _Badge(
                  label: 'Rate',
                  value: '৳${widget.item.unitPrice.toStringAsFixed(2)}',
                  color: const Color(0xFF2196F3),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Divider(height: 1, color: Colors.grey.shade100, thickness: 1),
            const SizedBox(height: 10),

            // Remarks & Return Qty — update locally after edit
            _InfoRow(
              label: 'Remarks',
              value: _remarks.isEmpty ? '—' : _remarks,
            ),
            const SizedBox(height: 8),
            _InfoRow(
              label: 'Return Qty',
              value: _returnQty == 0 ? '0 units' : '$_returnQty units',
            ),

            const SizedBox(height: 10),
            Divider(height: 1, color: Colors.grey.shade100, thickness: 1),
            const SizedBox(height: 10),

            // Net amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Net Amount',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '৳${netAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: widget.accentColor,
                    letterSpacing: -0.3,
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

// ════════════════════════════════════════════════════════════════════════════
// UPDATE FIELDS SHEET  — blank fields + auto-focus on notes
// ════════════════════════════════════════════════════════════════════════════

class _UpdateFieldsSheet extends StatefulWidget {
  final ChallanDetailItem item;
  final String initialRemarks;
  final int initialReturnQty;
  final Color accentColor;
  final int challanId;

  final void Function(String remarks, int returnQty) onLocalUpdate;

  const _UpdateFieldsSheet({
    required this.item,
    required this.initialRemarks,
    required this.initialReturnQty,
    required this.accentColor,
    required this.onLocalUpdate,
    required this.challanId,
  });

  @override
  State<_UpdateFieldsSheet> createState() => _UpdateFieldsSheetState();
}

class _UpdateFieldsSheetState extends State<_UpdateFieldsSheet> {
  late final TextEditingController _notesCtrl;
  late final TextEditingController _returnQtyCtrl;
  late final FocusNode _notesFocus; // ← NEW

  final DateTime _today = DateTime.now();

  static String _fmtForApi(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

  static String _fmtDisplay(DateTime d) {
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
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month]} ${d.year}';
  }

  @override
  void initState() {
    super.initState();
    // ── Always start blank ───────────────────────────────────────────────
    _notesCtrl = TextEditingController();
    _returnQtyCtrl = TextEditingController();
    _notesFocus = FocusNode();

    // ── Request focus on notes field after the sheet finishes building ───
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notesFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _returnQtyCtrl.dispose();
    _notesFocus.dispose(); // ← NEW
    super.dispose();
  }

  void _submit() {
    final notes = _notesCtrl.text.trim();
    final returnQty = int.tryParse(_returnQtyCtrl.text.trim()) ?? 0;

    context.read<UpdateChallanBloc>().add(
      SubmitUpdateChallan(
        UpdateChallanRequest(
          id: widget.item.autoChallanId,
          challanId: widget.challanId,
          qty: returnQty,
          notes: notes,
          returnDate: _today,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return BlocListener<UpdateChallanBloc, UpdateChallanState>(
      listener: (context, state) {
        if (state is UpdateChallanSuccess) {
          widget.onLocalUpdate(
            _notesCtrl.text.trim(),
            int.tryParse(_returnQtyCtrl.text.trim()) ?? 0,
          );
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Challan updated successfully',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF4CAF50),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        } else if (state is UpdateChallanFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.error,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5F5),
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Drag handle ─────────────────────────────────────────────
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Sheet header ─────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Edit Details',
                      style: TextStyle(fontSize: 13, color: Colors.black45),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.item.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: widget.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: widget.accentColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'Qty: ${widget.item.unitQty.abs()}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: widget.accentColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Return Date — read-only, shows today ─────────────────────
            const Text(
              'Return Date',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black45,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: const Border(
                  left: BorderSide(color: Color(0xFF2196F3), width: 3),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.calendar_today_rounded,
                      size: 16,
                      color: Color(0xFF2196F3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _fmtDisplay(_today),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        'API value: ${_fmtForApi(_today)}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black38,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 14,
                    color: Colors.black26,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Notes field ──────────────────────────────────────────────
            const Text(
              'Notes',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black45,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _notesCtrl,
                focusNode: _notesFocus, // ← NEW
                maxLines: 3,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Add notes here...',
                  hintStyle: const TextStyle(
                    color: Colors.black26,
                    fontSize: 13,
                  ),
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ── Return Qty field ─────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Return Qty',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black45,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                Text(
                  'Max: ${widget.item.unitQty.abs()} units',
                  style: const TextStyle(fontSize: 11, color: Colors.black38),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _returnQtyCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: const TextStyle(color: Colors.black26),
                  suffixText: 'units',
                  suffixStyle: const TextStyle(
                    color: Colors.black38,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Submit button — reacts to BLoC loading state ─────────────
            BlocBuilder<UpdateChallanBloc, UpdateChallanState>(
              builder: (context, state) {
                final isLoading = state is UpdateChallanLoading;
                return GestureDetector(
                  onTap: isLoading ? null : _submit,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isLoading ? Colors.black38 : Colors.black,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isLoading
                          ? []
                          : const [
                              BoxShadow(
                                color: Color(0x26000000),
                                blurRadius: 12,
                                offset: Offset(0, 6),
                              ),
                            ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isLoading) ...[
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Updating…',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ] else ...[
                          const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Update Challan',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ════════════════════════════════════════════════════════════════════════════

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
            child: Icon(icon, size: 15, color: color),
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

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final List<Widget> children;

  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border(left: BorderSide(color: iconColor, width: 3)),
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
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 15, color: iconColor),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: iconColor,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: Colors.grey.shade100, thickness: 1),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  final bool isLast;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
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
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: value == '—' ? Colors.black26 : Colors.black87,
            ),
          ),
        ),
      ],
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionLabel({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 15, color: color),
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

class _Badge extends StatelessWidget {
  final String label, value;
  final Color color;

  const _Badge({required this.label, required this.value, required this.color});

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
          label,
          style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.7)),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    ),
  );
}

// ─── Shimmer ──────────────────────────────────────────────────────────────────

class _DetailsShimmer extends StatefulWidget {
  const _DetailsShimmer();

  @override
  State<_DetailsShimmer> createState() => _DetailsShimmerState();
}

class _DetailsShimmerState extends State<_DetailsShimmer>
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
    builder: (_, _) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(child: _shimmerBox(height: 64)),
                const SizedBox(width: 10),
                Expanded(child: _shimmerBox(height: 64)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _shimmerBox(height: 220),
          const SizedBox(height: 20),
          _bar(120, 16),
          const SizedBox(height: 12),
          _shimmerBox(height: 160),
          const SizedBox(height: 12),
          _shimmerBox(height: 160),
        ],
      ),
    ),
  );

  Widget _shimmerBox({required double height}) => Opacity(
    opacity: _anim.value,
    child: Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
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
}

// ─── Error View ───────────────────────────────────────────────────────────────

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
