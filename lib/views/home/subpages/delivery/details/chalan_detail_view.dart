import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marketing/bloc/chalan-details/channal_bloc.dart';
import 'package:marketing/bloc/chalan-details/repository/chalan_details_repo.dart';
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
    return BlocProvider(
      create: (_) =>
          ChallanDetailsBloc(repository: ChallanDetailsRepository())
            ..add(FetchChallanDetails(challanId: challanId)),
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
    );
  }

  Widget _buildBody(BuildContext context, ChallanDetailsState state) {
    if (state is ChallanDetailsLoading || state is ChallanDetailsInitial)
      return const _DetailsShimmer();
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
// PRODUCT CARD — Edit Button in Top Right
// ════════════════════════════════════════════════════════════════════════════

class _ProductCard extends StatefulWidget {
  final int index;
  final ChallanDetailItem item;
  final Color accentColor;

  const _ProductCard({
    required this.index,
    required this.item,
    required this.accentColor,
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

  void _showUpdatePopup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UpdateFieldsSheet(
        initialRemarks: _remarks,
        initialReturnQty: _returnQty,
        maxQty: widget.item.unitQty.abs(),
        accentColor: widget.accentColor,
        onUpdate: (newRemarks, newReturnQty) {
          setState(() {
            _remarks = newRemarks;
            _returnQty = newReturnQty;
          });
          print('=== UPDATE LOG ===');
          print('Product: ${widget.item.name} (ID: ${widget.item.productId})');
          print('Remarks: $newRemarks');
          print('Return Qty: $newReturnQty');
          print('==================');
        },
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
            // Header with Edit Button
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
                GestureDetector(
                  onTap: _showUpdatePopup,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.edit_rounded,
                      size: 18,
                      color: widget.accentColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
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

            // Normal Fields (non-clickable)
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
// UPDATE POPUP
// ════════════════════════════════════════════════════════════════════════════

class _UpdateFieldsSheet extends StatefulWidget {
  final String initialRemarks;
  final int initialReturnQty;
  final int maxQty;
  final Color accentColor;
  final Function(String, int) onUpdate;

  const _UpdateFieldsSheet({
    required this.initialRemarks,
    required this.initialReturnQty,
    required this.maxQty,
    required this.accentColor,
    required this.onUpdate,
  });

  @override
  State<_UpdateFieldsSheet> createState() => _UpdateFieldsSheetState();
}

class _UpdateFieldsSheetState extends State<_UpdateFieldsSheet> {
  late final TextEditingController _remarksCtrl;
  late final TextEditingController _returnCtrl;

  @override
  void initState() {
    super.initState();
    _remarksCtrl = TextEditingController(text: widget.initialRemarks);
    _returnCtrl = TextEditingController(
      text: widget.initialReturnQty == 0 ? '' : '${widget.initialReturnQty}',
    );
  }

  @override
  void dispose() {
    _remarksCtrl.dispose();
    _returnCtrl.dispose();
    super.dispose();
  }

  void _update() {
    final remarks = _remarksCtrl.text.trim();
    final returnQty = int.tryParse(_returnCtrl.text.trim()) ?? 0;
    widget.onUpdate(remarks, returnQty);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Update Fields',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: widget.accentColor,
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Remarks',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _remarksCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Enter remarks...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: widget.accentColor),
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Text(
            'Return Quantity',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _returnCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: '0',
              suffixText: 'units',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: widget.accentColor),
              ),
            ),
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _update,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accentColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Update',
                style: TextStyle(
                  fontSize: 16,
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

// Shimmer
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
                Expanded(child: _fbox(double.infinity, 64)),
                const SizedBox(width: 10),
                Expanded(child: _fbox(double.infinity, 64)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _card(rows: 9),
          const SizedBox(height: 20),
          _bar(120, 16),
          const SizedBox(height: 12),
          _product(),
          _product(),
        ],
      ),
    ),
  );

  Widget _card({required int rows}) => Opacity(
    opacity: _anim.value,
    child: Container(/* your original card shimmer code */),
  );
  Widget _product() => Opacity(
    opacity: _anim.value,
    child: Container(/* your original product shimmer */),
  );
  Widget _bar(double w, double h, {double r = 6}) => Container(
    width: w == double.infinity ? null : w,
    height: h,
    decoration: BoxDecoration(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(r),
    ),
  );
  Widget _fbox(double w, double h) => Opacity(
    opacity: _anim.value,
    child: Container(
      width: w == double.infinity ? null : w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
    ),
  );
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
