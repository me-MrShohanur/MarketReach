import 'package:flutter/material.dart';
import 'package:marketing/services/models/customer.dart';
import 'package:marketing/services/provider/customer_service.dart';

class SelectCustomerSheet extends StatefulWidget {
  final ValueChanged<CustomerModel?> onCustomerSelected;

  const SelectCustomerSheet({super.key, required this.onCustomerSelected});

  static Future<void> show(
    BuildContext context, {
    required ValueChanged<CustomerModel?> onCustomerSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          SelectCustomerSheet(onCustomerSelected: onCustomerSelected),
    );
  }

  @override
  State<SelectCustomerSheet> createState() => _SelectCustomerSheetState();
}

class _SelectCustomerSheetState extends State<SelectCustomerSheet> {
  final CustomerService _service = CustomerService();
  final TextEditingController _searchController = TextEditingController();

  List<CustomerModel> _allCustomers = [];
  List<CustomerModel> _filtered = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    try {
      final customers = await _service.fetchCustomers();
      setState(() {
        _allCustomers = customers;
        _filtered = customers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onSearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filtered = _allCustomers
          .where((c) => (c.aliasName ?? '').toLowerCase().contains(query))
          .toList();
    });
  }

  void _selectCustomer(CustomerModel? customer) {
    if (customer != null) {
      debugPrint('accountId: ${customer.accountId}');
    }
    widget.onCustomerSelected(customer);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(24),
      ),
      // Cap height at 80% of screen
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.80,
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ──────────────────────────────────────────────────
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

          // ── Title ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Customer',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    letterSpacing: -0.4,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Search Bar ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 14, color: Colors.black),
                decoration: const InputDecoration(
                  hintText: 'Search by name...',
                  hintStyle: TextStyle(fontSize: 14, color: Colors.black38),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: Colors.black38,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── List ─────────────────────────────────────────────────────
          Flexible(
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    ),
                  )
                : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.wifi_off_rounded,
                            size: 40,
                            color: Colors.black26,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Failed to load customers',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _error!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black45,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isLoading = true;
                                _error = null;
                              });
                              _loadCustomers();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Retry',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: _filtered.length + 1, // +1 for Walk-in
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      // Walk-in Customer pinned at top
                      if (index == 0) {
                        return _CustomerTile(
                          name: 'Walk-in Customer',
                          subtitle: 'No account linked',
                          isWalkIn: true,
                          onTap: () => _selectCustomer(null),
                        );
                      }

                      final customer = _filtered[index - 1];
                      return _CustomerTile(
                        name: customer.aliasName ?? '—',
                        subtitle: 'ID: ${customer.accountId ?? '—'}',
                        isWalkIn: false,
                        onTap: () => _selectCustomer(customer),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Customer Tile ────────────────────────────────────────────────────────────

class _CustomerTile extends StatelessWidget {
  final String name;
  final String subtitle;
  final bool isWalkIn;
  final VoidCallback onTap;

  const _CustomerTile({
    required this.name,
    required this.subtitle,
    required this.isWalkIn,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: isWalkIn
              ? const Border(
                  left: BorderSide(color: Color(0xFF2196F3), width: 3),
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isWalkIn
                    ? const Color(0xFF2196F3).withValues(alpha: 0.08)
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isWalkIn
                    ? Icons.person_outline_rounded
                    : Icons.account_circle_outlined,
                size: 18,
                color: isWalkIn ? const Color(0xFF2196F3) : Colors.black45,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: Colors.black38),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Colors.black26,
            ),
          ],
        ),
      ),
    );
  }
}
