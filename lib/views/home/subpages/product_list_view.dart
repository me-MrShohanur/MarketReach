import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marketing/bloc/product/products_provider.dart';
import 'package:marketing/services/models/products_model.dart';

// ─── Shared Primitives ────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  final Color? accent;
  final double radius;

  const _Card({required this.child, this.accent, this.radius = 14});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: accent != null
          ? Border(left: BorderSide(color: accent!, width: 3))
          : null,
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D000000),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );
}

class _BlackBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final double radius;
  final EdgeInsets padding;
  final bool enabled;

  const _BlackBtn({
    required this.label,
    required this.onTap,
    this.radius = 10,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      padding: padding,
      decoration: BoxDecoration(
        color: enabled ? Colors.black : Colors.black26,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: enabled
            ? const [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: -0.2,
        ),
      ),
    ),
  );
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const SizedBox(height: 12),
      Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(height: 16),
    ],
  );
}

class _SheetHeader extends StatelessWidget {
  final String subtitle;
  final String title;
  final Widget badge;

  const _SheetHeader({
    required this.subtitle,
    required this.title,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black45,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 2),
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
        badge,
      ],
    ),
  );
}

// ─── Add Products Sheet ───────────────────────────────────────────────────────

class AddProductsSheet extends StatelessWidget {
  final int categoryId;
  final ValueChanged<ProductModel> onProductAdded;

  const AddProductsSheet({
    super.key,
    required this.categoryId,
    required this.onProductAdded,
  });

  static void show(
    BuildContext context, {
    required int partyId,
    required int categoryId,
    required ValueChanged<ProductModel> onProductAdded,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider(
        create: (_) =>
            ProductBloc()
              ..add(FetchProducts(getPartyId: partyId, categoryId: categoryId)),
        child: AddProductsSheet(
          categoryId: categoryId,
          onProductAdded: onProductAdded,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
    child: DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      snap: true,
      snapSizes: const [0.5, 0.9],
      builder: (_, sc) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5F5),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: _SheetBody(scrollController: sc, onProductAdded: onProductAdded),
      ),
    ),
  );
}

// ─── Sheet Body ───────────────────────────────────────────────────────────────

class _SheetBody extends StatefulWidget {
  final ScrollController scrollController;
  final ValueChanged<ProductModel> onProductAdded;

  const _SheetBody({
    required this.scrollController,
    required this.onProductAdded,
  });

  @override
  State<_SheetBody> createState() => _SheetBodyState();
}

class _SheetBodyState extends State<_SheetBody> {
  final _searchNotifier = ValueNotifier<String>('');

  @override
  void dispose() {
    _searchNotifier.dispose();
    super.dispose();
  }

  List<ProductModel> _filtered(List<ProductModel> all, String query) =>
      query.isEmpty
      ? all
      : all
            .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
            .toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _DragHandle(),
        _SheetHeader(
          subtitle: 'Browse',
          title: 'Products',
          badge: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.qr_code_scanner_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _Card(
            child: TextField(
              onChanged: (v) => _searchNotifier.value = v,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'Search products...',
                hintStyle: const TextStyle(
                  color: Colors.black38,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Colors.black38,
                  size: 20,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: BlocBuilder<ProductBloc, ProductState>(
            buildWhen: (prev, curr) =>
                prev.runtimeType != curr.runtimeType ||
                (curr is ProductLoaded && prev is! ProductLoaded),
            builder: (context, state) {
              if (state is ProductInitial || state is ProductLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF2196F3),
                    strokeWidth: 2,
                  ),
                );
              }

              if (state is ProductError) {
                return _ErrorView(
                  message: state.message,
                  onRetry: () => context.read<ProductBloc>().add(
                    FetchProducts(getPartyId: 0, categoryId: 1),
                  ),
                );
              }

              if (state is ProductLoaded) {
                return ValueListenableBuilder<String>(
                  valueListenable: _searchNotifier,
                  builder: (context, query, child) {
                    final filtered = _filtered(state.products, query);
                    if (filtered.isEmpty) return const _EmptySearch();

                    return ListView.builder(
                      controller: widget.scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 4,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ProductTile(
                          product: filtered[i],
                          onProductAdded: widget.onProductAdded,
                        ),
                      ),
                    );
                  },
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }
}

// ─── Error / Empty Views ──────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.error_outline_rounded,
          size: 48,
          color: Colors.redAccent,
        ),
        const SizedBox(height: 10),
        const Text(
          'Failed to load products',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black45,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          style: const TextStyle(fontSize: 12, color: Colors.black26),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        _BlackBtn(label: 'Retry', onTap: onRetry),
      ],
    ),
  );
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade300),
        const SizedBox(height: 10),
        const Text(
          'No products found',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black45,
            letterSpacing: -0.2,
          ),
        ),
      ],
    ),
  );
}

// ─── Product Tile ─────────────────────────────────────────────────────────────

class _ProductTile extends StatelessWidget {
  final ProductModel product;
  final ValueChanged<ProductModel> onProductAdded;

  const _ProductTile({required this.product, required this.onProductAdded});

  @override
  Widget build(BuildContext context) {
    return _Card(
      accent: const Color(0xFF2196F3),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        product.salePrice != null
                            ? '৳${product.salePrice!.toStringAsFixed(2)}'
                            : 'Price N/A',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: product.salePrice != null
                              ? const Color(0xFF4CAF50)
                              : Colors.black38,
                        ),
                      ),
                      if (product.discountRate > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: Colors.black26,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${product.discountRate}% off',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.orangeAccent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => _AddProductDetailSheet.show(
                context,
                product: product,
                onSave: onProductAdded,
              ),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add Product Detail Sheet ─────────────────────────────────────────────────

class _AddProductDetailSheet extends StatefulWidget {
  final ProductModel product;
  final ValueChanged<ProductModel> onSave;

  const _AddProductDetailSheet({required this.product, required this.onSave});

  static void show(
    BuildContext context, {
    required ProductModel product,
    required ValueChanged<ProductModel> onSave,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddProductDetailSheet(product: product, onSave: onSave),
    );
  }

  @override
  State<_AddProductDetailSheet> createState() => _AddProductDetailSheetState();
}

class _AddProductDetailSheetState extends State<_AddProductDetailSheet> {
  final _qtyCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  final _rateFocus = FocusNode();
  final _discountFocus = FocusNode();
  final _notesFocus = FocusNode();

  double get _qty => double.tryParse(_qtyCtrl.text) ?? 0;
  double get _rate => double.tryParse(_rateCtrl.text) ?? 0;
  double get _disc => double.tryParse(_discountCtrl.text) ?? 0;
  double get _net => (_qty * _rate) - _disc;

  late final ValueNotifier<double> _netNotifier;
  late final ValueNotifier<bool> _saveEnabledNotifier;

  @override
  void initState() {
    super.initState();
    _qtyCtrl.text = widget.product.depoDiscount.toStringAsFixed(2);
    _rateCtrl.text = (widget.product.salePrice ?? 0).toStringAsFixed(2);
    _discountCtrl.text = widget.product.discountRate.toStringAsFixed(2);

    _netNotifier = ValueNotifier(_net);
    _saveEnabledNotifier = ValueNotifier(_qty > 0);

    for (final c in [_qtyCtrl, _rateCtrl, _discountCtrl]) {
      c.addListener(_onFieldChanged);
    }

    log(
      'depoDiscount: ${widget.product.depoDiscount} | '
      'salePrice: ${widget.product.salePrice} | '
      'discountRate: ${widget.product.discountRate}',
      name: 'DetailSheet.prefill',
    );
  }

  void _onFieldChanged() {
    _netNotifier.value = _net;
    _saveEnabledNotifier.value = _qty > 0;
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _rateCtrl.dispose();
    _discountCtrl.dispose();
    _notesCtrl.dispose();
    _rateFocus.dispose();
    _discountFocus.dispose();
    _notesFocus.dispose();
    _netNotifier.dispose();
    _saveEnabledNotifier.dispose();
    super.dispose();
  }

  void _onSaveTapped() {
    final cartProduct = widget.product.copyWithCart(
      cartQty: _qty,
      cartRate: _rate,
      cartDiscount: _disc,
      cartNetAmount: _net,
      cartNotes: _notesCtrl.text.trim(),
    );

    log(
      'Saving to cart — product: ${cartProduct.name} | '
      'qty: ${cartProduct.cartQty} | rate: ${cartProduct.cartRate} | '
      'net: ${cartProduct.cartNetAmount}',
      name: 'DetailSheet.save',
    );

    // Step 1: add product to cart first
    widget.onSave(cartProduct);

    // Step 2: close both sheets at once safely.
    // popUntil pops routes until it finds a PageRoute (a real screen).
    // Bottom sheets are ModalBottomSheetRoute — NOT PageRoute.
    // So this pops: _AddProductDetailSheet + AddProductsSheet
    // and stops at CreateOrderView. Works whether search was active or not.
    Navigator.of(context).popUntil((route) => route is PageRoute);
  }

  @override
  Widget build(BuildContext context) {
    final hasDescription =
        widget.product.description != null &&
        widget.product.description!.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        snap: true,
        snapSizes: const [0.88],
        builder: (_, sc) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF5F5F5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _DragHandle(),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configure',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black45,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.product.name,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        color: Colors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (widget.product.salePrice != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '৳${widget.product.salePrice!.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (widget.product.discountRate > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${widget.product.discountRate.toStringAsFixed(0)}% off',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFE65100),
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (hasDescription) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEEEEEE)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 15,
                              color: Colors.black38,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.product.description!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: ListView(
                  controller: sc,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    _row(
                      _field(
                        _qtyCtrl,
                        'Quantity',
                        '0',
                        keyboard: TextInputType.number,
                        inputAction: TextInputAction.next,
                        onSubmitted: (_) => _rateFocus.requestFocus(),
                      ),
                      _field(
                        _rateCtrl,
                        'Rate',
                        '0.00',
                        keyboard: TextInputType.number,
                        focusNode: _rateFocus,
                        inputAction: TextInputAction.next,
                        onSubmitted: (_) => _discountFocus.requestFocus(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _row(
                      _field(
                        _discountCtrl,
                        'Discount',
                        '0.00',
                        keyboard: TextInputType.number,
                        focusNode: _discountFocus,
                        inputAction: TextInputAction.next,
                        onSubmitted: (_) => _notesFocus.requestFocus(),
                      ),
                      _netBox(),
                    ),
                    const SizedBox(height: 12),
                    _notesRow(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(Widget l, Widget r) => Row(
    children: [
      Expanded(child: l),
      const SizedBox(width: 12),
      Expanded(child: r),
    ],
  );

  Widget _field(
    TextEditingController ctrl,
    String label,
    String hint, {
    TextInputType keyboard = TextInputType.text,
    FocusNode? focusNode,
    TextInputAction? inputAction,
    void Function(String)? onSubmitted,
  }) => _Card(
    child: TextField(
      controller: ctrl,
      keyboardType: keyboard,
      focusNode: focusNode,
      textInputAction: inputAction,
      onSubmitted: onSubmitted,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 12,
          color: Colors.black45,
          fontWeight: FontWeight.w500,
        ),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black26),
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
  );

  Widget _netBox() => _Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Net Amount',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          ValueListenableBuilder<double>(
            valueListenable: _netNotifier,
            builder: (context, net, child) => Text(
              '৳${net.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4CAF50),
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _notesRow() => _Card(
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: _notesCtrl,
            focusNode: _notesFocus,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (_saveEnabledNotifier.value) _onSaveTapped();
            },
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              labelText: 'Notes',
              labelStyle: const TextStyle(
                fontSize: 12,
                color: Colors.black45,
                fontWeight: FontWeight.w500,
              ),
              hintText: 'Add a note...',
              hintStyle: const TextStyle(color: Colors.black26),
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
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ValueListenableBuilder<bool>(
            valueListenable: _saveEnabledNotifier,
            builder: (context, enabled, child) => _BlackBtn(
              label: 'Save',
              enabled: enabled,
              onTap: _onSaveTapped,
            ),
          ),
        ),
      ],
    ),
  );
}
