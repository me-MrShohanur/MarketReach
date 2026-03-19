import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marketing/bloc/customer/customer_provider.dart';
import 'package:marketing/services/models/products_model.dart';
import 'package:marketing/services/provider/current_user.dart';
import 'package:marketing/views/home/subpages/product_list_view.dart';
import 'package:marketing/views/home/subpages/select_customer.dart';

class CreateOrderView extends StatefulWidget {
  const CreateOrderView({super.key});

  @override
  State<CreateOrderView> createState() => _CreateOrderViewState();
}

class _CreateOrderViewState extends State<CreateOrderView> {
  final List<ProductModel> _cart = [];
  double discount = 0;
  double tax = 0;
  String orderStatus = 'Pending';

  static const _orderStatuses = [
    'Pending',
    'Processing',
    'Completed',
    'Cancelled',
  ];

  double get _subtotal => _cart.fold(0, (s, p) => s + (p.salePrice ?? 0));
  double get _total => _subtotal - discount + tax;

  void _openSheet() => AddProductsSheet.show(
    context,
    categoryId: 1,
    onProductAdded: (p) => setState(() => _cart.add(p)),
  );

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: SafeArea(
          child: Column(
            children: [
              _Header(),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    children: [
                      BlocProvider(
                        create: (_) => CustomerBloc()..add(LoadCustomers()),
                        child: const CustomerDropdownCard(),
                      ),
                      const SizedBox(height: 12),
                      _cart.isEmpty
                          ? _EmptyCart(onAdd: _openSheet)
                          : _CartList(
                              items: _cart,
                              onRemove: (i) =>
                                  setState(() => _cart.removeAt(i)),
                              onAddMore: _openSheet,
                            ),
                      const SizedBox(height: 12),
                      _SummaryCard(
                        subtotal: _subtotal,
                        discount: discount,
                        tax: tax,
                        total: _total,
                        onDiscountChanged: (v) => setState(() => discount = v),
                        onTaxChanged: (v) => setState(() => tax = v),
                      ),
                      const SizedBox(height: 12),
                      _StatusDropdown(
                        label: 'Order Status',
                        value: orderStatus,
                        items: _orderStatuses,
                        accent: const Color(0xFFFFC107),
                        onChanged: (v) => setState(() => orderStatus = v!),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              _BottomButton(
                label: 'Create Order',
                icon: Icons.check_rounded,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _IconBtn(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.maybePop(context),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New Transaction',
                    style: TextStyle(fontSize: 13, color: Colors.black45),
                  ),
                  Text(
                    'Create Order',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          _BlackBox(
            child: Container(
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
        ],
      ),
    );
  }
}

// ─── Empty Cart ───────────────────────────────────────────────────────────────

class _EmptyCart extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyCart({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Column(
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 10),
            const Text(
              'Cart is empty',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Add products to create an order',
              style: TextStyle(fontSize: 13, color: Colors.black45),
            ),
            const SizedBox(height: 20),
            _BlackBox(
              radius: 12,
              onTap: onAdd,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Add Products',
                      style: TextStyle(
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
      ),
    );
  }
}

// ─── Cart List ────────────────────────────────────────────────────────────────

class _CartList extends StatelessWidget {
  final List<ProductModel> items;
  final ValueChanged<int> onRemove;
  final VoidCallback onAddMore;

  const _CartList({
    required this.items,
    required this.onRemove,
    required this.onAddMore,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.shopping_cart_outlined,
                      size: 18,
                      color: Colors.black45,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${items.length} item${items.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                _BlackBox(
                  radius: 9,
                  onTap: onAddMore,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    child: Row(
                      children: [
                        Icon(Icons.add_rounded, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Add More',
                          style: TextStyle(
                            fontSize: 12,
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
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: Color(0xFFF5F5F5)),
            itemBuilder: (_, i) =>
                _CartTile(product: items[i], onRemove: () => onRemove(i)),
          ),
        ],
      ),
    );
  }
}

class _CartTile extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onRemove;

  const _CartTile({required this.product, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: Colors.black26,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  product.salePrice != null
                      ? '৳${product.salePrice!.toStringAsFixed(2)}'
                      : 'Price N/A',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: product.salePrice != null
                        ? const Color(0xFF4CAF50)
                        : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.redAccent,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Summary Card ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final double subtotal, discount, tax, total;
  final ValueChanged<double> onDiscountChanged, onTaxChanged;

  const _SummaryCard({
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.onDiscountChanged,
    required this.onTaxChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      accent: const Color(0xFF4CAF50),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black45,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 12),
            _Row(label: 'Subtotal', value: '৳${subtotal.toStringAsFixed(2)}'),
            const SizedBox(height: 12),
            _EditableRow(
              label: 'Discount',
              value: discount,
              onChanged: onDiscountChanged,
            ),
            const SizedBox(height: 12),
            _EditableRow(label: 'Tax', value: tax, onChanged: onTaxChanged),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: Color(0xFFF0F0F0)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  '৳${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4CAF50),
                    letterSpacing: -0.5,
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

class _Row extends StatelessWidget {
  final String label, value;
  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(fontSize: 15, color: Colors.black45)),
      Text(
        value,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    ],
  );
}

class _EditableRow extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _EditableRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(fontSize: 15, color: Colors.black87)),
      _CurrencyInput(value: value, onChanged: onChanged),
    ],
  );
}

// ─── Currency Input ───────────────────────────────────────────────────────────

class _CurrencyInput extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  const _CurrencyInput({required this.value, required this.onChanged});

  @override
  State<_CurrencyInput> createState() => _CurrencyInputState();
}

class _CurrencyInputState extends State<_CurrencyInput> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.value == 0 ? '0' : widget.value.toString(),
    );
    log(CurrentUser.customerID.toString(), name: 'CurrentUser');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 32,
            child: Center(
              child: Text(
                '৳',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _ctrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              onChanged: (v) => widget.onChanged(double.tryParse(v) ?? 0),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Status Dropdown ──────────────────────────────────────────────────────────

class _StatusDropdown extends StatelessWidget {
  final String label, value;
  final List<String> items;
  final Color accent;
  final ValueChanged<String?> onChanged;

  const _StatusDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      accent: accent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black45,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 2),
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isDense: true,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: Colors.black45,
                ),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  letterSpacing: -0.2,
                ),
                items: items
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom Button ────────────────────────────────────────────────────────────

class _BottomButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _BottomButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      child: GestureDetector(
        onTap: onTap,
        child: _BlackBox(
          radius: 16,
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
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
      ),
    );
  }
}

// ─── Shared Primitives ────────────────────────────────────────────────────────

/// White card with optional left accent border and shadow
class _Card extends StatelessWidget {
  final Widget child;
  final Color? accent;

  const _Card({required this.child, this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: accent != null
            ? Border(left: BorderSide(color: accent!, width: 3))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Black rounded container — used for buttons/badges
class _BlackBox extends StatelessWidget {
  final Widget child;
  final double radius;
  final VoidCallback? onTap;

  const _BlackBox({required this.child, this.radius = 12, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

/// Small icon button (back button style)
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, size: 16, color: Colors.black),
      ),
    );
  }
}
