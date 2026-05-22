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
      const SizedBox(height: 8),
      Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(height: 12),
    ],
  );
}

class _DescriptionBox extends StatelessWidget {
  final String text;
  final bool compact;

  const _DescriptionBox({required this.text, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 6 : 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E7),
        borderRadius: BorderRadius.circular(compact ? 8 : 10),
        border: Border.all(color: const Color(0xFFFFB74D), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 1),
            padding: EdgeInsets.all(compact ? 3 : 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB74D),
              borderRadius: BorderRadius.circular(compact ? 5 : 6),
            ),
            child: Icon(
              Icons.info_rounded,
              size: compact ? 10 : 12,
              color: Colors.white,
            ),
          ),
          SizedBox(width: compact ? 7 : 9),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: compact ? 13 : 15,
                color: const Color(0xFF6D4C28),
                height: 1.3,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.05,
              ),
              maxLines: compact ? 2 : 3,
              overflow: TextOverflow.ellipsis,
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
      useRootNavigator: true,
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
      initialChildSize: 0.97,
      minChildSize: 0.6,
      maxChildSize: 0.97,
      expand: false,
      snap: true,
      snapSizes: const [0.6, 0.97],
      builder: (_, sc) => SafeArea(
        bottom: false,
        // top: false,
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
    Navigator.of(context, rootNavigator: true).pop();
  }

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

    return Stack(
      children: [
        Column(
          children: [
            const _DragHandle(),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Browse',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black45,
                          letterSpacing: 0.2,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Products',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _toggleSearch,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: 40,
                          height: 40,
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
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: selectedCount > 0 ? _showSelectedPanel : null,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: selectedCount > 0
                                    ? const Color(0xFF4CAF50)
                                    : Colors.white,
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
                                Icons.shopping_cart_rounded,
                                color: selectedCount > 0
                                    ? Colors.white
                                    : Colors.black26,
                                size: 20,
                              ),
                            ),
                            if (selectedCount > 0)
                              Positioned(
                                top: -5,
                                right: -5,
                                child: Container(
                                  width: 18,
                                  height: 18,
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
                                        fontSize: 9,
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

            const SizedBox(height: 12),

            // Search bar
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: _searchActive
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
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
                              size: 18,
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
                                        size: 16,
                                      ),
                                    ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
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

            // Product list with rounded corners
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
                          padding: EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            70 + MediaQuery.of(context).padding.bottom + 16,
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

        // Bottom CTA
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
                    padding: EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      8 + MediaQuery.of(context).padding.bottom,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: _showSelectedPanel,
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFF4CAF50),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$selectedCount item${selectedCount == 1 ? '' : 's'}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF4CAF50),
                                    ),
                                  ),
                                  Text(
                                    '৳${totalNet.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.black45,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: _addToOrder,
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Add $selectedCount item${selectedCount == 1 ? '' : 's'}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
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
        ),
      ],
    );
  }
}

// ─── Selected Products Panel ───────────────────────────────────────────────────

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
        20,
        0,
        20,
        20 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _DragHandle(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selected',
                    style: TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                  Text(
                    '${products.length} Product${products.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 24,
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
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF4CAF50), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(fontSize: 9, color: Colors.black45),
                    ),
                    Text(
                      '৳${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: products.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final p = products[i];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: const Border(
                      left: BorderSide(color: Color(0xFF4CAF50), width: 3),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0D000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.black45,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${p.cartQty.toStringAsFixed(0)} × ৳${p.cartRate.toStringAsFixed(2)}'
                                '${p.cartDiscount > 0 ? '  •  ${p.cartDiscount.toStringAsFixed(0)}% off' : ''}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black45,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '৳${p.cartNetAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          children: [
                            GestureDetector(
                              onTap: () => onEdit(p),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE3F2FD),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.edit_rounded,
                                  size: 14,
                                  color: Color(0xFF2196F3),
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            GestureDetector(
                              onTap: () => onRemove(p.name),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF0F0),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 14,
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
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onConfirm,
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Add ${products.length} item${products.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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
          ),
        ),
      ],
    ),
  );
}

// ─── Product Tile with Rounded Corners ─────────────────────────────────────────

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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? const Color(0xFF4CAF50) : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _AddProductDetailSheet.show(
            context,
            product: selectedProduct ?? product,
            onSave: onProductConfigured,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selection indicator with rounded corners
                    // AnimatedContainer(
                    //   duration: const Duration(milliseconds: 200),
                    //   width: 22,
                    //   height: 22,
                    //   margin: const EdgeInsets.only(top: 2, right: 12),
                    //   decoration: BoxDecoration(
                    //     borderRadius: BorderRadius.circular(6),
                    //     color: isSelected
                    //         ? const Color(0xFF4CAF50)
                    //         : Colors.transparent,
                    //     border: Border.all(
                    //       color: isSelected
                    //           ? const Color(0xFF4CAF50)
                    //           : Colors.grey.shade300,
                    //       width: 1.5,
                    //     ),
                    //   ),
                    //   child: isSelected
                    //       ? const Icon(
                    //           Icons.check_rounded,
                    //           size: 14,
                    //           color: Colors.white,
                    //         )
                    //       : null,
                    // ),

                    // Product info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 1,
                              //   vertical: ,
                            ),
                            child: Text(
                              product.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              if (product.salePrice != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    // vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '৳${product.salePrice!.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                ),
                              if (product.discountRate > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    // vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF3E0),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${product.discountRate.toStringAsFixed(0)}% off',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFE65100),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Action button with rounded corners
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF4CAF50)
                            : Colors.black,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isSelected ? Icons.edit_rounded : Icons.add_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),

                // Description with rounded corners
                if (hasDescription) ...[
                  const SizedBox(height: 10),
                  _DescriptionBox(text: product.description!, compact: true),
                ],

                // Selected summary with rounded corners
                if (isSelected && selectedProduct != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1FBF4),
                      borderRadius: BorderRadius.circular(10),
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
                            '${selectedProduct!.cartQty.toStringAsFixed(0)} × ৳${selectedProduct!.cartRate.toStringAsFixed(2)} = ৳${selectedProduct!.cartNetAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: onRemove,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: Colors.redAccent,
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
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.85,
        expand: false,
        snap: true,
        snapSizes: const [0.85],
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
                      style: TextStyle(fontSize: 12, color: Colors.black45),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.product.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (widget.product.salePrice != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '৳${widget.product.salePrice!.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                        if (widget.product.discountRate > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${widget.product.discountRate.toStringAsFixed(0)}% off',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFE65100),
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (hasDescription) ...[
                      const SizedBox(height: 10),
                      _DescriptionBox(
                        text: widget.product.description!,
                        compact: true,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
                    const SizedBox(height: 10),
                    _row(_discountBox(), _netBox()),
                    const SizedBox(height: 10),
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
      const SizedBox(width: 10),
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
    radius: 12,
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
          fontSize: 11,
          color: Colors.black45,
          fontWeight: FontWeight.w500,
        ),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black26),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: readOnly ? const Color(0xFFF5F5F5) : Colors.white,
      ),
    ),
  );

  Widget _discountBox() => _Card(
    radius: 12,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Discount',
            style: TextStyle(
              fontSize: 11,
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
          const SizedBox(height: 4),
          ValueListenableBuilder<double>(
            valueListenable: _discountAmtNotifier,
            builder: (_, amt, _) {
              if (amt <= 0) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
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
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE65100),
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
    radius: 12,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Net Amount',
            style: TextStyle(
              fontSize: 11,
              color: Colors.black45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          ValueListenableBuilder<double>(
            valueListenable: _netNotifier,
            builder: (_, net, _) => Text(
              '৳${net.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4CAF50),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _notesRow() => _Card(
    radius: 12,
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
                fontSize: 11,
                color: Colors.black45,
                fontWeight: FontWeight.w500,
              ),
              hintText: 'Add a note...',
              hintStyle: const TextStyle(color: Colors.black26),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
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
              radius: 10,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ),
      ],
    ),
  );
}
