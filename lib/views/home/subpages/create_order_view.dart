// lib/views/home/subpages/create_order_view.dart

import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:marketing/bloc/customer/customer_provider.dart';
import 'package:marketing/services/models/products_model.dart';
import 'package:marketing/services/provider/ordersave_service.dart';
import 'package:marketing/views/home/subpages/product_list_view.dart';
import 'package:marketing/views/home/subpages/select_customer.dart';

class CreateOrderView extends StatefulWidget {
  const CreateOrderView({super.key});

  @override
  State<CreateOrderView> createState() => _CreateOrderViewState();
}

class _CreateOrderViewState extends State<CreateOrderView> {
  final List<ProductModel> _cart = [];
  final List<File> _attachments = [];

  double discount = 0;
  double tax = 0;
  String orderStatus = 'Pending';
  DateTime? _chequeDate;
  bool _isLoading = false;

  bool _customerSelected = false;
  int? _selectedPartyId;

  final TextEditingController _deliveryContactCtrl = TextEditingController();
  final TextEditingController _deliveryAddressCtrl = TextEditingController();
  bool _isDeliveryExpanded = false;

  static const _orderStatuses = [
    'Pending',
    'Processing',
    'Completed',
    'Cancelled',
  ];

  double get _subtotal => _cart.fold(0, (s, p) => s + p.cartNetAmount);
  double get _total => _subtotal - discount + tax;

  bool get _canAddProducts => _customerSelected;
  bool get _canCreateOrder =>
      _customerSelected && _cart.isNotEmpty && !_isLoading;

  @override
  void dispose() {
    _deliveryContactCtrl.dispose();
    _deliveryAddressCtrl.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _cart.clear();
      _attachments.clear();
      discount = 0;
      tax = 0;
      orderStatus = 'Pending';
      _chequeDate = null;
      _isLoading = false;
      _customerSelected = false;
      _selectedPartyId = null;
      _deliveryContactCtrl.clear();
      _deliveryAddressCtrl.clear();
      _isDeliveryExpanded = false;
    });
  }

  // ── Attachment pickers ────────────────────────────────────────────────────

  Future<void> _pickFromCamera() async {
    try {
      final XFile? photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (photo != null) {
        setState(() => _attachments.add(File(photo.path)));
        log('Camera photo added: ${photo.path}', name: 'Attachments');
      }
    } catch (e) {
      _showError('Camera error: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final List<XFile> photos = await ImagePicker().pickMultiImage(
        imageQuality: 80,
      );
      if (photos.isNotEmpty) {
        setState(() {
          for (final p in photos) _attachments.add(File(p.path));
        });
        log('${photos.length} photo(s) from gallery', name: 'Attachments');
      }
    } catch (e) {
      _showError('Gallery error: $e');
    }
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          for (final f in result.files) {
            if (f.path != null) _attachments.add(File(f.path!));
          }
        });
        log('${result.files.length} file(s) added', name: 'Attachments');
      }
    } catch (e) {
      _showError('File picker error: $e');
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AttachmentOptionsSheet(
        onCamera: () {
          Navigator.pop(context);
          _pickFromCamera();
        },
        onGallery: () {
          Navigator.pop(context);
          _pickFromGallery();
        },
        onFiles: () {
          Navigator.pop(context);
          _pickFiles();
        },
      ),
    );
  }

  void _removeAttachment(int index) =>
      setState(() => _attachments.removeAt(index));

  void _openSheet() {
    if (!_canAddProducts) return;
    AddProductsSheet.show(
      context,
      partyId: _selectedPartyId ?? 0,
      categoryId: 1,
      onProductsAdded: (List<ProductModel> products) {
        setState(() {
          for (final p in products) {
            final existingIndex = _cart.indexWhere((c) => c.name == p.name);
            if (existingIndex != -1) {
              _cart[existingIndex] = p;
            } else {
              _cart.add(p);
            }
          }
        });
        log('Products added/updated in cart: ${products.length}', name: 'Cart');
      },
    );
  }

  Future<void> _selectChequeDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _chequeDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF4CAF50),
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _chequeDate) {
      setState(() => _chequeDate = picked);
    }
  }

  Future<void> _submitOrder() async {
    if (!_canCreateOrder) return;
    setState(() => _isLoading = true);

    try {
      final response = await OrderSaveService.saveOrder(
        partyId: _selectedPartyId!,
        cart: _cart,
        discount: discount,
        tax: tax,
        files: _attachments.isEmpty ? null : _attachments,
        chequeDate: _chequeDate,
        shippingContact: _deliveryContactCtrl.text.trim(),
        shippingAddress: _deliveryAddressCtrl.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ ${response.result} (Order ID #${response.orderId})'),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      _resetForm();
    } on OrderSaveException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (e) {
      if (!mounted) return;
      _showError('Unexpected error: $e');
    } finally {
      if (mounted && _isLoading) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: SafeArea(
          child: Column(
            children: [
              _Header(
                attachmentCount: _attachments.length,
                onAttachmentTap: _showAttachmentOptions,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    children: [
                      // ── Customer Dropdown ───────────────────────────────
                      BlocProvider(
                        create: (_) => CustomerBloc()..add(LoadCustomers()),
                        child: BlocConsumer<CustomerBloc, CustomerState>(
                          listener: (context, state) {
                            if (state is CustomerLoaded &&
                                state.selectedCustomer != null) {
                              final selected = state.selectedCustomer!;
                              setState(() {
                                _customerSelected = true;
                                _selectedPartyId = selected.accountId;
                              });
                              log(
                                'Customer: id=${selected.accountId} '
                                'name=${selected.aliasName}',
                                name: 'CustomerDropdown',
                              );
                            } else if (state is CustomerLoaded &&
                                state.selectedCustomer == null) {
                              setState(() {
                                _customerSelected = false;
                                _selectedPartyId = null;
                              });
                            }
                          },
                          builder: (context, state) =>
                              const CustomerDropdownCard(),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── Cart ─────────────────────────────────────────────
                      _cart.isEmpty
                          ? _EmptyCart(
                              onAdd: _openSheet,
                              enabled: _canAddProducts,
                            )
                          : _CartList(
                              items: _cart,
                              onRemove: (i) =>
                                  setState(() => _cart.removeAt(i)),
                              onAddMore: _openSheet,
                            ),

                      const SizedBox(height: 12),

                      // ── Summary — green left accent ───────────────────────
                      _AccentCard(
                        accent: const Color(0xFF4CAF50),
                        child: _SummaryCardContent(
                          subtotal: _subtotal,
                          discount: discount,
                          tax: tax,
                          total: _total,
                          onDiscountChanged: (v) =>
                              setState(() => discount = v),
                          onTaxChanged: (v) => setState(() => tax = v),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── Delivery Info ─────────────────────────────────────
                      _DeliveryInfoCard(
                        isExpanded: _isDeliveryExpanded,
                        onToggle: () => setState(() {
                          _isDeliveryExpanded = !_isDeliveryExpanded;
                        }),
                        contactCtrl: _deliveryContactCtrl,
                        addressCtrl: _deliveryAddressCtrl,
                      ),

                      const SizedBox(height: 12),

                      if (_attachments.isNotEmpty)
                        _AttachmentsCard(
                          files: _attachments,
                          onAdd: _showAttachmentOptions,
                          onRemove: _removeAttachment,
                        ),
                      if (_attachments.isNotEmpty) const SizedBox(height: 12),

                      // ── Cheque Date — blue left accent ────────────────────
                      _ChequeDateCard(
                        chequeDate: _chequeDate,
                        onTap: _selectChequeDate,
                      ),

                      const SizedBox(height: 12),

                      // ── Status Dropdown — amber left accent ───────────────
                      _AccentCard(
                        accent: const Color(0xFFFFC107),
                        child: _StatusDropdownContent(
                          label: 'Order Status',
                          value: orderStatus,
                          items: _orderStatuses,
                          onChanged: (v) => setState(() => orderStatus = v!),
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              _BottomButton(
                label: _isLoading ? 'Creating Order…' : 'Create Order',
                icon: _isLoading
                    ? Icons.hourglass_top_rounded
                    : Icons.check_rounded,
                enabled: _canCreateOrder,
                onTap: _submitOrder,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final int attachmentCount;
  final VoidCallback onAttachmentTap;

  const _Header({required this.attachmentCount, required this.onAttachmentTap});

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
          GestureDetector(
            onTap: onAttachmentTap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.attach_file_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                if (attachmentCount > 0)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2196F3),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          attachmentCount > 9
                              ? '9+'
                              : attachmentCount.toString(),
                          style: const TextStyle(
                            fontSize: 11,
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
    );
  }
}

// ─── Accent Card — white card with colored LEFT border (your signature style)
// Q2 Fix: Uses Border(left: BorderSide(...)) not Border.all()
// ─────────────────────────────────────────────────────────────────────────────

class _AccentCard extends StatelessWidget {
  final Color accent;
  final Widget child;

  const _AccentCard({required this.accent, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      // ✅ Left-only border — your design system style
      border: Border(left: BorderSide(color: accent, width: 3)),
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

// ─── Plain white card (no accent) ────────────────────────────────────────────

class _PlainCard extends StatelessWidget {
  final Widget child;
  const _PlainCard({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
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
    child: child,
  );
}

// ─── Summary Card Content (green accent via _AccentCard) ──────────────────────

class _SummaryCardContent extends StatelessWidget {
  final double subtotal, discount, tax, total;
  final ValueChanged<double> onDiscountChanged, onTaxChanged;

  const _SummaryCardContent({
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.onDiscountChanged,
    required this.onTaxChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
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
          _SummaryRow(
            label: 'Subtotal',
            value: '৳${subtotal.toStringAsFixed(2)}',
          ),
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
    );
  }
}

// ─── Status Dropdown Content (amber accent via _AccentCard) ───────────────────

class _StatusDropdownContent extends StatelessWidget {
  final String label, value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _StatusDropdownContent({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
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
    );
  }
}

// ─── Collapsible Delivery Info Card ──────────────────────────────────────────

class _DeliveryInfoCard extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggle;
  final TextEditingController contactCtrl;
  final TextEditingController addressCtrl;

  const _DeliveryInfoCard({
    required this.isExpanded,
    required this.onToggle,
    required this.contactCtrl,
    required this.addressCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          left: BorderSide(color: Color(0xFF9C27B0), width: 3),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E5F5),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.local_shipping_outlined,
                      color: Color(0xFF9C27B0),
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Delivery Info',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black45,
                            letterSpacing: 0.2,
                          ),
                        ),
                        if (!isExpanded &&
                            (contactCtrl.text.isNotEmpty ||
                                addressCtrl.text.isNotEmpty))
                          Text(
                            contactCtrl.text.isNotEmpty
                                ? contactCtrl.text
                                : addressCtrl.text,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9C27B0),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.black45,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  const SizedBox(height: 14),
                  _DeliveryField(
                    controller: contactCtrl,
                    label: 'Delivery Contact',
                    hint: 'Enter contact number (optional)',
                    icon: Icons.phone_outlined,
                    iconColor: const Color(0xFF9C27B0),
                    iconBg: const Color(0xFFF3E5F5),
                    keyboardType: TextInputType.phone,
                    inputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  _DeliveryField(
                    controller: addressCtrl,
                    label: 'Delivery Address',
                    hint: 'Enter delivery address (optional)',
                    icon: Icons.location_on_outlined,
                    iconColor: const Color(0xFF9C27B0),
                    iconBg: const Color(0xFFF3E5F5),
                    keyboardType: TextInputType.streetAddress,
                    inputAction: TextInputAction.done,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DeliveryField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final TextInputType keyboardType;
  final TextInputAction inputAction;
  final int maxLines;

  const _DeliveryField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.keyboardType,
    required this.inputAction,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 0, 12),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: iconColor, size: 17),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              textInputAction: inputAction,
              maxLines: maxLines,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(
                  fontSize: 12,
                  color: Colors.black45,
                  fontWeight: FontWeight.w500,
                ),
                hintText: hint,
                hintStyle: const TextStyle(fontSize: 13, color: Colors.black26),
                contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Attachment Options Sheet ─────────────────────────────────────────────────

class _AttachmentOptionsSheet extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onFiles;

  const _AttachmentOptionsSheet({
    required this.onCamera,
    required this.onGallery,
    required this.onFiles,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Add Attachment',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Attach photos or files to this order',
              style: TextStyle(fontSize: 13, color: Colors.black45),
            ),
          ),
          const SizedBox(height: 20),
          _OptionTile(
            icon: Icons.camera_alt_rounded,
            iconColor: const Color(0xFF2196F3),
            iconBg: const Color(0xFFE3F2FD),
            title: 'Take Photo',
            subtitle: 'Open camera',
            onTap: onCamera,
          ),
          const SizedBox(height: 10),
          _OptionTile(
            icon: Icons.photo_library_rounded,
            iconColor: const Color(0xFF9C27B0),
            iconBg: const Color(0xFFF3E5F5),
            title: 'Choose from Gallery',
            subtitle: 'Select one or more photos',
            onTap: onGallery,
          ),
          const SizedBox(height: 10),
          _OptionTile(
            icon: Icons.attach_file_rounded,
            iconColor: const Color(0xFF4CAF50),
            iconBg: const Color(0xFFE8F5E9),
            title: 'Browse Files',
            subtitle: 'PDF, Word, images',
            onTap: onFiles,
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Colors.black26,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Attachments Card ────────────────────────────────────────────────────────

class _AttachmentsCard extends StatelessWidget {
  final List<File> files;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  const _AttachmentsCard({
    required this.files,
    required this.onAdd,
    required this.onRemove,
  });

  String _ext(File f) {
    final parts = f.path.split('/').last.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : 'file';
  }

  bool _isImage(File f) =>
      ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'].contains(_ext(f));

  String _fileName(File f) => f.path.split('/').last;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          left: BorderSide(color: Color(0xFF2196F3), width: 3),
        ),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.attach_file_rounded,
                      size: 18,
                      color: Colors.black45,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Attachments (${files.length})',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black45,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Row(
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
            const SizedBox(height: 14),
            if (files.any(_isImage)) ...[
              SizedBox(
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: files.length,
                  itemBuilder: (_, i) {
                    final file = files[i];
                    if (!_isImage(file)) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              file,
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => onRemove(i),
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 13,
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
              const SizedBox(height: 10),
            ],
            ...files
                .asMap()
                .entries
                .where((e) => !_isImage(e.value))
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white,
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
                            onTap: () => onRemove(entry.key),
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
        ),
      ),
    );
  }
}

// ─── Cheque Date Card — blue left accent ──────────────────────────────────────

class _ChequeDateCard extends StatelessWidget {
  final DateTime? chequeDate;
  final VoidCallback onTap;

  const _ChequeDateCard({required this.chequeDate, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: const Border(
            left: BorderSide(color: Color(0xFF2196F3), width: 3),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.calendar_today_rounded,
                      color: Color(0xFF2196F3),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cheque Date',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black45,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        chequeDate != null
                            ? '${chequeDate!.day.toString().padLeft(2, '0')}/'
                                  '${chequeDate!.month.toString().padLeft(2, '0')}/'
                                  '${chequeDate!.year}'
                            : 'Select date (optional)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: chequeDate != null
                              ? const Color(0xFF4CAF50)
                              : Colors.black54,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Empty Cart ───────────────────────────────────────────────────────────────

class _EmptyCart extends StatelessWidget {
  final VoidCallback onAdd;
  final bool enabled;
  const _EmptyCart({required this.onAdd, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return _PlainCard(
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
            Text(
              enabled
                  ? 'Add products to create an order'
                  : 'Select a customer first',
              style: TextStyle(
                fontSize: 13,
                color: enabled ? Colors.black45 : Colors.orangeAccent,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: enabled ? onAdd : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: enabled ? Colors.black : Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: enabled
                      ? const [
                          BoxShadow(
                            color: Color(0x26000000),
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          ),
                        ]
                      : [],
                ),
                child: const Row(
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
    return _PlainCard(
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
                GestureDetector(
                  onTap: onAddMore,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Row(
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
                Row(
                  children: [
                    Text(
                      '${product.cartQty.toStringAsFixed(0)} × '
                      '৳${product.cartRate.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '৳${product.cartNetAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  ],
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

// ─── Summary Row / Editable Row helpers ──────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final String label, value;
  const _SummaryRow({required this.label, required this.value});

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

// ─── Bottom Button ────────────────────────────────────────────────────────────

class _BottomButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const _BottomButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.enabled = true,
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
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            color: enabled ? Colors.black : Colors.black26,
            borderRadius: BorderRadius.circular(16),
            boxShadow: enabled
                ? const [
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ]
                : [],
          ),
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
    );
  }
}

// ─── Icon Button ─────────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
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
      child: Icon(icon, size: 16, color: Colors.black),
    ),
  );
}
//-----------------------------------------------------------------
// import 'dart:developer';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:marketing/bloc/customer/customer_provider.dart';
// import 'package:marketing/services/models/products_model.dart';
// import 'package:marketing/services/provider/ordersave_service.dart';
// import 'package:marketing/views/home/subpages/product_list_view.dart';
// import 'package:marketing/views/home/subpages/select_customer.dart';

// class CreateOrderView extends StatefulWidget {
//   const CreateOrderView({super.key});

//   @override
//   State<CreateOrderView> createState() => _CreateOrderViewState();
// }

// class _CreateOrderViewState extends State<CreateOrderView> {
//   final List<ProductModel> _cart = [];
//   final List<File> _attachments = [];

//   double discount = 0;
//   double tax = 0;
//   String orderStatus = 'Pending';
//   DateTime? _chequeDate;
//   bool _isLoading = false;

//   bool _customerSelected = false;
//   int? _selectedPartyId;

//   static const _orderStatuses = [
//     'Pending',
//     'Processing',
//     'Completed',
//     'Cancelled',
//   ];

//   double get _subtotal => _cart.fold(0, (s, p) => s + p.cartNetAmount);
//   double get _total => _subtotal - discount + tax;

//   bool get _canAddProducts => _customerSelected;
//   bool get _canCreateOrder =>
//       _customerSelected && _cart.isNotEmpty && !_isLoading;

//   void _resetForm() {
//     setState(() {
//       _cart.clear();
//       _attachments.clear();
//       discount = 0;
//       tax = 0;
//       orderStatus = 'Pending';
//       _chequeDate = null;
//       _isLoading = false;
//       _customerSelected = false;
//       _selectedPartyId = null;
//     });
//   }

//   // ── Attachment pickers ────────────────────────────────────────────────────
//   Future<void> _pickFromCamera() async {
//     try {
//       final XFile? photo = await ImagePicker().pickImage(
//         source: ImageSource.camera,
//         imageQuality: 80,
//       );
//       if (photo != null) {
//         setState(() => _attachments.add(File(photo.path)));
//         log('Camera photo added: ${photo.path}', name: 'Attachments');
//       }
//     } catch (e) {
//       _showError('Camera error: $e');
//     }
//   }

//   Future<void> _pickFromGallery() async {
//     try {
//       final List<XFile> photos = await ImagePicker().pickMultiImage(
//         imageQuality: 80,
//       );
//       if (photos.isNotEmpty) {
//         setState(() {
//           for (final p in photos) _attachments.add(File(p.path));
//         });
//         log('${photos.length} photo(s) from gallery', name: 'Attachments');
//       }
//     } catch (e) {
//       _showError('Gallery error: $e');
//     }
//   }

//   Future<void> _pickFiles() async {
//     try {
//       final result = await FilePicker.platform.pickFiles(
//         allowMultiple: true,
//         type: FileType.custom,
//         allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
//       );
//       if (result != null && result.files.isNotEmpty) {
//         setState(() {
//           for (final f in result.files) {
//             if (f.path != null) _attachments.add(File(f.path!));
//           }
//         });
//         log('${result.files.length} file(s) added', name: 'Attachments');
//       }
//     } catch (e) {
//       _showError('File picker error: $e');
//     }
//   }

//   void _showAttachmentOptions() {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       builder: (_) => _AttachmentOptionsSheet(
//         onCamera: () {
//           Navigator.pop(context);
//           _pickFromCamera();
//         },
//         onGallery: () {
//           Navigator.pop(context);
//           _pickFromGallery();
//         },
//         onFiles: () {
//           Navigator.pop(context);
//           _pickFiles();
//         },
//       ),
//     );
//   }

//   void _removeAttachment(int index) =>
//       setState(() => _attachments.removeAt(index));

//   void _openSheet() {
//     if (!_canAddProducts) return;
//     AddProductsSheet.show(
//       context,
//       partyId: _selectedPartyId ?? 0,
//       categoryId: 1,
//       onProductAdded: (ProductModel product) {
//         setState(() => _cart.add(product));
//         log(
//           'Added to cart: ${product.name} | '
//           'qty=${product.cartQty} | net=${product.cartNetAmount}',
//           name: 'Cart',
//         );
//       },
//     );
//   }

//   // ─── Date picker for cheque date ─────────────────────────────────────────
//   Future<void> _selectChequeDate() async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _chequeDate ?? DateTime.now(),
//       firstDate: DateTime(2020),
//       lastDate: DateTime(2030),
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: const ColorScheme.light(
//               primary: Color(0xFF4CAF50),
//               onPrimary: Colors.white,
//               surface: Colors.white,
//               onSurface: Colors.black,
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );
//     if (picked != null && picked != _chequeDate) {
//       setState(() {
//         _chequeDate = picked;
//       });
//       log(
//         'Cheque date selected: ${_formatDateForApi(picked)}',
//         name: 'ChequeDate',
//       );
//     }
//   }

//   String _formatDateForApi(DateTime date) {
//     return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
//   }

//   Future<void> _submitOrder() async {
//     if (!_canCreateOrder) return;
//     setState(() => _isLoading = true);

//     try {
//       final response = await OrderSaveService.saveOrder(
//         partyId: _selectedPartyId!,
//         cart: _cart,
//         discount: discount,
//         tax: tax,
//         files: _attachments.isEmpty ? null : _attachments,
//         chequeDate: _chequeDate,
//       );

//       if (!mounted) return;

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('✓ ${response.result} (Order ID #${response.orderId})'),
//           backgroundColor: const Color(0xFF4CAF50),
//           behavior: SnackBarBehavior.floating,
//           margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//         ),
//       );

//       _resetForm();
//     } on OrderSaveException catch (e) {
//       if (!mounted) return;
//       _showError(e.message);
//     } catch (e) {
//       if (!mounted) return;
//       _showError('Unexpected error: $e');
//     } finally {
//       if (mounted && _isLoading) setState(() => _isLoading = false);
//     }
//   }

//   void _showError(String msg) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(msg),
//         backgroundColor: Colors.redAccent,
//         behavior: SnackBarBehavior.floating,
//         margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AnnotatedRegion<SystemUiOverlayStyle>(
//       value: SystemUiOverlayStyle.dark,
//       child: Scaffold(
//         backgroundColor: const Color(0xFFF5F5F5),
//         body: SafeArea(
//           child: Column(
//             children: [
//               _Header(
//                 attachmentCount: _attachments.length,
//                 onAttachmentTap: _showAttachmentOptions,
//               ),
//               const SizedBox(height: 24),
//               Expanded(
//                 child: SingleChildScrollView(
//                   padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
//                   child: Column(
//                     children: [
//                       BlocProvider(
//                         create: (_) => CustomerBloc()..add(LoadCustomers()),
//                         child: BlocConsumer<CustomerBloc, CustomerState>(
//                           listener: (context, state) {
//                             if (state is CustomerLoaded &&
//                                 state.selectedCustomer != null) {
//                               final selected = state.selectedCustomer!;
//                               setState(() {
//                                 _customerSelected = true;
//                                 _selectedPartyId = selected.accountId;
//                               });
//                               log(
//                                 'Customer: id=${selected.accountId} '
//                                 'name=${selected.aliasName}',
//                                 name: 'CustomerDropdown',
//                               );
//                             } else if (state is CustomerLoaded &&
//                                 state.selectedCustomer == null) {
//                               setState(() {
//                                 _customerSelected = false;
//                                 _selectedPartyId = null;
//                               });
//                             }
//                           },
//                           builder: (context, state) =>
//                               const CustomerDropdownCard(),
//                         ),
//                       ),
//                       const SizedBox(height: 12),
//                       _cart.isEmpty
//                           ? _EmptyCart(
//                               onAdd: _openSheet,
//                               enabled: _canAddProducts,
//                             )
//                           : _CartList(
//                               items: _cart,
//                               onRemove: (i) =>
//                                   setState(() => _cart.removeAt(i)),
//                               onAddMore: _openSheet,
//                             ),
//                       const SizedBox(height: 12),
//                       _SummaryCard(
//                         subtotal: _subtotal,
//                         discount: discount,
//                         tax: tax,
//                         total: _total,
//                         onDiscountChanged: (v) => setState(() => discount = v),
//                         onTaxChanged: (v) => setState(() => tax = v),
//                       ),
//                       const SizedBox(height: 12),
//                       if (_attachments.isNotEmpty)
//                         _AttachmentsCard(
//                           files: _attachments,
//                           onAdd: _showAttachmentOptions,
//                           onRemove: _removeAttachment,
//                         ),
//                       if (_attachments.isNotEmpty) const SizedBox(height: 12),
//                       _ChequeDateCard(
//                         chequeDate: _chequeDate,
//                         onTap: _selectChequeDate,
//                       ),
//                       const SizedBox(height: 12),
//                       _StatusDropdown(
//                         label: 'Order Status',
//                         value: orderStatus,
//                         items: _orderStatuses,
//                         accent: const Color(0xFFFFC107),
//                         onChanged: (v) => setState(() => orderStatus = v!),
//                       ),
//                       const SizedBox(height: 16),
//                     ],
//                   ),
//                 ),
//               ),
//               _BottomButton(
//                 label: _isLoading ? 'Creating Order…' : 'Create Order',
//                 icon: _isLoading
//                     ? Icons.hourglass_top_rounded
//                     : Icons.check_rounded,
//                 enabled: _canCreateOrder,
//                 onTap: _submitOrder,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ─── Header ──────────────────────────────────────────────────────────────────

// class _Header extends StatelessWidget {
//   final int attachmentCount;
//   final VoidCallback onAttachmentTap;

//   const _Header({required this.attachmentCount, required this.onAttachmentTap});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Row(
//             children: [
//               _IconBtn(
//                 icon: Icons.arrow_back_ios_new_rounded,
//                 onTap: () => Navigator.maybePop(context),
//               ),
//               const SizedBox(width: 14),
//               const Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'New Transaction',
//                     style: TextStyle(fontSize: 13, color: Colors.black45),
//                   ),
//                   Text(
//                     'Create Order',
//                     style: TextStyle(
//                       fontSize: 26,
//                       fontWeight: FontWeight.w700,
//                       letterSpacing: -0.5,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//           GestureDetector(
//             onTap: onAttachmentTap,
//             child: Stack(
//               clipBehavior: Clip.none,
//               children: [
//                 Container(
//                   width: 44,
//                   height: 44,
//                   decoration: BoxDecoration(
//                     color: Colors.black,
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: const Icon(
//                     Icons.attach_file_rounded,
//                     color: Colors.white,
//                     size: 22,
//                   ),
//                 ),
//                 if (attachmentCount > 0)
//                   Positioned(
//                     top: -6,
//                     right: -6,
//                     child: Container(
//                       width: 20,
//                       height: 20,
//                       decoration: const BoxDecoration(
//                         color: Color(0xFF2196F3),
//                         shape: BoxShape.circle,
//                       ),
//                       child: Center(
//                         child: Text(
//                           attachmentCount > 9
//                               ? '9+'
//                               : attachmentCount.toString(),
//                           style: const TextStyle(
//                             fontSize: 11,
//                             fontWeight: FontWeight.w700,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ─── Attachment Options Bottom Sheet ─────────────────────────────────────────

// class _AttachmentOptionsSheet extends StatelessWidget {
//   final VoidCallback onCamera;
//   final VoidCallback onGallery;
//   final VoidCallback onFiles;

//   const _AttachmentOptionsSheet({
//     required this.onCamera,
//     required this.onGallery,
//     required this.onFiles,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: const BoxDecoration(
//         color: Color(0xFFF5F5F5),
//         borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//       ),
//       padding: EdgeInsets.fromLTRB(
//         24,
//         16,
//         24,
//         24 + MediaQuery.of(context).padding.bottom,
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             width: 36,
//             height: 4,
//             margin: const EdgeInsets.only(bottom: 20),
//             decoration: BoxDecoration(
//               color: Colors.black12,
//               borderRadius: BorderRadius.circular(2),
//             ),
//           ),
//           const Align(
//             alignment: Alignment.centerLeft,
//             child: Text(
//               'Add Attachment',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.w700,
//                 letterSpacing: -0.4,
//               ),
//             ),
//           ),
//           const SizedBox(height: 4),
//           const Align(
//             alignment: Alignment.centerLeft,
//             child: Text(
//               'Attach photos or files to this order',
//               style: TextStyle(fontSize: 13, color: Colors.black45),
//             ),
//           ),
//           const SizedBox(height: 20),
//           _OptionTile(
//             icon: Icons.camera_alt_rounded,
//             iconColor: const Color(0xFF2196F3),
//             iconBg: const Color(0xFFE3F2FD),
//             title: 'Take Photo',
//             subtitle: 'Open camera',
//             onTap: onCamera,
//           ),
//           const SizedBox(height: 10),
//           _OptionTile(
//             icon: Icons.photo_library_rounded,
//             iconColor: const Color(0xFF9C27B0),
//             iconBg: const Color(0xFFF3E5F5),
//             title: 'Choose from Gallery',
//             subtitle: 'Select one or more photos',
//             onTap: onGallery,
//           ),
//           const SizedBox(height: 10),
//           _OptionTile(
//             icon: Icons.attach_file_rounded,
//             iconColor: const Color(0xFF4CAF50),
//             iconBg: const Color(0xFFE8F5E9),
//             title: 'Browse Files',
//             subtitle: 'PDF, Word, images',
//             onTap: onFiles,
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _OptionTile extends StatelessWidget {
//   final IconData icon;
//   final Color iconColor;
//   final Color iconBg;
//   final String title;
//   final String subtitle;
//   final VoidCallback onTap;

//   const _OptionTile({
//     required this.icon,
//     required this.iconColor,
//     required this.iconBg,
//     required this.title,
//     required this.subtitle,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(14),
//           boxShadow: const [
//             BoxShadow(
//               color: Color(0x0D000000),
//               blurRadius: 8,
//               offset: Offset(0, 3),
//             ),
//           ],
//         ),
//         child: Row(
//           children: [
//             Container(
//               width: 44,
//               height: 44,
//               decoration: BoxDecoration(
//                 color: iconBg,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Icon(icon, color: iconColor, size: 22),
//             ),
//             const SizedBox(width: 14),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     title,
//                     style: const TextStyle(
//                       fontSize: 15,
//                       fontWeight: FontWeight.w600,
//                       letterSpacing: -0.2,
//                     ),
//                   ),
//                   const SizedBox(height: 2),
//                   Text(
//                     subtitle,
//                     style: const TextStyle(fontSize: 12, color: Colors.black45),
//                   ),
//                 ],
//               ),
//             ),
//             const Icon(
//               Icons.arrow_forward_ios_rounded,
//               size: 14,
//               color: Colors.black26,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ─── Attachments Card ────────────────────────────────────────────────────────

// class _AttachmentsCard extends StatelessWidget {
//   final List<File> files;
//   final VoidCallback onAdd;
//   final ValueChanged<int> onRemove;

//   const _AttachmentsCard({
//     required this.files,
//     required this.onAdd,
//     required this.onRemove,
//   });

//   String _ext(File f) {
//     final parts = f.path.split('/').last.split('.');
//     return parts.length > 1 ? parts.last.toLowerCase() : 'file';
//   }

//   bool _isImage(File f) =>
//       ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'].contains(_ext(f));

//   String _fileName(File f) => f.path.split('/').last;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: const Border(
//           left: BorderSide(color: Color(0xFF2196F3), width: 3),
//         ),
//         boxShadow: const [
//           BoxShadow(
//             color: Color(0x0D000000),
//             blurRadius: 10,
//             offset: Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Row(
//                   children: [
//                     const Icon(
//                       Icons.attach_file_rounded,
//                       size: 18,
//                       color: Colors.black45,
//                     ),
//                     const SizedBox(width: 8),
//                     Text(
//                       'Attachments (${files.length})',
//                       style: const TextStyle(
//                         fontSize: 13,
//                         color: Colors.black45,
//                         letterSpacing: 0.2,
//                       ),
//                     ),
//                   ],
//                 ),
//                 GestureDetector(
//                   onTap: onAdd,
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 12,
//                       vertical: 7,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.black,
//                       borderRadius: BorderRadius.circular(9),
//                     ),
//                     child: const Row(
//                       children: [
//                         Icon(Icons.add_rounded, color: Colors.white, size: 14),
//                         SizedBox(width: 4),
//                         Text(
//                           'Add More',
//                           style: TextStyle(
//                             fontSize: 12,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 14),
//             if (files.any(_isImage)) ...[
//               SizedBox(
//                 height: 90,
//                 child: ListView.builder(
//                   scrollDirection: Axis.horizontal,
//                   itemCount: files.length,
//                   itemBuilder: (_, i) {
//                     final file = files[i];
//                     if (!_isImage(file)) return const SizedBox.shrink();
//                     return Padding(
//                       padding: const EdgeInsets.only(right: 8),
//                       child: Stack(
//                         children: [
//                           ClipRRect(
//                             borderRadius: BorderRadius.circular(10),
//                             child: Image.file(
//                               file,
//                               width: 90,
//                               height: 90,
//                               fit: BoxFit.cover,
//                             ),
//                           ),
//                           Positioned(
//                             top: 4,
//                             right: 4,
//                             child: GestureDetector(
//                               onTap: () => onRemove(i),
//                               child: Container(
//                                 width: 22,
//                                 height: 22,
//                                 decoration: const BoxDecoration(
//                                   color: Colors.black54,
//                                   shape: BoxShape.circle,
//                                 ),
//                                 child: const Icon(
//                                   Icons.close_rounded,
//                                   color: Colors.white,
//                                   size: 13,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     );
//                   },
//                 ),
//               ),
//               const SizedBox(height: 10),
//             ],
//             ...files
//                 .asMap()
//                 .entries
//                 .where((e) => !_isImage(e.value))
//                 .map(
//                   (entry) => Padding(
//                     padding: const EdgeInsets.only(bottom: 8),
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 12,
//                         vertical: 10,
//                       ),
//                       decoration: BoxDecoration(
//                         color: const Color(0xFFF5F5F5),
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       child: Row(
//                         children: [
//                           Container(
//                             width: 36,
//                             height: 36,
//                             decoration: BoxDecoration(
//                               color: Colors.white,
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: Center(
//                               child: Text(
//                                 _ext(entry.value).toUpperCase(),
//                                 style: const TextStyle(
//                                   fontSize: 9,
//                                   fontWeight: FontWeight.w700,
//                                   color: Color(0xFF2196F3),
//                                 ),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 10),
//                           Expanded(
//                             child: Text(
//                               _fileName(entry.value),
//                               style: const TextStyle(
//                                 fontSize: 13,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                           GestureDetector(
//                             onTap: () => onRemove(entry.key),
//                             child: const Icon(
//                               Icons.close_rounded,
//                               size: 18,
//                               color: Colors.redAccent,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ─── Cheque Date Card ────────────────────────────────────────────────────────

// class _ChequeDateCard extends StatelessWidget {
//   final DateTime? chequeDate;
//   final VoidCallback onTap;

//   const _ChequeDateCard({required this.chequeDate, required this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: double.infinity,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           border: const Border(
//             left: BorderSide(color: Color(0xFF2196F3), width: 3),
//           ),
//           boxShadow: const [
//             BoxShadow(
//               color: Color(0x0D000000),
//               blurRadius: 10,
//               offset: Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Row(
//                 children: [
//                   Container(
//                     width: 36,
//                     height: 36,
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFE3F2FD),
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: const Icon(
//                       Icons.calendar_today_rounded,
//                       color: Color(0xFF2196F3),
//                       size: 18,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text(
//                         'Cheque Date',
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Colors.black45,
//                           letterSpacing: 0.2,
//                         ),
//                       ),
//                       const SizedBox(height: 2),
//                       Text(
//                         chequeDate != null
//                             ? '${chequeDate!.day}/${chequeDate!.month}/${chequeDate!.year}'
//                             : 'Select date',
//                         style: TextStyle(
//                           fontSize: 15,
//                           fontWeight: FontWeight.w600,
//                           color: chequeDate != null
//                               ? const Color(0xFF4CAF50)
//                               : Colors.black54,
//                           letterSpacing: -0.2,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//               Icon(
//                 Icons.arrow_forward_ios_rounded,
//                 size: 14,
//                 color: Colors.grey.shade400,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ─── Empty Cart ───────────────────────────────────────────────────────────────

// class _EmptyCart extends StatelessWidget {
//   final VoidCallback onAdd;
//   final bool enabled;
//   const _EmptyCart({required this.onAdd, this.enabled = true});

//   @override
//   Widget build(BuildContext context) {
//     return _Card(
//       child: Padding(
//         padding: const EdgeInsets.symmetric(vertical: 36),
//         child: Column(
//           children: [
//             Icon(
//               Icons.shopping_cart_outlined,
//               size: 64,
//               color: Colors.grey.shade300,
//             ),
//             const SizedBox(height: 10),
//             const Text(
//               'Cart is empty',
//               style: TextStyle(
//                 fontSize: 17,
//                 fontWeight: FontWeight.w700,
//                 letterSpacing: -0.3,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               enabled
//                   ? 'Add products to create an order'
//                   : 'Select a customer first',
//               style: TextStyle(
//                 fontSize: 13,
//                 color: enabled ? Colors.black45 : Colors.orangeAccent,
//               ),
//             ),
//             const SizedBox(height: 20),
//             GestureDetector(
//               onTap: enabled ? onAdd : null,
//               child: AnimatedContainer(
//                 duration: const Duration(milliseconds: 250),
//                 curve: Curves.easeInOut,
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 28,
//                   vertical: 13,
//                 ),
//                 decoration: BoxDecoration(
//                   color: enabled ? Colors.black : Colors.black26,
//                   borderRadius: BorderRadius.circular(12),
//                   boxShadow: enabled
//                       ? const [
//                           BoxShadow(
//                             color: Color(0x26000000),
//                             blurRadius: 12,
//                             offset: Offset(0, 6),
//                           ),
//                         ]
//                       : [],
//                 ),
//                 child: const Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(Icons.add_rounded, color: Colors.white, size: 18),
//                     SizedBox(width: 6),
//                     Text(
//                       'Add Products',
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ─── Cart List ────────────────────────────────────────────────────────────────

// class _CartList extends StatelessWidget {
//   final List<ProductModel> items;
//   final ValueChanged<int> onRemove;
//   final VoidCallback onAddMore;

//   const _CartList({
//     required this.items,
//     required this.onRemove,
//     required this.onAddMore,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return _Card(
//       child: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Row(
//                   children: [
//                     const Icon(
//                       Icons.shopping_cart_outlined,
//                       size: 18,
//                       color: Colors.black45,
//                     ),
//                     const SizedBox(width: 8),
//                     Text(
//                       '${items.length} item${items.length == 1 ? '' : 's'}',
//                       style: const TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w600,
//                         letterSpacing: -0.2,
//                       ),
//                     ),
//                   ],
//                 ),
//                 GestureDetector(
//                   onTap: onAddMore,
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 12,
//                       vertical: 7,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.black,
//                       borderRadius: BorderRadius.circular(9),
//                     ),
//                     child: const Row(
//                       children: [
//                         Icon(Icons.add_rounded, color: Colors.white, size: 14),
//                         SizedBox(width: 4),
//                         Text(
//                           'Add More',
//                           style: TextStyle(
//                             fontSize: 12,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const Divider(height: 1, color: Color(0xFFF0F0F0)),
//           ListView.separated(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             itemCount: items.length,
//             separatorBuilder: (context, index) =>
//                 const Divider(height: 1, color: Color(0xFFF5F5F5)),
//             itemBuilder: (context, i) =>
//                 _CartTile(product: items[i], onRemove: () => onRemove(i)),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _CartTile extends StatelessWidget {
//   final ProductModel product;
//   final VoidCallback onRemove;
//   const _CartTile({required this.product, required this.onRemove});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       child: Row(
//         children: [
//           Container(
//             width: 40,
//             height: 40,
//             decoration: BoxDecoration(
//               color: const Color(0xFFF5F5F5),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: const Icon(
//               Icons.inventory_2_outlined,
//               color: Colors.black26,
//               size: 20,
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   product.name,
//                   style: const TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w600,
//                     letterSpacing: -0.2,
//                   ),
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 const SizedBox(height: 3),
//                 Row(
//                   children: [
//                     Text(
//                       '${product.cartQty.toStringAsFixed(0)} × '
//                       '৳${product.cartRate.toStringAsFixed(2)}',
//                       style: const TextStyle(
//                         fontSize: 12,
//                         color: Colors.black45,
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     Text(
//                       '৳${product.cartNetAmount.toStringAsFixed(2)}',
//                       style: const TextStyle(
//                         fontSize: 13,
//                         fontWeight: FontWeight.w600,
//                         color: Color(0xFF4CAF50),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           GestureDetector(
//             onTap: onRemove,
//             child: Container(
//               width: 30,
//               height: 30,
//               decoration: BoxDecoration(
//                 color: const Color(0xFFFFF0F0),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: const Icon(
//                 Icons.close_rounded,
//                 color: Colors.redAccent,
//                 size: 16,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ─── Summary Card ─────────────────────────────────────────────────────────────

// class _SummaryCard extends StatelessWidget {
//   final double subtotal, discount, tax, total;
//   final ValueChanged<double> onDiscountChanged, onTaxChanged;

//   const _SummaryCard({
//     required this.subtotal,
//     required this.discount,
//     required this.tax,
//     required this.total,
//     required this.onDiscountChanged,
//     required this.onTaxChanged,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return _Card(
//       accent: const Color(0xFF4CAF50),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Order Summary',
//               style: TextStyle(
//                 fontSize: 13,
//                 color: Colors.black45,
//                 letterSpacing: 0.2,
//               ),
//             ),
//             const SizedBox(height: 12),
//             _SummaryRow(
//               label: 'Subtotal',
//               value: '৳${subtotal.toStringAsFixed(2)}',
//             ),
//             const SizedBox(height: 12),
//             _EditableRow(
//               label: 'Discount',
//               value: discount,
//               onChanged: onDiscountChanged,
//             ),
//             const SizedBox(height: 12),
//             _EditableRow(label: 'Tax', value: tax, onChanged: onTaxChanged),
//             const Padding(
//               padding: EdgeInsets.symmetric(vertical: 12),
//               child: Divider(height: 1, color: Color(0xFFF0F0F0)),
//             ),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   'Total',
//                   style: TextStyle(
//                     fontSize: 22,
//                     fontWeight: FontWeight.w700,
//                     letterSpacing: -0.5,
//                   ),
//                 ),
//                 Text(
//                   '৳${total.toStringAsFixed(2)}',
//                   style: const TextStyle(
//                     fontSize: 22,
//                     fontWeight: FontWeight.w700,
//                     color: Color(0xFF4CAF50),
//                     letterSpacing: -0.5,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _SummaryRow extends StatelessWidget {
//   final String label, value;
//   const _SummaryRow({required this.label, required this.value});

//   @override
//   Widget build(BuildContext context) => Row(
//     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//     children: [
//       Text(label, style: const TextStyle(fontSize: 15, color: Colors.black45)),
//       Text(
//         value,
//         style: const TextStyle(
//           fontSize: 15,
//           fontWeight: FontWeight.w600,
//           color: Colors.black87,
//         ),
//       ),
//     ],
//   );
// }

// class _EditableRow extends StatelessWidget {
//   final String label;
//   final double value;
//   final ValueChanged<double> onChanged;

//   const _EditableRow({
//     required this.label,
//     required this.value,
//     required this.onChanged,
//   });

//   @override
//   Widget build(BuildContext context) => Row(
//     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//     children: [
//       Text(label, style: const TextStyle(fontSize: 15, color: Colors.black87)),
//       _CurrencyInput(value: value, onChanged: onChanged),
//     ],
//   );
// }

// class _CurrencyInput extends StatefulWidget {
//   final double value;
//   final ValueChanged<double> onChanged;
//   const _CurrencyInput({required this.value, required this.onChanged});

//   @override
//   State<_CurrencyInput> createState() => _CurrencyInputState();
// }

// class _CurrencyInputState extends State<_CurrencyInput> {
//   late final TextEditingController _ctrl;

//   @override
//   void initState() {
//     super.initState();
//     _ctrl = TextEditingController(
//       text: widget.value == 0 ? '0' : widget.value.toString(),
//     );
//   }

//   @override
//   void dispose() {
//     _ctrl.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 110,
//       height: 38,
//       decoration: BoxDecoration(
//         color: const Color(0xFFF5F5F5),
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: const Color(0xFFE0E0E0)),
//       ),
//       child: Row(
//         children: [
//           const SizedBox(
//             width: 32,
//             child: Center(
//               child: Text(
//                 '৳',
//                 style: TextStyle(
//                   fontSize: 15,
//                   color: Colors.black45,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ),
//           ),
//           Expanded(
//             child: TextField(
//               controller: _ctrl,
//               keyboardType: const TextInputType.numberWithOptions(
//                 decimal: true,
//               ),
//               textAlign: TextAlign.center,
//               style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
//               decoration: const InputDecoration(
//                 border: InputBorder.none,
//                 contentPadding: EdgeInsets.zero,
//                 isDense: true,
//               ),
//               onChanged: (v) => widget.onChanged(double.tryParse(v) ?? 0),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ─── Status Dropdown ──────────────────────────────────────────────────────────

// class _StatusDropdown extends StatelessWidget {
//   final String label, value;
//   final List<String> items;
//   final Color accent;
//   final ValueChanged<String?> onChanged;

//   const _StatusDropdown({
//     required this.label,
//     required this.value,
//     required this.items,
//     required this.accent,
//     required this.onChanged,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return _Card(
//       accent: accent,
//       child: Padding(
//         padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               label,
//               style: const TextStyle(
//                 fontSize: 11,
//                 color: Colors.black45,
//                 letterSpacing: 0.2,
//               ),
//             ),
//             const SizedBox(height: 2),
//             DropdownButtonHideUnderline(
//               child: DropdownButton<String>(
//                 value: value,
//                 isDense: true,
//                 isExpanded: true,
//                 icon: const Icon(
//                   Icons.keyboard_arrow_down_rounded,
//                   size: 18,
//                   color: Colors.black45,
//                 ),
//                 style: const TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.black,
//                   letterSpacing: -0.2,
//                 ),
//                 items: items
//                     .map((s) => DropdownMenuItem(value: s, child: Text(s)))
//                     .toList(),
//                 onChanged: onChanged,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ─── Bottom Button ────────────────────────────────────────────────────────────

// class _BottomButton extends StatelessWidget {
//   final String label;
//   final IconData icon;
//   final VoidCallback onTap;
//   final bool enabled;

//   const _BottomButton({
//     required this.label,
//     required this.icon,
//     required this.onTap,
//     this.enabled = true,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       color: const Color(0xFFF5F5F5),
//       padding: EdgeInsets.fromLTRB(
//         24,
//         12,
//         24,
//         12 + MediaQuery.of(context).padding.bottom,
//       ),
//       child: GestureDetector(
//         onTap: enabled ? onTap : null,
//         child: AnimatedContainer(
//           duration: const Duration(milliseconds: 250),
//           curve: Curves.easeInOut,
//           width: double.infinity,
//           height: 52,
//           decoration: BoxDecoration(
//             color: enabled ? Colors.black : Colors.black26,
//             borderRadius: BorderRadius.circular(16),
//             boxShadow: enabled
//                 ? const [
//                     BoxShadow(
//                       color: Color(0x26000000),
//                       blurRadius: 12,
//                       offset: Offset(0, 6),
//                     ),
//                   ]
//                 : [],
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(icon, color: Colors.white, size: 20),
//               const SizedBox(width: 8),
//               Text(
//                 label,
//                 style: const TextStyle(
//                   fontSize: 15,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.white,
//                   letterSpacing: -0.1,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ─── Shared Primitives ────────────────────────────────────────────────────────

// class _Card extends StatelessWidget {
//   final Widget child;
//   final Color? accent;
//   const _Card({required this.child, this.accent});

//   @override
//   Widget build(BuildContext context) => Container(
//     width: double.infinity,
//     decoration: BoxDecoration(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(16),
//       border: accent != null
//           ? Border(left: BorderSide(color: accent!, width: 3))
//           : null,
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

// class _IconBtn extends StatelessWidget {
//   final IconData icon;
//   final VoidCallback onTap;
//   const _IconBtn({required this.icon, required this.onTap});

//   @override
//   Widget build(BuildContext context) => GestureDetector(
//     onTap: onTap,
//     child: Container(
//       width: 38,
//       height: 38,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(10),
//         boxShadow: const [
//           BoxShadow(
//             color: Color(0x0F000000),
//             blurRadius: 8,
//             offset: Offset(0, 3),
//           ),
//         ],
//       ),
//       child: Icon(icon, size: 16, color: Colors.black),
//     ),
//   );
// }
//-----------------------------------------------------------------------
// import 'dart:developer';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:marketing/bloc/customer/customer_provider.dart';
// import 'package:marketing/services/models/products_model.dart';
// import 'package:marketing/services/provider/ordersave_service.dart';
// import 'package:marketing/views/home/subpages/product_list_view.dart';
// import 'package:marketing/views/home/subpages/select_customer.dart';

// class CreateOrderView extends StatefulWidget {
//   const CreateOrderView({super.key});

//   @override
//   State<CreateOrderView> createState() => _CreateOrderViewState();
// }

// class _CreateOrderViewState extends State<CreateOrderView> {
//   final List<ProductModel> _cart = [];
//   final List<File> _attachments = [];

//   double discount = 0;
//   double tax = 0;
//   String orderStatus = 'Pending';
//   bool _isLoading = false;

//   bool _customerSelected = false;
//   int? _selectedPartyId;

//   static const _orderStatuses = [
//     'Pending',
//     'Processing',
//     'Completed',
//     'Cancelled',
//   ];

//   double get _subtotal => _cart.fold(0, (s, p) => s + p.cartNetAmount);
//   double get _total => _subtotal - discount + tax;

//   bool get _canAddProducts => _customerSelected;
//   bool get _canCreateOrder =>
//       _customerSelected && _cart.isNotEmpty && !_isLoading;

//   void _resetForm() {
//     setState(() {
//       _cart.clear();
//       _attachments.clear();
//       discount = 0;
//       tax = 0;
//       orderStatus = 'Pending';
//       _isLoading = false;
//       _customerSelected = false;
//       _selectedPartyId = null;
//     });
//   }

//   // ── Attachment pickers ────────────────────────────────────────────────────
//   Future<void> _pickFromCamera() async {
//     try {
//       final XFile? photo = await ImagePicker().pickImage(
//         source: ImageSource.camera,
//         imageQuality: 80,
//       );
//       if (photo != null) {
//         setState(() => _attachments.add(File(photo.path)));
//         log('Camera photo added: ${photo.path}', name: 'Attachments');
//       }
//     } catch (e) {
//       _showError('Camera error: $e');
//     }
//   }

//   Future<void> _pickFromGallery() async {
//     try {
//       final List<XFile> photos = await ImagePicker().pickMultiImage(
//         imageQuality: 80,
//       );
//       if (photos.isNotEmpty) {
//         setState(() {
//           for (final p in photos) _attachments.add(File(p.path));
//         });
//         log('${photos.length} photo(s) from gallery', name: 'Attachments');
//       }
//     } catch (e) {
//       _showError('Gallery error: $e');
//     }
//   }

//   Future<void> _pickFiles() async {
//     try {
//       final result = await FilePicker.platform.pickFiles(
//         allowMultiple: true,
//         type: FileType.custom,
//         allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
//       );
//       if (result != null && result.files.isNotEmpty) {
//         setState(() {
//           for (final f in result.files) {
//             if (f.path != null) _attachments.add(File(f.path!));
//           }
//         });
//         log('${result.files.length} file(s) added', name: 'Attachments');
//       }
//     } catch (e) {
//       _showError('File picker error: $e');
//     }
//   }

//   void _showAttachmentOptions() {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       builder: (_) => _AttachmentOptionsSheet(
//         onCamera: () {
//           Navigator.pop(context);
//           _pickFromCamera();
//         },
//         onGallery: () {
//           Navigator.pop(context);
//           _pickFromGallery();
//         },
//         onFiles: () {
//           Navigator.pop(context);
//           _pickFiles();
//         },
//       ),
//     );
//   }

//   void _removeAttachment(int index) =>
//       setState(() => _attachments.removeAt(index));

//   void _openSheet() {
//     if (!_canAddProducts) return;
//     AddProductsSheet.show(
//       context,
//       partyId: _selectedPartyId ?? 0,
//       categoryId: 1,
//       onProductAdded: (ProductModel product) {
//         setState(() => _cart.add(product));
//         log(
//           'Added to cart: ${product.name} | '
//           'qty=${product.cartQty} | net=${product.cartNetAmount}',
//           name: 'Cart',
//         );
//       },
//     );
//   }

//   Future<void> _submitOrder() async {
//     if (!_canCreateOrder) return;
//     setState(() => _isLoading = true);

//     try {
//       final response = await OrderSaveService.saveOrder(
//         partyId: _selectedPartyId!,
//         cart: _cart,
//         discount: discount,
//         tax: tax,
//         files: _attachments.isEmpty ? null : _attachments,
//       );

//       if (!mounted) return;

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('✓ ${response.result} (Order ID #${response.orderId})'),
//           backgroundColor: const Color(0xFF4CAF50),
//           behavior: SnackBarBehavior.floating,
//           margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//         ),
//       );

//       _resetForm();
//     } on OrderSaveException catch (e) {
//       if (!mounted) return;
//       _showError(e.message);
//     } catch (e) {
//       if (!mounted) return;
//       _showError('Unexpected error: $e');
//     } finally {
//       if (mounted && _isLoading) setState(() => _isLoading = false);
//     }
//   }

//   void _showError(String msg) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(msg),
//         backgroundColor: Colors.redAccent,
//         behavior: SnackBarBehavior.floating,
//         margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AnnotatedRegion<SystemUiOverlayStyle>(
//       value: SystemUiOverlayStyle.dark,
//       child: Scaffold(
//         backgroundColor: const Color(0xFFF5F5F5),
//         body: SafeArea(
//           child: Column(
//             children: [
//               // ── CHANGED: pass attachment count + callback to header ──────
//               _Header(
//                 attachmentCount: _attachments.length,
//                 onAttachmentTap: _showAttachmentOptions,
//               ),
//               const SizedBox(height: 24),
//               Expanded(
//                 child: SingleChildScrollView(
//                   padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
//                   child: Column(
//                     children: [
//                       BlocProvider(
//                         create: (_) => CustomerBloc()..add(LoadCustomers()),
//                         child: BlocConsumer<CustomerBloc, CustomerState>(
//                           listener: (context, state) {
//                             if (state is CustomerLoaded &&
//                                 state.selectedCustomer != null) {
//                               final selected = state.selectedCustomer!;
//                               setState(() {
//                                 _customerSelected = true;
//                                 _selectedPartyId = selected.accountId;
//                               });
//                               log(
//                                 'Customer: id=${selected.accountId} '
//                                 'name=${selected.aliasName}',
//                                 name: 'CustomerDropdown',
//                               );
//                             } else if (state is CustomerLoaded &&
//                                 state.selectedCustomer == null) {
//                               setState(() {
//                                 _customerSelected = false;
//                                 _selectedPartyId = null;
//                               });
//                             }
//                           },
//                           builder: (context, state) =>
//                               const CustomerDropdownCard(),
//                         ),
//                       ),

//                       const SizedBox(height: 12),

//                       _cart.isEmpty
//                           ? _EmptyCart(
//                               onAdd: _openSheet,
//                               enabled: _canAddProducts,
//                             )
//                           : _CartList(
//                               items: _cart,
//                               onRemove: (i) =>
//                                   setState(() => _cart.removeAt(i)),
//                               onAddMore: _openSheet,
//                             ),

//                       const SizedBox(height: 12),

//                       _SummaryCard(
//                         subtotal: _subtotal,
//                         discount: discount,
//                         tax: tax,
//                         total: _total,
//                         onDiscountChanged: (v) => setState(() => discount = v),
//                         onTaxChanged: (v) => setState(() => tax = v),
//                       ),

//                       const SizedBox(height: 12),

//                       // Attachments card — only shows when there are files
//                       if (_attachments.isNotEmpty)
//                         _AttachmentsCard(
//                           files: _attachments,
//                           onAdd: _showAttachmentOptions,
//                           onRemove: _removeAttachment,
//                         ),

//                       if (_attachments.isNotEmpty) const SizedBox(height: 12),

//                       _StatusDropdown(
//                         label: 'Order Status',
//                         value: orderStatus,
//                         items: _orderStatuses,
//                         accent: const Color(0xFFFFC107),
//                         onChanged: (v) => setState(() => orderStatus = v!),
//                       ),

//                       const SizedBox(height: 16),
//                     ],
//                   ),
//                 ),
//               ),

//               _BottomButton(
//                 label: _isLoading ? 'Creating Order…' : 'Create Order',
//                 icon: _isLoading
//                     ? Icons.hourglass_top_rounded
//                     : Icons.check_rounded,
//                 enabled: _canCreateOrder,
//                 onTap: _submitOrder,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ─── Header — QR button replaced with attachment button ──────────────────────

// class _Header extends StatelessWidget {
//   final int attachmentCount;
//   final VoidCallback onAttachmentTap;

//   const _Header({required this.attachmentCount, required this.onAttachmentTap});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Row(
//             children: [
//               _IconBtn(
//                 icon: Icons.arrow_back_ios_new_rounded,
//                 onTap: () => Navigator.maybePop(context),
//               ),
//               const SizedBox(width: 14),
//               const Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'New Transaction',
//                     style: TextStyle(fontSize: 13, color: Colors.black45),
//                   ),
//                   Text(
//                     'Create Order',
//                     style: TextStyle(
//                       fontSize: 26,
//                       fontWeight: FontWeight.w700,
//                       letterSpacing: -0.5,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),

//           // ── Attachment button replaces the old QR button ───────────────
//           GestureDetector(
//             onTap: onAttachmentTap,
//             child: Stack(
//               clipBehavior: Clip.none,
//               children: [
//                 Container(
//                   width: 44,
//                   height: 44,
//                   decoration: BoxDecoration(
//                     color: Colors.black,
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: const Icon(
//                     Icons.attach_file_rounded,
//                     color: Colors.white,
//                     size: 22,
//                   ),
//                 ),
//                 // Badge — shows count when files are attached
//                 if (attachmentCount > 0)
//                   Positioned(
//                     top: -6,
//                     right: -6,
//                     child: Container(
//                       width: 20,
//                       height: 20,
//                       decoration: const BoxDecoration(
//                         color: Color(0xFF2196F3),
//                         shape: BoxShape.circle,
//                       ),
//                       child: Center(
//                         child: Text(
//                           attachmentCount > 9
//                               ? '9+'
//                               : attachmentCount.toString(),
//                           style: const TextStyle(
//                             fontSize: 11,
//                             fontWeight: FontWeight.w700,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ─── Attachment Options Bottom Sheet ─────────────────────────────────────────

// class _AttachmentOptionsSheet extends StatelessWidget {
//   final VoidCallback onCamera;
//   final VoidCallback onGallery;
//   final VoidCallback onFiles;

//   const _AttachmentOptionsSheet({
//     required this.onCamera,
//     required this.onGallery,
//     required this.onFiles,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: const BoxDecoration(
//         color: Color(0xFFF5F5F5),
//         borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//       ),
//       padding: EdgeInsets.fromLTRB(
//         24,
//         16,
//         24,
//         24 + MediaQuery.of(context).padding.bottom,
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             width: 36,
//             height: 4,
//             margin: const EdgeInsets.only(bottom: 20),
//             decoration: BoxDecoration(
//               color: Colors.black12,
//               borderRadius: BorderRadius.circular(2),
//             ),
//           ),
//           const Align(
//             alignment: Alignment.centerLeft,
//             child: Text(
//               'Add Attachment',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.w700,
//                 letterSpacing: -0.4,
//               ),
//             ),
//           ),
//           const SizedBox(height: 4),
//           const Align(
//             alignment: Alignment.centerLeft,
//             child: Text(
//               'Attach photos or files to this order',
//               style: TextStyle(fontSize: 13, color: Colors.black45),
//             ),
//           ),
//           const SizedBox(height: 20),
//           _OptionTile(
//             icon: Icons.camera_alt_rounded,
//             iconColor: const Color(0xFF2196F3),
//             iconBg: const Color(0xFFE3F2FD),
//             title: 'Take Photo',
//             subtitle: 'Open camera',
//             onTap: onCamera,
//           ),
//           const SizedBox(height: 10),
//           _OptionTile(
//             icon: Icons.photo_library_rounded,
//             iconColor: const Color(0xFF9C27B0),
//             iconBg: const Color(0xFFF3E5F5),
//             title: 'Choose from Gallery',
//             subtitle: 'Select one or more photos',
//             onTap: onGallery,
//           ),
//           const SizedBox(height: 10),
//           _OptionTile(
//             icon: Icons.attach_file_rounded,
//             iconColor: const Color(0xFF4CAF50),
//             iconBg: const Color(0xFFE8F5E9),
//             title: 'Browse Files',
//             subtitle: 'PDF, Word, images',
//             onTap: onFiles,
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _OptionTile extends StatelessWidget {
//   final IconData icon;
//   final Color iconColor;
//   final Color iconBg;
//   final String title;
//   final String subtitle;
//   final VoidCallback onTap;

//   const _OptionTile({
//     required this.icon,
//     required this.iconColor,
//     required this.iconBg,
//     required this.title,
//     required this.subtitle,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(14),
//           boxShadow: const [
//             BoxShadow(
//               color: Color(0x0D000000),
//               blurRadius: 8,
//               offset: Offset(0, 3),
//             ),
//           ],
//         ),
//         child: Row(
//           children: [
//             Container(
//               width: 44,
//               height: 44,
//               decoration: BoxDecoration(
//                 color: iconBg,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Icon(icon, color: iconColor, size: 22),
//             ),
//             const SizedBox(width: 14),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     title,
//                     style: const TextStyle(
//                       fontSize: 15,
//                       fontWeight: FontWeight.w600,
//                       letterSpacing: -0.2,
//                     ),
//                   ),
//                   const SizedBox(height: 2),
//                   Text(
//                     subtitle,
//                     style: const TextStyle(fontSize: 12, color: Colors.black45),
//                   ),
//                 ],
//               ),
//             ),
//             const Icon(
//               Icons.arrow_forward_ios_rounded,
//               size: 14,
//               color: Colors.black26,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ─── Attachments Card — shown in scroll when files exist ─────────────────────

// class _AttachmentsCard extends StatelessWidget {
//   final List<File> files;
//   final VoidCallback onAdd;
//   final ValueChanged<int> onRemove;

//   const _AttachmentsCard({
//     required this.files,
//     required this.onAdd,
//     required this.onRemove,
//   });

//   String _ext(File f) {
//     final parts = f.path.split('/').last.split('.');
//     return parts.length > 1 ? parts.last.toLowerCase() : 'file';
//   }

//   bool _isImage(File f) =>
//       ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'].contains(_ext(f));

//   String _fileName(File f) => f.path.split('/').last;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: const Border(
//           left: BorderSide(color: Color(0xFF2196F3), width: 3),
//         ),
//         boxShadow: const [
//           BoxShadow(
//             color: Color(0x0D000000),
//             blurRadius: 10,
//             offset: Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Row(
//                   children: [
//                     const Icon(
//                       Icons.attach_file_rounded,
//                       size: 18,
//                       color: Colors.black45,
//                     ),
//                     const SizedBox(width: 8),
//                     Text(
//                       'Attachments (${files.length})',
//                       style: const TextStyle(
//                         fontSize: 13,
//                         color: Colors.black45,
//                         letterSpacing: 0.2,
//                       ),
//                     ),
//                   ],
//                 ),
//                 GestureDetector(
//                   onTap: onAdd,
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 12,
//                       vertical: 7,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.black,
//                       borderRadius: BorderRadius.circular(9),
//                     ),
//                     child: const Row(
//                       children: [
//                         Icon(Icons.add_rounded, color: Colors.white, size: 14),
//                         SizedBox(width: 4),
//                         Text(
//                           'Add More',
//                           style: TextStyle(
//                             fontSize: 12,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),

//             const SizedBox(height: 14),

//             // Image thumbnails
//             if (files.any(_isImage)) ...[
//               SizedBox(
//                 height: 90,
//                 child: ListView.builder(
//                   scrollDirection: Axis.horizontal,
//                   itemCount: files.length,
//                   itemBuilder: (_, i) {
//                     final file = files[i];
//                     if (!_isImage(file)) return const SizedBox.shrink();
//                     return Padding(
//                       padding: const EdgeInsets.only(right: 8),
//                       child: Stack(
//                         children: [
//                           ClipRRect(
//                             borderRadius: BorderRadius.circular(10),
//                             child: Image.file(
//                               file,
//                               width: 90,
//                               height: 90,
//                               fit: BoxFit.cover,
//                             ),
//                           ),
//                           Positioned(
//                             top: 4,
//                             right: 4,
//                             child: GestureDetector(
//                               onTap: () => onRemove(i),
//                               child: Container(
//                                 width: 22,
//                                 height: 22,
//                                 decoration: const BoxDecoration(
//                                   color: Colors.black54,
//                                   shape: BoxShape.circle,
//                                 ),
//                                 child: const Icon(
//                                   Icons.close_rounded,
//                                   color: Colors.white,
//                                   size: 13,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     );
//                   },
//                 ),
//               ),
//               const SizedBox(height: 10),
//             ],

//             // Non-image files
//             ...files
//                 .asMap()
//                 .entries
//                 .where((e) => !_isImage(e.value))
//                 .map(
//                   (entry) => Padding(
//                     padding: const EdgeInsets.only(bottom: 8),
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 12,
//                         vertical: 10,
//                       ),
//                       decoration: BoxDecoration(
//                         color: const Color(0xFFF5F5F5),
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       child: Row(
//                         children: [
//                           Container(
//                             width: 36,
//                             height: 36,
//                             decoration: BoxDecoration(
//                               color: Colors.white,
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: Center(
//                               child: Text(
//                                 _ext(entry.value).toUpperCase(),
//                                 style: const TextStyle(
//                                   fontSize: 9,
//                                   fontWeight: FontWeight.w700,
//                                   color: Color(0xFF2196F3),
//                                 ),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 10),
//                           Expanded(
//                             child: Text(
//                               _fileName(entry.value),
//                               style: const TextStyle(
//                                 fontSize: 13,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                           GestureDetector(
//                             onTap: () => onRemove(entry.key),
//                             child: const Icon(
//                               Icons.close_rounded,
//                               size: 18,
//                               color: Colors.redAccent,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ─── Empty Cart ───────────────────────────────────────────────────────────────

// class _EmptyCart extends StatelessWidget {
//   final VoidCallback onAdd;
//   final bool enabled;
//   const _EmptyCart({required this.onAdd, this.enabled = true});

//   @override
//   Widget build(BuildContext context) {
//     return _Card(
//       child: Padding(
//         padding: const EdgeInsets.symmetric(vertical: 36),
//         child: Column(
//           children: [
//             Icon(
//               Icons.shopping_cart_outlined,
//               size: 64,
//               color: Colors.grey.shade300,
//             ),
//             const SizedBox(height: 10),
//             const Text(
//               'Cart is empty',
//               style: TextStyle(
//                 fontSize: 17,
//                 fontWeight: FontWeight.w700,
//                 letterSpacing: -0.3,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               enabled
//                   ? 'Add products to create an order'
//                   : 'Select a customer first',
//               style: TextStyle(
//                 fontSize: 13,
//                 color: enabled ? Colors.black45 : Colors.orangeAccent,
//               ),
//             ),
//             const SizedBox(height: 20),
//             GestureDetector(
//               onTap: enabled ? onAdd : null,
//               child: AnimatedContainer(
//                 duration: const Duration(milliseconds: 250),
//                 curve: Curves.easeInOut,
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 28,
//                   vertical: 13,
//                 ),
//                 decoration: BoxDecoration(
//                   color: enabled ? Colors.black : Colors.black26,
//                   borderRadius: BorderRadius.circular(12),
//                   boxShadow: enabled
//                       ? const [
//                           BoxShadow(
//                             color: Color(0x26000000),
//                             blurRadius: 12,
//                             offset: Offset(0, 6),
//                           ),
//                         ]
//                       : [],
//                 ),
//                 child: const Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(Icons.add_rounded, color: Colors.white, size: 18),
//                     SizedBox(width: 6),
//                     Text(
//                       'Add Products',
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ─── Cart List ────────────────────────────────────────────────────────────────

// class _CartList extends StatelessWidget {
//   final List<ProductModel> items;
//   final ValueChanged<int> onRemove;
//   final VoidCallback onAddMore;

//   const _CartList({
//     required this.items,
//     required this.onRemove,
//     required this.onAddMore,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return _Card(
//       child: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Row(
//                   children: [
//                     const Icon(
//                       Icons.shopping_cart_outlined,
//                       size: 18,
//                       color: Colors.black45,
//                     ),
//                     const SizedBox(width: 8),
//                     Text(
//                       '${items.length} item${items.length == 1 ? '' : 's'}',
//                       style: const TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w600,
//                         letterSpacing: -0.2,
//                       ),
//                     ),
//                   ],
//                 ),
//                 GestureDetector(
//                   onTap: onAddMore,
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 12,
//                       vertical: 7,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.black,
//                       borderRadius: BorderRadius.circular(9),
//                     ),
//                     child: const Row(
//                       children: [
//                         Icon(Icons.add_rounded, color: Colors.white, size: 14),
//                         SizedBox(width: 4),
//                         Text(
//                           'Add More',
//                           style: TextStyle(
//                             fontSize: 12,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const Divider(height: 1, color: Color(0xFFF0F0F0)),
//           ListView.separated(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             itemCount: items.length,
//             separatorBuilder: (context, index) =>
//                 const Divider(height: 1, color: Color(0xFFF5F5F5)),
//             itemBuilder: (context, i) =>
//                 _CartTile(product: items[i], onRemove: () => onRemove(i)),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _CartTile extends StatelessWidget {
//   final ProductModel product;
//   final VoidCallback onRemove;
//   const _CartTile({required this.product, required this.onRemove});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       child: Row(
//         children: [
//           Container(
//             width: 40,
//             height: 40,
//             decoration: BoxDecoration(
//               color: const Color(0xFFF5F5F5),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: const Icon(
//               Icons.inventory_2_outlined,
//               color: Colors.black26,
//               size: 20,
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   product.name,
//                   style: const TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w600,
//                     letterSpacing: -0.2,
//                   ),
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 const SizedBox(height: 3),
//                 Row(
//                   children: [
//                     Text(
//                       '${product.cartQty.toStringAsFixed(0)} × '
//                       '৳${product.cartRate.toStringAsFixed(2)}',
//                       style: const TextStyle(
//                         fontSize: 12,
//                         color: Colors.black45,
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     Text(
//                       '৳${product.cartNetAmount.toStringAsFixed(2)}',
//                       style: const TextStyle(
//                         fontSize: 13,
//                         fontWeight: FontWeight.w600,
//                         color: Color(0xFF4CAF50),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           GestureDetector(
//             onTap: onRemove,
//             child: Container(
//               width: 30,
//               height: 30,
//               decoration: BoxDecoration(
//                 color: const Color(0xFFFFF0F0),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: const Icon(
//                 Icons.close_rounded,
//                 color: Colors.redAccent,
//                 size: 16,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ─── Summary Card ─────────────────────────────────────────────────────────────

// class _SummaryCard extends StatelessWidget {
//   final double subtotal, discount, tax, total;
//   final ValueChanged<double> onDiscountChanged, onTaxChanged;

//   const _SummaryCard({
//     required this.subtotal,
//     required this.discount,
//     required this.tax,
//     required this.total,
//     required this.onDiscountChanged,
//     required this.onTaxChanged,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return _Card(
//       accent: const Color(0xFF4CAF50),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Order Summary',
//               style: TextStyle(
//                 fontSize: 13,
//                 color: Colors.black45,
//                 letterSpacing: 0.2,
//               ),
//             ),
//             const SizedBox(height: 12),
//             _SummaryRow(
//               label: 'Subtotal',
//               value: '৳${subtotal.toStringAsFixed(2)}',
//             ),
//             const SizedBox(height: 12),
//             _EditableRow(
//               label: 'Discount',
//               value: discount,
//               onChanged: onDiscountChanged,
//             ),
//             const SizedBox(height: 12),
//             _EditableRow(label: 'Tax', value: tax, onChanged: onTaxChanged),
//             const Padding(
//               padding: EdgeInsets.symmetric(vertical: 12),
//               child: Divider(height: 1, color: Color(0xFFF0F0F0)),
//             ),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   'Total',
//                   style: TextStyle(
//                     fontSize: 22,
//                     fontWeight: FontWeight.w700,
//                     letterSpacing: -0.5,
//                   ),
//                 ),
//                 Text(
//                   '৳${total.toStringAsFixed(2)}',
//                   style: const TextStyle(
//                     fontSize: 22,
//                     fontWeight: FontWeight.w700,
//                     color: Color(0xFF4CAF50),
//                     letterSpacing: -0.5,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _SummaryRow extends StatelessWidget {
//   final String label, value;
//   const _SummaryRow({required this.label, required this.value});

//   @override
//   Widget build(BuildContext context) => Row(
//     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//     children: [
//       Text(label, style: const TextStyle(fontSize: 15, color: Colors.black45)),
//       Text(
//         value,
//         style: const TextStyle(
//           fontSize: 15,
//           fontWeight: FontWeight.w600,
//           color: Colors.black87,
//         ),
//       ),
//     ],
//   );
// }

// class _EditableRow extends StatelessWidget {
//   final String label;
//   final double value;
//   final ValueChanged<double> onChanged;

//   const _EditableRow({
//     required this.label,
//     required this.value,
//     required this.onChanged,
//   });

//   @override
//   Widget build(BuildContext context) => Row(
//     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//     children: [
//       Text(label, style: const TextStyle(fontSize: 15, color: Colors.black87)),
//       _CurrencyInput(value: value, onChanged: onChanged),
//     ],
//   );
// }

// class _CurrencyInput extends StatefulWidget {
//   final double value;
//   final ValueChanged<double> onChanged;
//   const _CurrencyInput({required this.value, required this.onChanged});

//   @override
//   State<_CurrencyInput> createState() => _CurrencyInputState();
// }

// class _CurrencyInputState extends State<_CurrencyInput> {
//   late final TextEditingController _ctrl;

//   @override
//   void initState() {
//     super.initState();
//     _ctrl = TextEditingController(
//       text: widget.value == 0 ? '0' : widget.value.toString(),
//     );
//   }

//   @override
//   void dispose() {
//     _ctrl.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 110,
//       height: 38,
//       decoration: BoxDecoration(
//         color: const Color(0xFFF5F5F5),
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: const Color(0xFFE0E0E0)),
//       ),
//       child: Row(
//         children: [
//           const SizedBox(
//             width: 32,
//             child: Center(
//               child: Text(
//                 '৳',
//                 style: TextStyle(
//                   fontSize: 15,
//                   color: Colors.black45,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ),
//           ),
//           Expanded(
//             child: TextField(
//               controller: _ctrl,
//               keyboardType: const TextInputType.numberWithOptions(
//                 decimal: true,
//               ),
//               textAlign: TextAlign.center,
//               style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
//               decoration: const InputDecoration(
//                 border: InputBorder.none,
//                 contentPadding: EdgeInsets.zero,
//                 isDense: true,
//               ),
//               onChanged: (v) => widget.onChanged(double.tryParse(v) ?? 0),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ─── Status Dropdown ──────────────────────────────────────────────────────────

// class _StatusDropdown extends StatelessWidget {
//   final String label, value;
//   final List<String> items;
//   final Color accent;
//   final ValueChanged<String?> onChanged;

//   const _StatusDropdown({
//     required this.label,
//     required this.value,
//     required this.items,
//     required this.accent,
//     required this.onChanged,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return _Card(
//       accent: accent,
//       child: Padding(
//         padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               label,
//               style: const TextStyle(
//                 fontSize: 11,
//                 color: Colors.black45,
//                 letterSpacing: 0.2,
//               ),
//             ),
//             const SizedBox(height: 2),
//             DropdownButtonHideUnderline(
//               child: DropdownButton<String>(
//                 value: value,
//                 isDense: true,
//                 isExpanded: true,
//                 icon: const Icon(
//                   Icons.keyboard_arrow_down_rounded,
//                   size: 18,
//                   color: Colors.black45,
//                 ),
//                 style: const TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.black,
//                   letterSpacing: -0.2,
//                 ),
//                 items: items
//                     .map((s) => DropdownMenuItem(value: s, child: Text(s)))
//                     .toList(),
//                 onChanged: onChanged,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ─── Bottom Button ────────────────────────────────────────────────────────────

// class _BottomButton extends StatelessWidget {
//   final String label;
//   final IconData icon;
//   final VoidCallback onTap;
//   final bool enabled;

//   const _BottomButton({
//     required this.label,
//     required this.icon,
//     required this.onTap,
//     this.enabled = true,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       color: const Color(0xFFF5F5F5),
//       padding: EdgeInsets.fromLTRB(
//         24,
//         12,
//         24,
//         12 + MediaQuery.of(context).padding.bottom,
//       ),
//       child: GestureDetector(
//         onTap: enabled ? onTap : null,
//         child: AnimatedContainer(
//           duration: const Duration(milliseconds: 250),
//           curve: Curves.easeInOut,
//           width: double.infinity,
//           height: 52,
//           decoration: BoxDecoration(
//             color: enabled ? Colors.black : Colors.black26,
//             borderRadius: BorderRadius.circular(16),
//             boxShadow: enabled
//                 ? const [
//                     BoxShadow(
//                       color: Color(0x26000000),
//                       blurRadius: 12,
//                       offset: Offset(0, 6),
//                     ),
//                   ]
//                 : [],
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(icon, color: Colors.white, size: 20),
//               const SizedBox(width: 8),
//               Text(
//                 label,
//                 style: const TextStyle(
//                   fontSize: 15,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.white,
//                   letterSpacing: -0.1,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ─── Shared Primitives ────────────────────────────────────────────────────────

// class _Card extends StatelessWidget {
//   final Widget child;
//   final Color? accent;
//   const _Card({required this.child, this.accent});

//   @override
//   Widget build(BuildContext context) => Container(
//     width: double.infinity,
//     decoration: BoxDecoration(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(16),
//       border: accent != null
//           ? Border(left: BorderSide(color: accent!, width: 3))
//           : null,
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

// class _IconBtn extends StatelessWidget {
//   final IconData icon;
//   final VoidCallback onTap;
//   const _IconBtn({required this.icon, required this.onTap});

//   @override
//   Widget build(BuildContext context) => GestureDetector(
//     onTap: onTap,
//     child: Container(
//       width: 38,
//       height: 38,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(10),
//         boxShadow: const [
//           BoxShadow(
//             color: Color(0x0F000000),
//             blurRadius: 8,
//             offset: Offset(0, 3),
//           ),
//         ],
//       ),
//       child: Icon(icon, size: 16, color: Colors.black),
//     ),
//   );
// }
