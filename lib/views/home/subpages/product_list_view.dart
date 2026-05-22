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
      border: accent != null ? Border.all(color: accent!, width: 1.5) : null,
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

class _DescriptionBox extends StatelessWidget {
  final String text;
  const _DescriptionBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFB74D), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 1),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB74D),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.info_rounded,
              size: 12,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF6D4C28),
                height: 1.5,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.05,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Add Products Sheet (entry point) ────────────────────────────────────────

class AddProductsSheet extends StatelessWidget {
  final int categoryId;
  final int partyId;
  final ValueChanged<List<ProductModel>> onProductsAdded;

  const AddProductsSheet({
    super.key,
    required this.categoryId,
    required this.partyId,
    required this.onProductsAdded,
  });

  static void show(
    BuildContext context, {
    required int partyId,
    required int categoryId,
    required ValueChanged<List<ProductModel>> onProductsAdded,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // useRootNavigator: true — sheet covers ALL routes including CreateOrderView header.
      useRootNavigator: true,
      // useSafeArea: false — we manage top insets via SafeArea inside the sheet.
      useSafeArea: false,
      builder: (_) => BlocProvider(
        create: (_) =>
            ProductBloc()
              ..add(FetchProducts(getPartyId: partyId, categoryId: categoryId)),
        child: AddProductsSheet(
          categoryId: categoryId,
          partyId: partyId,
          onProductsAdded: onProductsAdded,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      snap: true,
      snapSizes: const [0.5, 0.92],
      builder: (_, sc) => SafeArea(
        bottom: false,
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF5F5F5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: _SheetBody(
            scrollController: sc,
            onProductsAdded: onProductsAdded,
          ),
        ),
      ),
    );
  }
}

// ─── Sheet Body ───────────────────────────────────────────────────────────────

class _SheetBody extends StatefulWidget {
  final ScrollController scrollController;
  final ValueChanged<List<ProductModel>> onProductsAdded;

  const _SheetBody({
    required this.scrollController,
    required this.onProductsAdded,
  });

  @override
  State<_SheetBody> createState() => _SheetBodyState();
}

class _SheetBodyState extends State<_SheetBody> {
  final _searchController = TextEditingController();
  final _searchNotifier = ValueNotifier<String>('');
  final _searchFocus = FocusNode();
  bool _searchActive = false;

  /// productName → configured ProductModel
  final Map<String, ProductModel> _selectedProducts = {};

  @override
  void dispose() {
    _searchController.dispose();
    _searchNotifier.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<ProductModel> _filtered(List<ProductModel> all, String query) =>
      query.isEmpty
      ? all
      : all
            .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
            .toList();

  void _onProductConfigured(ProductModel configured) {
    setState(() => _selectedProducts[configured.name] = configured);
    log(
      'Configured: ${configured.name} | qty=${configured.cartQty} '
      '| disc%=${configured.cartDiscount} | discAmt=${configured.cartDiscountAmt} '
      '| net=${configured.cartNetAmount}',
      name: 'MultiSelect',
    );
  }

  void _removeSelected(String name) =>
      setState(() => _selectedProducts.remove(name));

  void _addToOrder() {
    if (_selectedProducts.isEmpty) return;
    widget.onProductsAdded(_selectedProducts.values.toList());
    // rootNavigator: true matches the navigator used to push this sheet
    Navigator.of(context, rootNavigator: true).pop();
  }

  // ── Toggle search bar ─────────────────────────────────────────────────────
  void _toggleSearch() {
    setState(() {
      _searchActive = !_searchActive;
      if (_searchActive) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _searchFocus.requestFocus(),
        );
      } else {
        _searchController.clear();
        _searchNotifier.value = '';
        _searchFocus.unfocus();
      }
    });
  }

  // ── Show selected products panel ──────────────────────────────────────────
  void _showSelectedPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SelectedProductsPanel(
        products: _selectedProducts.values.toList(),
        onEdit: (product) {
          Navigator.pop(context);
          _AddProductDetailSheet.show(
            context,
            product: product,
            onSave: _onProductConfigured,
          );
        },
        onRemove: (name) {
          _removeSelected(name);
          Navigator.pop(context);
          if (_selectedProducts.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _showSelectedPanel(),
            );
          }
        },
        onConfirm: () {
          Navigator.pop(context);
          _addToOrder();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selectedProducts.length;
    final double totalNet = _selectedProducts.values.fold(
      0.0,
      (s, p) => s + p.cartNetAmount,
    );

    // ── KEY FIX ──────────────────────────────────────────────────────────────
    // The bottom CTA bar is placed as a direct sibling of the scrollable list
    // inside a Stack.  It is pinned to the bottom of the sheet and adds only
    // the system bottom padding (safe area) — NOT the keyboard inset.
    // This means it never moves when the keyboard opens or closes.
    return Stack(
      children: [
        // ── Main scrollable column ──────────────────────────────────────────
        Column(
          children: [
            const _DragHandle(),

            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Products',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black45,
                          letterSpacing: 0.2,
                        ),
                      ),
                      SizedBox(height: 2),
                    ],
                  ),
                  Row(
                    children: [
                      // ── Search toggle ────────────────────────────────────
                      GestureDetector(
                        onTap: _toggleSearch,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _searchActive ? Colors.black : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0F000000),
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            _searchActive
                                ? Icons.close_rounded
                                : Icons.search_rounded,
                            color: _searchActive
                                ? Colors.white
                                : Colors.black54,
                            size: 22,
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // ── Cart button with badge ───────────────────────────
                      GestureDetector(
                        onTap: selectedCount > 0 ? _showSelectedPanel : null,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: selectedCount > 0
                                    ? const Color(0xFF4CAF50)
                                    : const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: selectedCount > 0
                                    ? const [
                                        BoxShadow(
                                          color: Color(0x264CAF50),
                                          blurRadius: 10,
                                          offset: Offset(0, 4),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Icon(
                                Icons.shopping_cart_rounded,
                                color: selectedCount > 0
                                    ? Colors.white
                                    : Colors.black26,
                                size: 22,
                              ),
                            ),
                            if (selectedCount > 0)
                              Positioned(
                                top: -6,
                                right: -6,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    color: Colors.black,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      selectedCount > 9
                                          ? '9+'
                                          : '$selectedCount',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Search bar — slides in/out ───────────────────────────────────
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: _searchActive
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                      child: _Card(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocus,
                          onChanged: (v) => _searchNotifier.value = v,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
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
                            suffixIcon: ValueListenableBuilder<String>(
                              valueListenable: _searchNotifier,
                              builder: (_, q, _) => q.isEmpty
                                  ? const SizedBox.shrink()
                                  : GestureDetector(
                                      onTap: () {
                                        _searchController.clear();
                                        _searchNotifier.value = '';
                                      },
                                      child: const Icon(
                                        Icons.close_rounded,
                                        color: Colors.black26,
                                        size: 18,
                                      ),
                                    ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
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
                    )
                  : const SizedBox.shrink(),
            ),

            // ── Product list ─────────────────────────────────────────────────
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
                      builder: (context, query, _) {
                        final filtered = _filtered(state.products, query);
                        if (filtered.isEmpty) return const _EmptySearch();

                        return ListView.builder(
                          controller: widget.scrollController,
                          // ── KEY FIX ──────────────────────────────────────
                          // Bottom padding = CTA bar height (76) + safe area.
                          // This ensures the last list item is never hidden
                          // behind the pinned CTA bar.
                          padding: EdgeInsets.fromLTRB(
                            24,
                            0,
                            24,
                            76 +
                                MediaQuery.of(context).padding.bottom +
                                16, // extra breathing room
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, i) {
                            final product = filtered[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _ProductTile(
                                product: product,
                                isSelected: _selectedProducts.containsKey(
                                  product.name,
                                ),
                                selectedProduct:
                                    _selectedProducts[product.name],
                                onProductConfigured: _onProductConfigured,
                                onRemove: () => _removeSelected(product.name),
                              ),
                            );
                          },
                        );
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),

        // ── Bottom CTA — pinned, never moves with keyboard ──────────────────
        // Placed in a Stack so it overlays the list but stays fixed at the
        // bottom of the sheet container regardless of keyboard state.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: selectedCount == 0
                ? const SizedBox.shrink()
                : Container(
                    // Use only the safe-area bottom inset (notch / home bar),
                    // NOT viewInsets.bottom (keyboard).  This keeps the bar
                    // anchored at the very bottom of the sheet at all times.
                    padding: EdgeInsets.fromLTRB(
                      24,
                      12,
                      24,
                      12 + MediaQuery.of(context).padding.bottom,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      // Subtle top shadow so the bar feels elevated over the list
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // ── View selected summary ──────────────────────────
                        GestureDetector(
                          onTap: _showSelectedPanel,
                          child: Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFF4CAF50),
                                width: 1.5,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x0D000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$selectedCount item${selectedCount == 1 ? '' : 's'}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF4CAF50),
                                  ),
                                ),
                                Text(
                                  '৳${totalNet.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.black45,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        // ── Add to Order ───────────────────────────────────
                        Expanded(
                          child: GestureDetector(
                            onTap: _addToOrder,
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: const [
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
                                  const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Add $selectedCount item${selectedCount == 1 ? '' : 's'} to Order',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      letterSpacing: -0.1,
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
        ),
      ],
    );
  }
}

// ─── Selected Products Panel (bottom sheet) ───────────────────────────────────

class _SelectedProductsPanel extends StatelessWidget {
  final List<ProductModel> products;
  final ValueChanged<ProductModel> onEdit;
  final ValueChanged<String> onRemove;
  final VoidCallback onConfirm;

  const _SelectedProductsPanel({
    required this.products,
    required this.onEdit,
    required this.onRemove,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final double total = products.fold(0.0, (s, p) => s + p.cartNetAmount);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _DragHandle(),

          // ── Panel header ─────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selected',
                    style: TextStyle(fontSize: 13, color: Colors.black45),
                  ),
                  Text(
                    '${products.length} Product${products.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              // Total badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF4CAF50), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.black45,
                        letterSpacing: 0.2,
                      ),
                    ),
                    Text(
                      '৳${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2E7D32),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Product cards ─────────────────────────────────────────────────
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: products.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final p = products[i];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: const Border(
                      left: BorderSide(color: Color(0xFF4CAF50), width: 3),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0D000000),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        // Index bubble
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.black45,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Product info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${p.cartQty.toStringAsFixed(0)} × ৳${p.cartRate.toStringAsFixed(2)}'
                                '${p.cartDiscount > 0 ? '  •  ${p.cartDiscount.toStringAsFixed(0)}% off' : ''}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black45,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 10),

                        // Net amount
                        Text(
                          '৳${p.cartNetAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4CAF50),
                            letterSpacing: -0.3,
                          ),
                        ),

                        const SizedBox(width: 10),

                        // Action buttons
                        Column(
                          children: [
                            // Edit
                            GestureDetector(
                              onTap: () => onEdit(p),
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE3F2FD),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.edit_rounded,
                                  size: 15,
                                  color: Color(0xFF2196F3),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Remove
                            GestureDetector(
                              onTap: () => onRemove(p.name),
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF0F0),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 15,
                                  color: Colors.redAccent,
                                ),
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

          const SizedBox(height: 16),

          // ── Confirm button ────────────────────────────────────────────────
          GestureDetector(
            onTap: onConfirm,
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
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
                  const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Add ${products.length} item${products.length == 1 ? '' : 's'} to Order',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.1,
                    ),
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
  final bool isSelected;
  final ProductModel? selectedProduct;
  final ValueChanged<ProductModel> onProductConfigured;
  final VoidCallback onRemove;

  const _ProductTile({
    required this.product,
    required this.isSelected,
    required this.selectedProduct,
    required this.onProductConfigured,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasDescription =
        product.description != null && product.description!.trim().isNotEmpty;
    final accentColor = isSelected
        ? const Color(0xFF4CAF50)
        : const Color(0xFF2196F3);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? const Color(0xFF4CAF50) : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left accent bar
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      accentColor.withOpacity(0.6),
                      accentColor,
                      accentColor.withOpacity(0.7),
                    ],
                  ),
                ),
              ),

              // Tile content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: isSelected
                                ? Container(
                                    key: const ValueKey('check'),
                                    width: 26,
                                    height: 26,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE8F5E9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      size: 15,
                                      color: Color(0xFF4CAF50),
                                    ),
                                  )
                                : const SizedBox(key: ValueKey('empty')),
                          ),
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
                          // Add / Edit button
                          GestureDetector(
                            onTap: () => _AddProductDetailSheet.show(
                              context,
                              product: selectedProduct ?? product,
                              onSave: onProductConfigured,
                            ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF4CAF50)
                                    : Colors.black,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isSelected
                                    ? Icons.edit_rounded
                                    : Icons.add_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (hasDescription) ...[
                        const SizedBox(height: 10),
                        _DescriptionBox(text: product.description!),
                      ],

                      // ── Compact selected summary ───────────────────────
                      if (isSelected && selectedProduct != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1FBF4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.shopping_cart_outlined,
                                size: 13,
                                color: Color(0xFF4CAF50),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${selectedProduct!.cartQty.toStringAsFixed(0)} qty'
                                  '  ×  ৳${selectedProduct!.cartRate.toStringAsFixed(2)}'
                                  '  =  ৳${selectedProduct!.cartNetAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2E7D32),
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: onRemove,
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 14,
                                  color: Colors.redAccent,
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
            ],
          ),
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
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _rateCtrl;
  late final TextEditingController _discountCtrl;
  final _notesCtrl = TextEditingController();
  final _qtyFocus = FocusNode();
  final _notesFocus = FocusNode();

  double get _qty => double.tryParse(_qtyCtrl.text) ?? 0;
  double get _rate => double.tryParse(_rateCtrl.text) ?? 0;
  double get _disc => double.tryParse(_discountCtrl.text) ?? 0;
  double get _discAmt => _qty * _rate * (_disc / 100);
  double get _net => (_qty * _rate) - _discAmt;

  late final ValueNotifier<double> _netNotifier;
  late final ValueNotifier<double> _discountAmtNotifier;
  late final ValueNotifier<bool> _saveEnabledNotifier;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _qtyCtrl = TextEditingController(
      text: p.cartQty > 0 ? p.cartQty.toStringAsFixed(0) : '',
    );
    _rateCtrl = TextEditingController(
      text: (p.cartRate > 0 ? p.cartRate : (p.salePrice ?? 0)).toStringAsFixed(
        2,
      ),
    );
    _discountCtrl = TextEditingController(
      text: (p.cartDiscount > 0 ? p.cartDiscount : p.discountRate)
          .toStringAsFixed(2),
    );
    if (p.cartNotes.isNotEmpty) _notesCtrl.text = p.cartNotes;

    _netNotifier = ValueNotifier(_net);
    _discountAmtNotifier = ValueNotifier(_discAmt);
    _saveEnabledNotifier = ValueNotifier(_qty > 0);

    _qtyCtrl.addListener(_onFieldChanged);
    _rateCtrl.addListener(_onFieldChanged);
    _discountCtrl.addListener(_onFieldChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _qtyFocus.requestFocus();
    });

    log(
      'DetailSheet — ${p.name} | qty=${p.cartQty} | price=${p.salePrice}',
      name: 'DetailSheet',
    );
  }

  void _onFieldChanged() {
    _netNotifier.value = _net;
    _discountAmtNotifier.value = _discAmt;
    _saveEnabledNotifier.value = _qty > 0;
  }

  @override
  void dispose() {
    _qtyCtrl.removeListener(_onFieldChanged);
    _rateCtrl.removeListener(_onFieldChanged);
    _discountCtrl.removeListener(_onFieldChanged);
    _qtyCtrl.dispose();
    _rateCtrl.dispose();
    _discountCtrl.dispose();
    _notesCtrl.dispose();
    _qtyFocus.dispose();
    _notesFocus.dispose();
    _netNotifier.dispose();
    _discountAmtNotifier.dispose();
    _saveEnabledNotifier.dispose();
    super.dispose();
  }

  void _onSaveTapped() {
    final cartProduct = widget.product.copyWithCart(
      cartQty: _qty,
      cartRate: _rate,
      cartDiscount: _disc,
      cartDiscountAmt: _discAmt,
      cartNetAmount: _net,
      cartNotes: _notesCtrl.text.trim(),
    );
    log(
      'Save — ${cartProduct.name} | qty=${cartProduct.cartQty} '
      '| disc%=${cartProduct.cartDiscount} | discAmt=${cartProduct.cartDiscountAmt} '
      '| net=${cartProduct.cartNetAmount}',
      name: 'DetailSheet.save',
    );
    widget.onSave(cartProduct);
    Navigator.of(context).pop();
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
                      style: TextStyle(fontSize: 13, color: Colors.black45),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.product.name,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
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
                      _DescriptionBox(text: widget.product.description!),
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
                        'Enter qty',
                        focusNode: _qtyFocus,
                        keyboard: TextInputType.number,
                        inputAction: TextInputAction.next,
                        onSubmitted: (_) => _notesFocus.requestFocus(),
                      ),
                      _field(
                        _rateCtrl,
                        'Rate',
                        '0.00',
                        keyboard: TextInputType.number,
                        readOnly: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _row(_discountBox(), _netBox()),
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
    bool readOnly = false,
  }) => _Card(
    child: TextField(
      controller: ctrl,
      keyboardType: keyboard,
      focusNode: focusNode,
      textInputAction: inputAction,
      onSubmitted: onSubmitted,
      readOnly: readOnly,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: readOnly ? Colors.black38 : Colors.black,
      ),
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
        fillColor: readOnly ? const Color(0xFFF5F5F5) : Colors.white,
      ),
    ),
  );

  Widget _discountBox() => _Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Discount',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_discountCtrl.text.isEmpty ? '0.00' : _discountCtrl.text}%',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black38,
            ),
          ),
          const SizedBox(height: 6),
          ValueListenableBuilder<double>(
            valueListenable: _discountAmtNotifier,
            builder: (_, amt, _) {
              if (amt <= 0) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFFFFCC80),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  '৳${amt.toStringAsFixed(2)} off',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE65100),
                    letterSpacing: -0.1,
                  ),
                ),
              );
            },
          ),
        ],
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
            builder: (_, net, _) => Text(
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
            builder: (_, enabled, _) => _BlackBtn(
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
// import 'dart:developer';

// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:marketing/bloc/product/products_provider.dart';
// import 'package:marketing/services/models/products_model.dart';

// // ─── Shared Primitives ────────────────────────────────────────────────────────

// class _Card extends StatelessWidget {
//   final Widget child;
//   final Color? accent;
//   final double radius;

//   const _Card({required this.child, this.accent, this.radius = 14});

//   @override
//   Widget build(BuildContext context) => Container(
//     decoration: BoxDecoration(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(radius),
//       border: accent != null ? Border.all(color: accent!, width: 1.5) : null,
//       boxShadow: const [
//         BoxShadow(
//           color: Color(0x0D000000),
//           blurRadius: 10,
//           offset: Offset(0, 4),
//         ),
//       ],
//     ),
//     child: child,
//   );
// }

// class _BlackBtn extends StatelessWidget {
//   final String label;
//   final VoidCallback onTap;
//   final double radius;
//   final EdgeInsets padding;
//   final bool enabled;

//   const _BlackBtn({
//     required this.label,
//     required this.onTap,
//     this.radius = 10,
//     this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//     this.enabled = true,
//   });

//   @override
//   Widget build(BuildContext context) => GestureDetector(
//     onTap: enabled ? onTap : null,
//     child: AnimatedContainer(
//       duration: const Duration(milliseconds: 250),
//       curve: Curves.easeInOut,
//       padding: padding,
//       decoration: BoxDecoration(
//         color: enabled ? Colors.black : Colors.black26,
//         borderRadius: BorderRadius.circular(radius),
//         boxShadow: enabled
//             ? const [
//                 BoxShadow(
//                   color: Color(0x26000000),
//                   blurRadius: 8,
//                   offset: Offset(0, 4),
//                 ),
//               ]
//             : [],
//       ),
//       child: Text(
//         label,
//         style: const TextStyle(
//           fontSize: 14,
//           fontWeight: FontWeight.w600,
//           color: Colors.white,
//           letterSpacing: -0.2,
//         ),
//       ),
//     ),
//   );
// }

// class _DragHandle extends StatelessWidget {
//   const _DragHandle();

//   @override
//   Widget build(BuildContext context) => Column(
//     children: [
//       const SizedBox(height: 12),
//       Container(
//         width: 36,
//         height: 4,
//         decoration: BoxDecoration(
//           color: Colors.black12,
//           borderRadius: BorderRadius.circular(2),
//         ),
//       ),
//       const SizedBox(height: 16),
//     ],
//   );
// }

// // ─── Shared Description Box ───────────────────────────────────────────────────

// class _DescriptionBox extends StatelessWidget {
//   final String text;

//   const _DescriptionBox({required this.text});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//       decoration: BoxDecoration(
//         color: const Color(0xFFFFF8E7),
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: const Color(0xFFFFB74D), width: 1.2),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             margin: const EdgeInsets.only(top: 1),
//             padding: const EdgeInsets.all(4),
//             decoration: BoxDecoration(
//               color: const Color(0xFFFFB74D),
//               borderRadius: BorderRadius.circular(6),
//             ),
//             child: const Icon(
//               Icons.info_rounded,
//               size: 12,
//               color: Colors.white,
//             ),
//           ),
//           const SizedBox(width: 9),
//           Expanded(
//             child: Text(
//               text,
//               style: const TextStyle(
//                 fontSize: 15,
//                 color: Color(0xFF6D4C28),
//                 height: 1.5,
//                 fontWeight: FontWeight.w500,
//                 letterSpacing: 0.05,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ─── Add Products Sheet (entry point) ────────────────────────────────────────

// class AddProductsSheet extends StatelessWidget {
//   final int categoryId;
//   final int partyId;
//   final ValueChanged<List<ProductModel>> onProductsAdded;

//   const AddProductsSheet({
//     super.key,
//     required this.categoryId,
//     required this.partyId,
//     required this.onProductsAdded,
//   });

//   static void show(
//     BuildContext context, {
//     required int partyId,
//     required int categoryId,
//     required ValueChanged<List<ProductModel>> onProductsAdded,
//   }) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (_) => BlocProvider(
//         create: (_) =>
//             ProductBloc()
//               ..add(FetchProducts(getPartyId: partyId, categoryId: categoryId)),
//         child: AddProductsSheet(
//           categoryId: categoryId,
//           partyId: partyId,
//           onProductsAdded: onProductsAdded,
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) => Padding(
//     padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
//     child: DraggableScrollableSheet(
//       initialChildSize: 0.9,
//       minChildSize: 0.4,
//       maxChildSize: 0.95,
//       expand: false,
//       snap: true,
//       snapSizes: const [0.5, 0.9],
//       builder: (_, sc) => Container(
//         decoration: const BoxDecoration(
//           color: Color(0xFFF5F5F5),
//           borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//         ),
//         child: _SheetBody(
//           scrollController: sc,
//           onProductsAdded: onProductsAdded,
//         ),
//       ),
//     ),
//   );
// }

// // ─── Sheet Body ───────────────────────────────────────────────────────────────

// class _SheetBody extends StatefulWidget {
//   final ScrollController scrollController;
//   final ValueChanged<List<ProductModel>> onProductsAdded;

//   const _SheetBody({
//     required this.scrollController,
//     required this.onProductsAdded,
//   });

//   @override
//   State<_SheetBody> createState() => _SheetBodyState();
// }

// class _SheetBodyState extends State<_SheetBody> {
//   final _searchNotifier = ValueNotifier<String>('');

//   /// productName → configured ProductModel (preserves selection across searches)
//   final Map<String, ProductModel> _selectedProducts = {};

//   @override
//   void dispose() {
//     _searchNotifier.dispose();
//     super.dispose();
//   }

//   List<ProductModel> _filtered(List<ProductModel> all, String query) =>
//       query.isEmpty
//       ? all
//       : all
//             .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
//             .toList();

//   void _onProductConfigured(ProductModel configured) {
//     setState(() {
//       _selectedProducts[configured.name] = configured;
//     });
//     log(
//       'Configured: ${configured.name} | qty=${configured.cartQty} '
//       '| disc%=${configured.cartDiscount} | discAmt=${configured.cartDiscountAmt} '
//       '| net=${configured.cartNetAmount}',
//       name: 'MultiSelect',
//     );
//   }

//   void _removeSelected(String productName) {
//     setState(() => _selectedProducts.remove(productName));
//   }

//   void _addToOrder() {
//     if (_selectedProducts.isEmpty) return;
//     widget.onProductsAdded(_selectedProducts.values.toList());
//     Navigator.of(context).popUntil((route) => route is PageRoute);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final selectedCount = _selectedProducts.length;

//     return Column(
//       children: [
//         const _DragHandle(),

//         // ── Header ──────────────────────────────────────────────────────────
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 24),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Browse',
//                     style: TextStyle(
//                       fontSize: 13,
//                       color: Colors.black45,
//                       letterSpacing: 0.2,
//                     ),
//                   ),
//                   SizedBox(height: 2),
//                 ],
//               ),
//               Container(
//                 width: 44,
//                 height: 44,
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(12),
//                   boxShadow: const [
//                     BoxShadow(
//                       color: Color(0x0F000000),
//                       blurRadius: 8,
//                       offset: Offset(0, 3),
//                     ),
//                   ],
//                 ),
//                 child: const Icon(
//                   Icons.search_rounded,
//                   color: Colors.black54,
//                   size: 22,
//                 ),
//               ),
//             ],
//           ),
//         ),

//         const SizedBox(height: 16),

//         // ── Search bar ──────────────────────────────────────────────────────
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 24),
//           child: _Card(
//             child: TextField(
//               onChanged: (v) => _searchNotifier.value = v,
//               style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
//               decoration: InputDecoration(
//                 hintText: 'Search products...',
//                 hintStyle: const TextStyle(
//                   color: Colors.black38,
//                   fontWeight: FontWeight.w400,
//                 ),
//                 prefixIcon: const Icon(
//                   Icons.search_rounded,
//                   color: Colors.black38,
//                   size: 20,
//                 ),
//                 contentPadding: const EdgeInsets.symmetric(vertical: 14),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(14),
//                   borderSide: BorderSide.none,
//                 ),
//                 filled: true,
//                 fillColor: Colors.white,
//               ),
//             ),
//           ),
//         ),

//         const SizedBox(height: 12),

//         // ── Selected products horizontal chip strip ──────────────────────────
//         AnimatedSize(
//           duration: const Duration(milliseconds: 280),
//           curve: Curves.easeInOut,
//           child: selectedCount == 0
//               ? const SizedBox.shrink()
//               : Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Padding(
//                       padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
//                       child: Row(
//                         children: [
//                           const Icon(
//                             Icons.check_circle_rounded,
//                             size: 14,
//                             color: Color(0xFF4CAF50),
//                           ),
//                           const SizedBox(width: 6),
//                           Text(
//                             '$selectedCount selected',
//                             style: const TextStyle(
//                               fontSize: 13,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.black54,
//                               letterSpacing: -0.1,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     SizedBox(
//                       height: 72,
//                       child: ListView.builder(
//                         scrollDirection: Axis.horizontal,
//                         padding: const EdgeInsets.symmetric(horizontal: 24),
//                         itemCount: _selectedProducts.length,
//                         itemBuilder: (_, i) {
//                           final product = _selectedProducts.values.elementAt(i);
//                           return _SelectedChip(
//                             product: product,
//                             onRemove: () => _removeSelected(product.name),
//                           );
//                         },
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                   ],
//                 ),
//         ),

//         // ── Product list ─────────────────────────────────────────────────────
//         Expanded(
//           child: BlocBuilder<ProductBloc, ProductState>(
//             buildWhen: (prev, curr) =>
//                 prev.runtimeType != curr.runtimeType ||
//                 (curr is ProductLoaded && prev is! ProductLoaded),
//             builder: (context, state) {
//               if (state is ProductInitial || state is ProductLoading) {
//                 return const Center(
//                   child: CircularProgressIndicator(
//                     color: Color(0xFF2196F3),
//                     strokeWidth: 2,
//                   ),
//                 );
//               }

//               if (state is ProductError) {
//                 return _ErrorView(
//                   message: state.message,
//                   onRetry: () => context.read<ProductBloc>().add(
//                     FetchProducts(getPartyId: 0, categoryId: 1),
//                   ),
//                 );
//               }

//               if (state is ProductLoaded) {
//                 return ValueListenableBuilder<String>(
//                   valueListenable: _searchNotifier,
//                   builder: (context, query, _) {
//                     final filtered = _filtered(state.products, query);
//                     if (filtered.isEmpty) return const _EmptySearch();

//                     return ListView.builder(
//                       controller: widget.scrollController,
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 24,
//                         vertical: 4,
//                       ),
//                       itemCount: filtered.length,
//                       itemBuilder: (context, i) {
//                         final product = filtered[i];
//                         return Padding(
//                           padding: const EdgeInsets.only(bottom: 10),
//                           child: _ProductTile(
//                             product: product,
//                             isSelected: _selectedProducts.containsKey(
//                               product.name,
//                             ),
//                             selectedProduct: _selectedProducts[product.name],
//                             onProductConfigured: _onProductConfigured,
//                             onRemove: () => _removeSelected(product.name),
//                           ),
//                         );
//                       },
//                     );
//                   },
//                 );
//               }

//               return const SizedBox.shrink();
//             },
//           ),
//         ),

//         // ── Bottom "Add to Order" CTA — only visible when items selected ─────
//         AnimatedSize(
//           duration: const Duration(milliseconds: 250),
//           curve: Curves.easeInOut,
//           child: selectedCount == 0
//               ? const SizedBox.shrink()
//               : Container(
//                   color: const Color(0xFFF5F5F5),
//                   padding: EdgeInsets.fromLTRB(
//                     24,
//                     12,
//                     24,
//                     12 + MediaQuery.of(context).padding.bottom,
//                   ),
//                   child: GestureDetector(
//                     onTap: _addToOrder,
//                     child: Container(
//                       width: double.infinity,
//                       height: 52,
//                       decoration: BoxDecoration(
//                         color: Colors.black,
//                         borderRadius: BorderRadius.circular(16),
//                         boxShadow: const [
//                           BoxShadow(
//                             color: Color(0x26000000),
//                             blurRadius: 12,
//                             offset: Offset(0, 6),
//                           ),
//                         ],
//                       ),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           const Icon(
//                             Icons.check_rounded,
//                             color: Colors.white,
//                             size: 20,
//                           ),
//                           const SizedBox(width: 8),
//                           Text(
//                             'Add $selectedCount item${selectedCount == 1 ? '' : 's'} to Order',
//                             style: const TextStyle(
//                               fontSize: 15,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.white,
//                               letterSpacing: -0.1,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//         ),
//       ],
//     );
//   }
// }

// // ─── Selected Chip (horizontal strip) ────────────────────────────────────────

// class _SelectedChip extends StatelessWidget {
//   final ProductModel product;
//   final VoidCallback onRemove;

//   const _SelectedChip({required this.product, required this.onRemove});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.only(right: 10),
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: const Color(0xFF4CAF50), width: 1.5),
//         boxShadow: const [
//           BoxShadow(
//             color: Color(0x0D000000),
//             blurRadius: 6,
//             offset: Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(
//                 product.name.length > 14
//                     ? '${product.name.substring(0, 14)}…'
//                     : product.name,
//                 style: const TextStyle(
//                   fontSize: 12,
//                   fontWeight: FontWeight.w600,
//                   letterSpacing: -0.1,
//                 ),
//               ),
//               const SizedBox(height: 2),
//               Text(
//                 '${product.cartQty.toStringAsFixed(0)} × ৳${product.cartRate.toStringAsFixed(2)}',
//                 style: const TextStyle(
//                   fontSize: 11,
//                   color: Color(0xFF4CAF50),
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(width: 8),
//           GestureDetector(
//             onTap: onRemove,
//             child: Container(
//               width: 18,
//               height: 18,
//               decoration: const BoxDecoration(
//                 color: Color(0xFFFFEBEE),
//                 shape: BoxShape.circle,
//               ),
//               child: const Icon(
//                 Icons.close_rounded,
//                 size: 11,
//                 color: Colors.redAccent,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ─── Error / Empty Views ──────────────────────────────────────────────────────

// class _ErrorView extends StatelessWidget {
//   final String message;
//   final VoidCallback onRetry;

//   const _ErrorView({required this.message, required this.onRetry});

//   @override
//   Widget build(BuildContext context) => Center(
//     child: Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         const Icon(
//           Icons.error_outline_rounded,
//           size: 48,
//           color: Colors.redAccent,
//         ),
//         const SizedBox(height: 10),
//         const Text(
//           'Failed to load products',
//           style: TextStyle(
//             fontSize: 15,
//             fontWeight: FontWeight.w600,
//             color: Colors.black45,
//           ),
//         ),
//         const SizedBox(height: 6),
//         Text(
//           message,
//           style: const TextStyle(fontSize: 12, color: Colors.black26),
//           textAlign: TextAlign.center,
//         ),
//         const SizedBox(height: 16),
//         _BlackBtn(label: 'Retry', onTap: onRetry),
//       ],
//     ),
//   );
// }

// class _EmptySearch extends StatelessWidget {
//   const _EmptySearch();

//   @override
//   Widget build(BuildContext context) => Center(
//     child: Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade300),
//         const SizedBox(height: 10),
//         const Text(
//           'No products found',
//           style: TextStyle(
//             fontSize: 15,
//             fontWeight: FontWeight.w600,
//             color: Colors.black45,
//             letterSpacing: -0.2,
//           ),
//         ),
//       ],
//     ),
//   );
// }

// // ─── Product Tile ─────────────────────────────────────────────────────────────

// class _ProductTile extends StatelessWidget {
//   final ProductModel product;
//   final bool isSelected;
//   final ProductModel? selectedProduct;
//   final ValueChanged<ProductModel> onProductConfigured;
//   final VoidCallback onRemove;

//   const _ProductTile({
//     required this.product,
//     required this.isSelected,
//     required this.selectedProduct,
//     required this.onProductConfigured,
//     required this.onRemove,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final hasDescription =
//         product.description != null && product.description!.trim().isNotEmpty;

//     final accentColor = isSelected
//         ? const Color(0xFF4CAF50)
//         : const Color(0xFF2196F3);

//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 220),
//       curve: Curves.easeInOut,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(
//           color: isSelected ? const Color(0xFF4CAF50) : Colors.transparent,
//           width: 1.5,
//         ),
//         boxShadow: const [
//           BoxShadow(
//             color: Color(0x0D000000),
//             blurRadius: 10,
//             offset: Offset(0, 4),
//           ),
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(14),
//         child: IntrinsicHeight(
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               // ── LEFT ACCENT BAR ─────────────────────────────────────────
//               AnimatedContainer(
//                 duration: const Duration(milliseconds: 220),
//                 width: 5,
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     begin: Alignment.topCenter,
//                     end: Alignment.bottomCenter,
//                     colors: [
//                       accentColor.withOpacity(0.6),
//                       accentColor,
//                       accentColor.withOpacity(0.7),
//                     ],
//                   ),
//                 ),
//               ),

//               // ── TILE CONTENT ────────────────────────────────────────────
//               Expanded(
//                 child: Padding(
//                   padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           AnimatedSwitcher(
//                             duration: const Duration(milliseconds: 200),
//                             child: isSelected
//                                 ? Container(
//                                     key: const ValueKey('check'),
//                                     width: 26,
//                                     height: 26,
//                                     margin: const EdgeInsets.only(right: 8),
//                                     decoration: const BoxDecoration(
//                                       color: Color(0xFFE8F5E9),
//                                       shape: BoxShape.circle,
//                                     ),
//                                     child: const Icon(
//                                       Icons.check_rounded,
//                                       size: 15,
//                                       color: Color(0xFF4CAF50),
//                                     ),
//                                   )
//                                 : const SizedBox(key: ValueKey('empty')),
//                           ),

//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.end,
//                               children: [
//                                 Text(
//                                   product.name,
//                                   style: const TextStyle(
//                                     fontSize: 15,
//                                     fontWeight: FontWeight.w600,
//                                     letterSpacing: -0.2,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 4),
//                                 Row(
//                                   children: [
//                                     Text(
//                                       product.salePrice != null
//                                           ? '৳${product.salePrice!.toStringAsFixed(2)}'
//                                           : 'Price N/A',
//                                       style: TextStyle(
//                                         fontSize: 13,
//                                         fontWeight: FontWeight.w600,
//                                         color: product.salePrice != null
//                                             ? const Color(0xFF4CAF50)
//                                             : Colors.black38,
//                                       ),
//                                     ),
//                                     if (product.discountRate > 0) ...[
//                                       const SizedBox(width: 6),
//                                       Container(
//                                         width: 3,
//                                         height: 3,
//                                         decoration: const BoxDecoration(
//                                           color: Colors.black26,
//                                           shape: BoxShape.circle,
//                                         ),
//                                       ),
//                                       const SizedBox(width: 6),
//                                       Text(
//                                         '${product.discountRate}% off',
//                                         style: const TextStyle(
//                                           fontSize: 13,
//                                           color: Colors.orangeAccent,
//                                           fontWeight: FontWeight.w500,
//                                         ),
//                                       ),
//                                     ],
//                                   ],
//                                 ),
//                               ],
//                             ),
//                           ),

//                           const SizedBox(width: 10),

//                           GestureDetector(
//                             onTap: () => _AddProductDetailSheet.show(
//                               context,
//                               product: selectedProduct ?? product,
//                               onSave: onProductConfigured,
//                             ),
//                             child: AnimatedContainer(
//                               duration: const Duration(milliseconds: 220),
//                               width: 36,
//                               height: 36,
//                               decoration: BoxDecoration(
//                                 color: isSelected
//                                     ? const Color(0xFF4CAF50)
//                                     : Colors.black,
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                               child: Icon(
//                                 isSelected
//                                     ? Icons.edit_rounded
//                                     : Icons.add_rounded,
//                                 color: Colors.white,
//                                 size: 18,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),

//                       if (hasDescription) ...[
//                         const SizedBox(height: 10),
//                         _DescriptionBox(text: product.description!),
//                       ],

//                       if (isSelected && selectedProduct != null) ...[
//                         const SizedBox(height: 8),
//                         Container(
//                           width: double.infinity,
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 10,
//                             vertical: 7,
//                           ),
//                           decoration: BoxDecoration(
//                             color: const Color(0xFFF1FBF4),
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           child: Row(
//                             children: [
//                               const Icon(
//                                 Icons.shopping_cart_outlined,
//                                 size: 13,
//                                 color: Color(0xFF4CAF50),
//                               ),
//                               const SizedBox(width: 6),
//                               Expanded(
//                                 child: Text(
//                                   '${selectedProduct!.cartQty.toStringAsFixed(0)} qty'
//                                   '  ×  ৳${selectedProduct!.cartRate.toStringAsFixed(2)}'
//                                   '  =  ৳${selectedProduct!.cartNetAmount.toStringAsFixed(2)}',
//                                   style: const TextStyle(
//                                     fontSize: 12,
//                                     fontWeight: FontWeight.w600,
//                                     color: Color(0xFF2E7D32),
//                                     letterSpacing: -0.1,
//                                   ),
//                                 ),
//                               ),
//                               GestureDetector(
//                                 onTap: onRemove,
//                                 child: const Icon(
//                                   Icons.close_rounded,
//                                   size: 14,
//                                   color: Colors.redAccent,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ─── Add Product Detail Sheet ─────────────────────────────────────────────────

// class _AddProductDetailSheet extends StatefulWidget {
//   final ProductModel product;
//   final ValueChanged<ProductModel> onSave;

//   const _AddProductDetailSheet({required this.product, required this.onSave});

//   static void show(
//     BuildContext context, {
//     required ProductModel product,
//     required ValueChanged<ProductModel> onSave,
//   }) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (_) => _AddProductDetailSheet(product: product, onSave: onSave),
//     );
//   }

//   @override
//   State<_AddProductDetailSheet> createState() => _AddProductDetailSheetState();
// }

// class _AddProductDetailSheetState extends State<_AddProductDetailSheet> {
//   late final TextEditingController _qtyCtrl;
//   late final TextEditingController _rateCtrl;
//   late final TextEditingController _discountCtrl;
//   final _notesCtrl = TextEditingController();

//   final _qtyFocus = FocusNode();
//   final _notesFocus = FocusNode();

//   // ── Computed values ──────────────────────────────────────────────────────────
//   double get _qty => double.tryParse(_qtyCtrl.text) ?? 0;
//   double get _rate => double.tryParse(_rateCtrl.text) ?? 0;

//   // _disc holds the PERCENTAGE value (e.g. 15.0 means 15%)
//   double get _disc => double.tryParse(_discountCtrl.text) ?? 0;

//   // Actual discount amount in BDT = qty × rate × (disc% / 100)
//   double get _discAmt => _qty * _rate * (_disc / 100);

//   // Net = (qty × rate) − discount amount
//   double get _net => (_qty * _rate) - _discAmt;

//   // ── Notifiers ─────────────────────────────────────────────────────────────────
//   late final ValueNotifier<double> _netNotifier;
//   late final ValueNotifier<double>
//   _discountAmtNotifier; // ← NEW: live discount amount
//   late final ValueNotifier<bool> _saveEnabledNotifier;

//   @override
//   void initState() {
//     super.initState();

//     final p = widget.product;

//     _qtyCtrl = TextEditingController(
//       text: p.cartQty > 0 ? p.cartQty.toStringAsFixed(0) : '',
//     );
//     _rateCtrl = TextEditingController(
//       text: (p.cartRate > 0 ? p.cartRate : (p.salePrice ?? 0)).toStringAsFixed(
//         2,
//       ),
//     );
//     // Pre-fill discount % from cart or product default
//     _discountCtrl = TextEditingController(
//       text: (p.cartDiscount > 0 ? p.cartDiscount : p.discountRate)
//           .toStringAsFixed(2),
//     );
//     if (p.cartNotes.isNotEmpty) _notesCtrl.text = p.cartNotes;

//     _netNotifier = ValueNotifier(_net);
//     _discountAmtNotifier = ValueNotifier(_discAmt); // ← NEW
//     _saveEnabledNotifier = ValueNotifier(_qty > 0);

//     // Listen on qty, rate, and discount so all live values update together
//     _qtyCtrl.addListener(_onFieldChanged);
//     _rateCtrl.addListener(_onFieldChanged);
//     _discountCtrl.addListener(_onFieldChanged);

//     // Auto-focus qty field after sheet is fully rendered
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (mounted) _qtyFocus.requestFocus();
//     });

//     log(
//       'DetailSheet open — ${p.name} | cartQty=${p.cartQty} | salePrice=${p.salePrice}',
//       name: 'DetailSheet.prefill',
//     );
//   }

//   void _onFieldChanged() {
//     _netNotifier.value = _net;
//     _discountAmtNotifier.value = _discAmt; // ← NEW: update discount amount live
//     _saveEnabledNotifier.value = _qty > 0;
//   }

//   @override
//   void dispose() {
//     _qtyCtrl.removeListener(_onFieldChanged);
//     _rateCtrl.removeListener(_onFieldChanged);
//     _discountCtrl.removeListener(_onFieldChanged);
//     _qtyCtrl.dispose();
//     _rateCtrl.dispose();
//     _discountCtrl.dispose();
//     _notesCtrl.dispose();
//     _qtyFocus.dispose();
//     _notesFocus.dispose();
//     _netNotifier.dispose();
//     _discountAmtNotifier.dispose(); // ← NEW
//     _saveEnabledNotifier.dispose();
//     super.dispose();
//   }

//   void _onSaveTapped() {
//     final cartProduct = widget.product.copyWithCart(
//       cartQty: _qty,
//       cartRate: _rate,
//       cartDiscount: _disc, // ← the % value  → maps to "discount" in API body
//       cartDiscountAmt:
//           _discAmt, // ← the BDT amount → maps to "discountAmt" in API body
//       cartNetAmount: _net,
//       cartNotes: _notesCtrl.text.trim(),
//     );

//     log(
//       'Saving — ${cartProduct.name} '
//       '| qty=${cartProduct.cartQty} '
//       '| disc%=${cartProduct.cartDiscount} '
//       '| discAmt=${cartProduct.cartDiscountAmt} '
//       '| net=${cartProduct.cartNetAmount}',
//       name: 'DetailSheet.save',
//     );

//     widget.onSave(cartProduct);
//     Navigator.of(context).pop();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final hasDescription =
//         widget.product.description != null &&
//         widget.product.description!.trim().isNotEmpty;

//     return Padding(
//       padding: EdgeInsets.only(
//         bottom: MediaQuery.of(context).viewInsets.bottom,
//       ),
//       child: DraggableScrollableSheet(
//         initialChildSize: 0.88,
//         minChildSize: 0.5,
//         maxChildSize: 0.95,
//         expand: false,
//         snap: true,
//         snapSizes: const [0.88],
//         builder: (_, sc) => Container(
//           decoration: const BoxDecoration(
//             color: Color(0xFFF5F5F5),
//             borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const _DragHandle(),

//               // ── Product header ─────────────────────────────────────────────
//               Padding(
//                 padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Configure',
//                       style: TextStyle(
//                         fontSize: 13,
//                         color: Colors.black45,
//                         letterSpacing: 0.2,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       widget.product.name,
//                       style: const TextStyle(
//                         fontSize: 26,
//                         fontWeight: FontWeight.w700,
//                         letterSpacing: -0.5,
//                         color: Colors.black,
//                       ),
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     const SizedBox(height: 10),
//                     Row(
//                       children: [
//                         if (widget.product.salePrice != null) ...[
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 10,
//                               vertical: 5,
//                             ),
//                             decoration: BoxDecoration(
//                               color: const Color(0xFFE8F5E9),
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: Text(
//                               '৳${widget.product.salePrice!.toStringAsFixed(2)}',
//                               style: const TextStyle(
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.w700,
//                                 color: Color(0xFF2E7D32),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                         ],
//                         if (widget.product.discountRate > 0)
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 10,
//                               vertical: 5,
//                             ),
//                             decoration: BoxDecoration(
//                               color: const Color(0xFFFFF3E0),
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: Text(
//                               '${widget.product.discountRate.toStringAsFixed(0)}% off',
//                               style: const TextStyle(
//                                 fontSize: 13,
//                                 fontWeight: FontWeight.w600,
//                                 color: Color(0xFFE65100),
//                               ),
//                             ),
//                           ),
//                       ],
//                     ),
//                     if (hasDescription) ...[
//                       const SizedBox(height: 12),
//                       _DescriptionBox(text: widget.product.description!),
//                     ],
//                   ],
//                 ),
//               ),

//               const SizedBox(height: 20),

//               // ── Input fields ───────────────────────────────────────────────
//               Expanded(
//                 child: ListView(
//                   controller: sc,
//                   padding: const EdgeInsets.symmetric(horizontal: 24),
//                   children: [
//                     // Row 1: Quantity | Rate
//                     _row(
//                       _field(
//                         _qtyCtrl,
//                         'Quantity',
//                         'Enter qty',
//                         focusNode: _qtyFocus,
//                         keyboard: TextInputType.number,
//                         inputAction: TextInputAction.next,
//                         onSubmitted: (_) => _notesFocus.requestFocus(),
//                       ),
//                       _field(
//                         _rateCtrl,
//                         'Rate',
//                         '0.00',
//                         keyboard: TextInputType.number,
//                         readOnly: true,
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     // Row 2: Discount (% + live amount) | Net Amount
//                     _row(
//                       _discountBox(), // ← shows both % and BDT amount
//                       _netBox(),
//                     ),
//                     const SizedBox(height: 12),
//                     // Row 3: Notes + Save button
//                     _notesRow(),
//                     const SizedBox(height: 24),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _row(Widget l, Widget r) => Row(
//     children: [
//       Expanded(child: l),
//       const SizedBox(width: 12),
//       Expanded(child: r),
//     ],
//   );

//   Widget _field(
//     TextEditingController ctrl,
//     String label,
//     String hint, {
//     TextInputType keyboard = TextInputType.text,
//     FocusNode? focusNode,
//     TextInputAction? inputAction,
//     void Function(String)? onSubmitted,
//     bool readOnly = false,
//   }) => _Card(
//     child: TextField(
//       controller: ctrl,
//       keyboardType: keyboard,
//       focusNode: focusNode,
//       textInputAction: inputAction,
//       onSubmitted: onSubmitted,
//       readOnly: readOnly,
//       style: TextStyle(
//         fontSize: 14,
//         fontWeight: FontWeight.w500,
//         color: readOnly ? Colors.black38 : Colors.black,
//       ),
//       decoration: InputDecoration(
//         labelText: label,
//         labelStyle: const TextStyle(
//           fontSize: 12,
//           color: Colors.black45,
//           fontWeight: FontWeight.w500,
//         ),
//         hintText: hint,
//         hintStyle: const TextStyle(color: Colors.black26),
//         contentPadding: const EdgeInsets.symmetric(
//           horizontal: 14,
//           vertical: 14,
//         ),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: BorderSide.none,
//         ),
//         filled: true,
//         fillColor: readOnly ? const Color(0xFFF5F5F5) : Colors.white,
//       ),
//     ),
//   );

//   // ── Discount box ────────────────────────────────────────────────────────────
//   // Shows the discount % on top (read-only, same style as Rate/Net fields).
//   // Below it shows a live amber pill: "৳4,980.00 off" that updates as qty changes.
//   // ────────────────────────────────────────────────────────────────────────────
//   Widget _discountBox() => _Card(
//     child: Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // Label — matches other fields
//           const Text(
//             'Discount',
//             style: TextStyle(
//               fontSize: 12,
//               color: Colors.black45,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           const SizedBox(height: 4),
//           // Percentage value — read-only display
//           Text(
//             '${_discountCtrl.text.isEmpty ? '0.00' : _discountCtrl.text}%',
//             style: const TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.w500,
//               color: Colors.black38,
//             ),
//           ),
//           const SizedBox(height: 6),
//           // Live discount amount pill — only shown when > 0
//           ValueListenableBuilder<double>(
//             valueListenable: _discountAmtNotifier,
//             builder: (_, amt, _) {
//               if (amt <= 0) return const SizedBox.shrink();
//               return Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFFFF3E0),
//                   borderRadius: BorderRadius.circular(6),
//                   border: Border.all(
//                     color: const Color(0xFFFFCC80),
//                     width: 0.8,
//                   ),
//                 ),
//                 child: Text(
//                   '৳${amt.toStringAsFixed(2)} off',
//                   style: const TextStyle(
//                     fontSize: 11,
//                     fontWeight: FontWeight.w600,
//                     color: Color(0xFFE65100),
//                     letterSpacing: -0.1,
//                   ),
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//     ),
//   );

//   // ── Net amount box ──────────────────────────────────────────────────────────
//   Widget _netBox() => _Card(
//     child: Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Net Amount',
//             style: TextStyle(
//               fontSize: 12,
//               color: Colors.black45,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           const SizedBox(height: 6),
//           ValueListenableBuilder<double>(
//             valueListenable: _netNotifier,
//             builder: (_, net, _) => Text(
//               '৳${net.toStringAsFixed(2)}',
//               style: const TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w700,
//                 color: Color(0xFF4CAF50),
//                 letterSpacing: -0.3,
//               ),
//             ),
//           ),
//         ],
//       ),
//     ),
//   );

//   // ── Notes + Save row ────────────────────────────────────────────────────────
//   Widget _notesRow() => _Card(
//     child: Row(
//       children: [
//         Expanded(
//           child: TextField(
//             controller: _notesCtrl,
//             focusNode: _notesFocus,
//             textInputAction: TextInputAction.done,
//             onSubmitted: (_) {
//               if (_saveEnabledNotifier.value) _onSaveTapped();
//             },
//             style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
//             decoration: InputDecoration(
//               labelText: 'Notes',
//               labelStyle: const TextStyle(
//                 fontSize: 12,
//                 color: Colors.black45,
//                 fontWeight: FontWeight.w500,
//               ),
//               hintText: 'Add a note...',
//               hintStyle: const TextStyle(color: Colors.black26),
//               contentPadding: const EdgeInsets.symmetric(
//                 horizontal: 14,
//                 vertical: 14,
//               ),
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(14),
//                 borderSide: BorderSide.none,
//               ),
//               filled: true,
//               fillColor: Colors.white,
//             ),
//           ),
//         ),
//         Padding(
//           padding: const EdgeInsets.only(right: 8),
//           child: ValueListenableBuilder<bool>(
//             valueListenable: _saveEnabledNotifier,
//             builder: (_, enabled, _) => _BlackBtn(
//               label: 'Save',
//               enabled: enabled,
//               onTap: _onSaveTapped,
//             ),
//           ),
//         ),
//       ],
//     ),
//   );
// }
