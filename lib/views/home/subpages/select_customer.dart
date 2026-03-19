import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marketing/bloc/customer/customer_provider.dart';
import 'package:marketing/services/models/customer.dart';
import 'package:marketing/services/models/products_model.dart';

// ─── Customer Dropdown Card ───────────────────────────────────────────────────
// Drop-in replacement for the old _CustomerCard widget in CreateOrderView.
// Wrap your CreateOrderView (or a parent) with BlocProvider<CustomerBloc>.

class CustomerDropdownCard extends StatefulWidget {
  const CustomerDropdownCard({super.key});

  @override
  State<CustomerDropdownCard> createState() => _CustomerDropdownCardState();
}

class _CustomerDropdownCardState extends State<CustomerDropdownCard> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  // ── Overlay helpers ────────────────────────────────────────────────────────

  void _openDropdown(
    BuildContext context,
    List<CustomerModel> customers,
    CustomerModel? selected,
  ) {
    _closeDropdown();

    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (_) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _closeDropdown,
        child: Stack(
          children: [
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, size.height + 6),
              child: Material(
                color: Colors.transparent,
                child: _DropdownOverlay(
                  customers: customers,
                  selected: selected,
                  onSelect: (customer) {
                    context.read<CustomerBloc>().add(SelectCustomer(customer));
                    _closeDropdown();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _isOpen = false);
  }

  @override
  void dispose() {
    _closeDropdown();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerBloc, CustomerState>(
      builder: (context, state) {
        if (state is CustomerLoading) {
          return _buildShell(child: const _LoadingRow());
        }

        if (state is CustomerError) {
          return _buildShell(child: _ErrorRow(message: state.message));
        }

        if (state is CustomerLoaded) {
          return CompositedTransformTarget(
            link: _layerLink,
            child: GestureDetector(
              onTap: () => state.customers.isEmpty
                  ? null
                  : _isOpen
                  ? _closeDropdown()
                  : _openDropdown(
                      context,
                      state.customers,
                      state.selectedCustomer,
                    ),
              child: _buildShell(
                isOpen: _isOpen,
                child: _SelectedRow(
                  selected: state.selectedCustomer,
                  isOpen: _isOpen,
                ),
              ),
            ),
          );
        }

        // CustomerInitial — not yet triggered
        return _buildShell(child: const _PlaceholderRow());
      },
    );
  }

  Widget _buildShell({required Widget child, bool isOpen = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: const BorderSide(color: Color(0xFF2196F3), width: 3),
          bottom: isOpen
              ? const BorderSide(color: Color(0xFF2196F3), width: 1)
              : BorderSide.none,
        ),
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

// ── Row sub-widgets ────────────────────────────────────────────────────────────

class _SelectedRow extends StatelessWidget {
  final CustomerModel? selected;
  final bool isOpen;

  const _SelectedRow({this.selected, required this.isOpen});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.person_outline_rounded,
          color: Colors.black45,
          size: 22,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Customer',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black45,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                selected?.aliasName ?? 'Select a customer',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: selected != null ? Colors.black : Colors.black38,
                  letterSpacing: -0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        AnimatedRotation(
          turns: isOpen ? 0.5 : 0,
          duration: const Duration(milliseconds: 200),
          child: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.black26,
            size: 22,
          ),
        ),
      ],
    );
  }
}

class _PlaceholderRow extends StatelessWidget {
  const _PlaceholderRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Icon(Icons.person_outline_rounded, color: Colors.black45, size: 22),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Walk-in Customer',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              letterSpacing: -0.2,
            ),
          ),
        ),
        Icon(Icons.chevron_right_rounded, color: Colors.black26),
      ],
    );
  }
}

class _LoadingRow extends StatelessWidget {
  const _LoadingRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Icon(Icons.person_outline_rounded, color: Colors.black45, size: 22),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Loading customers…',
            style: TextStyle(fontSize: 14, color: Colors.black38),
          ),
        ),
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF2196F3),
          ),
        ),
      ],
    );
  }
}

class _ErrorRow extends StatelessWidget {
  final String message;
  const _ErrorRow({required this.message});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.error_outline_rounded,
          color: Colors.redAccent,
          size: 22,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Failed to load customers',
            style: const TextStyle(fontSize: 14, color: Colors.redAccent),
          ),
        ),
      ],
    );
  }
}

// ─── Dropdown Overlay Panel ───────────────────────────────────────────────────

class _DropdownOverlay extends StatefulWidget {
  final List<CustomerModel> customers;
  final CustomerModel? selected;
  final ValueChanged<CustomerModel> onSelect;

  const _DropdownOverlay({
    required this.customers,
    required this.selected,
    required this.onSelect,
  });

  @override
  State<_DropdownOverlay> createState() => _DropdownOverlayState();
}

class _DropdownOverlayState extends State<_DropdownOverlay> {
  late List<CustomerModel> _filtered;
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filtered = widget.customers;
    _search.addListener(_onSearch);
  }

  void _onSearch() {
    final q = _search.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? widget.customers
          : widget.customers
                .where((c) => c.aliasName.toLowerCase().contains(q))
                .toList();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: screenWidth - 48, // matches 24px horizontal padding each side
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8E8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Search bar ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: Colors.black38,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _search,
                      autofocus: true,
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                      decoration: const InputDecoration(
                        hintText: 'Search customer…',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: Colors.black38,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF0F0F0)),

          // ── List ────────────────────────────────────────────────────
          Flexible(
            child: _filtered.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No customers found',
                      style: TextStyle(fontSize: 14, color: Colors.black38),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shrinkWrap: true,
                    itemCount: _filtered.length,
                    separatorBuilder: (_, _) => const Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: Color(0xFFF5F5F5),
                    ),
                    itemBuilder: (_, i) {
                      final c = _filtered[i];
                      final isSelected =
                          widget.selected?.accountId == c.accountId;

                      return GestureDetector(
                        onTap: () => widget.onSelect(c),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          color: isSelected
                              ? const Color(0xFFE3F2FD)
                              : Colors.transparent,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  c.aliasName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: isSelected
                                        ? const Color(0xFF1565C0)
                                        : Colors.black87,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: Color(0xFF2196F3),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
