// lib/views/home/subpages/pending_orders_view.dart

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marketing/bloc/image/image_order.dart';

import 'package:marketing/bloc/order/pending_order_block.dart';
import 'package:marketing/views/home/subpages/order_details_view.dart';

class PendingOrdersView extends StatefulWidget {
  final List<int> statusFilter;
  final String title;
  final String subtitle;
  final Color accentColor;
  final List<OrderListItem>? preloadedOrders;

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
      _bloc.add(
        PreloadOrderList(
          orders: widget.preloadedOrders!,
          statusFilter: widget.statusFilter,
        ),
      );
    } else {
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
      _load();
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
                    orderId: order.orderId,
                    orderNo: order.orderNo,
                    id: order.id,
                  ),
                ),
              ),
              onAttachTap: () => _OrderAttachSheet.show(context, order: order),
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
  final VoidCallback onAttachTap;

  const _OrderCard({
    required this.order,
    required this.onTap,
    required this.onAttachTap,
  });

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
              // ── Row 1: order no + status badge ──────────────────────────
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

              // ── Row 2: party name ────────────────────────────────────────
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

              // ── Row 3: date + amount + attach button ─────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // date
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

                  // amount + attach button
                  Row(
                    children: [
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
                      const SizedBox(width: 10),

                      // ── Attach button ────────────────────────────────────
                      GestureDetector(
                        onTap: onAttachTap,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.attach_file_rounded,
                            color: Color(0xFF2196F3),
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // ── Balance row ──────────────────────────────────────────────
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

// ─── Order Attach Sheet ───────────────────────────────────────────────────────
// Opens as a bottom sheet with its own SaveImageBloc.
// Lets the user pick files then upload them to SaveImageForOrder.

class _OrderAttachSheet extends StatefulWidget {
  final OrderListItem order;

  const _OrderAttachSheet({required this.order});

  static void show(BuildContext context, {required OrderListItem order}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider(
        create: (_) => SaveImageBloc(),
        child: _OrderAttachSheet(order: order),
      ),
    );
  }

  @override
  State<_OrderAttachSheet> createState() => _OrderAttachSheetState();
}

class _OrderAttachSheetState extends State<_OrderAttachSheet> {
  final List<File> _files = [];

  // ── File pickers ──────────────────────────────────────────────────────────

  Future<void> _pickCamera() async {
    final XFile? photo = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (photo != null) setState(() => _files.add(File(photo.path)));
  }

  Future<void> _pickGallery() async {
    final List<XFile> photos = await ImagePicker().pickMultiImage(
      imageQuality: 80,
    );
    if (photos.isNotEmpty) {
      setState(() {
        for (final p in photos) _files.add(File(p.path));
      });
    }
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
    );
    if (result != null) {
      setState(() {
        for (final f in result.files) {
          if (f.path != null) _files.add(File(f.path!));
        }
      });
    }
  }

  void _removeFile(int index) => setState(() => _files.removeAt(index));

  void _upload() {
    if (_files.isEmpty) return;
    context.read<SaveImageBloc>().add(
      UploadOrderImages(
        orderId: widget.order.id,
        partyId: widget.order.partyId,
        files: List.from(_files),
      ),
    );
  }

  String _ext(File f) {
    final parts = f.path.split('/').last.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : 'file';
  }

  bool _isImage(File f) =>
      ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'].contains(_ext(f));

  String _fileName(File f) => f.path.split('/').last;

  @override
  Widget build(BuildContext context) {
    return BlocListener<SaveImageBloc, SaveImageState>(
      listener: (context, state) {
        if (state is SaveImageSuccess) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ ${state.message}'),
              backgroundColor: const Color(0xFF4CAF50),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
        if (state is SaveImageFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF5F5F5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            24 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Header ────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Attach Files',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Order ${widget.order.orderNo}  ·  ${widget.order.partyName}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black45,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // order id / party id info chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '#${widget.order.id}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Picker buttons ────────────────────────────────────────
              Row(
                children: [
                  _PickerBtn(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    color: const Color(0xFF2196F3),
                    bg: const Color(0xFFE3F2FD),
                    onTap: _pickCamera,
                  ),
                  const SizedBox(width: 10),
                  _PickerBtn(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    color: const Color(0xFF9C27B0),
                    bg: const Color(0xFFF3E5F5),
                    onTap: _pickGallery,
                  ),
                  const SizedBox(width: 10),
                  _PickerBtn(
                    icon: Icons.attach_file_rounded,
                    label: 'Files',
                    color: const Color(0xFF4CAF50),
                    bg: const Color(0xFFE8F5E9),
                    onTap: _pickFiles,
                  ),
                ],
              ),

              // ── File list ─────────────────────────────────────────────
              if (_files.isNotEmpty) ...[
                const SizedBox(height: 16),

                // image thumbnails
                if (_files.any(_isImage))
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _files.length,
                      itemBuilder: (_, i) {
                        final f = _files[i];
                        if (!_isImage(f)) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  f,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeFile(i),
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                // non-image file rows
                ..._files
                    .asMap()
                    .entries
                    .where((e) => !_isImage(e.value))
                    .map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFEEEEEE)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE3F2FD),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    _ext(entry.value).toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF2196F3),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _fileName(entry.value),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _removeFile(entry.key),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
              ],

              const SizedBox(height: 20),

              // ── Upload button ─────────────────────────────────────────
              BlocBuilder<SaveImageBloc, SaveImageState>(
                builder: (context, state) {
                  final isUploading = state is SaveImageUploading;
                  return GestureDetector(
                    onTap: (_files.isEmpty || isUploading) ? null : _upload,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: (_files.isEmpty || isUploading)
                            ? Colors.black26
                            : Colors.black,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: (_files.isEmpty || isUploading)
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
                          if (isUploading) ...[
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
                              'Uploading…',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ] else ...[
                            const Icon(
                              Icons.cloud_upload_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _files.isEmpty
                                  ? 'Select files to upload'
                                  : 'Upload ${_files.length} file${_files.length == 1 ? '' : 's'}',
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
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Picker Button ────────────────────────────────────────────────────────────

class _PickerBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _PickerBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
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
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
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
