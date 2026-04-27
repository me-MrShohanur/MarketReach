// lib/bloc/order/order_detail_provider.dart

import 'dart:convert';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:marketing/services/provider/current_user.dart';

// ─── Detail Item Model ────────────────────────────────────────────────────────

class OrderDetailItem {
  final int id;
  final int orderId;
  final int productId;
  final String? productDesc;
  final int unitId;
  final int unitQty;
  final double unitPrice;
  final double discountAmt;
  final double vat;
  final double netAmount;
  final int branchId;
  final int compId;
  final int uniqueQty;
  final int productTypeId;
  final int sizeId;
  final String? remarks;
  final String? custRef;

  const OrderDetailItem({
    required this.id,
    required this.orderId,
    required this.productId,
    this.productDesc,
    required this.unitId,
    required this.unitQty,
    required this.unitPrice,
    required this.discountAmt,
    required this.vat,
    required this.netAmount,
    required this.branchId,
    required this.compId,
    required this.uniqueQty,
    required this.productTypeId,
    required this.sizeId,
    this.remarks,
    this.custRef,
  });

  factory OrderDetailItem.fromJson(Map<String, dynamic> j) => OrderDetailItem(
    id: j['id'] ?? 0,
    orderId: j['orderId'] ?? 0,
    productId: j['productId'] ?? 0,
    productDesc: j['productDesc'],
    unitId: j['unitId'] ?? 0,
    unitQty: (j['unitQty'] ?? 0).toInt(),
    unitPrice: (j['unitPrice'] ?? 0).toDouble(),
    discountAmt: (j['discountAmt'] ?? 0).toDouble(),
    vat: (j['vat'] ?? 0).toDouble(),
    netAmount: (j['netAmount'] ?? 0).toDouble(),
    branchId: j['branchId'] ?? 0,
    compId: j['compId'] ?? 0,
    uniqueQty: (j['uniqueQty'] ?? 0).toInt(),
    productTypeId: j['productTypeId'] ?? 0,
    sizeId: j['sizeId'] ?? 0,
    remarks: j['remarks'],
    custRef: j['custRef'],
  );
}

// ─── Master Model ─────────────────────────────────────────────────────────────

class OrderDetailMaster {
  final int id;
  final int orderId;
  final String orderNo;
  final int partyId;
  final String? partyName;
  final String orderDate;
  final int orderType;
  final double paidAmount;
  final double netPayable;
  final double netAmount;
  final double discountAmount;
  final double discountRate;
  final double vatAmount;
  final double vatRate;
  final double otherAddition;
  final double otherDeduction;
  final double deposite;
  final double currencyRate;
  final int status;
  final String? statusName;
  final String? billTo;
  final String? billAddress;
  final String? billContactNo;
  final String? paymentType;
  final String? narration;
  final String? refNo;
  final int branchId;
  final int compId;
  final List<OrderDetailItem> details;

  const OrderDetailMaster({
    required this.id,
    required this.orderId,
    required this.orderNo,
    required this.partyId,
    this.partyName,
    required this.orderDate,
    required this.orderType,
    required this.paidAmount,
    required this.netPayable,
    required this.netAmount,
    required this.discountAmount,
    required this.discountRate,
    required this.vatAmount,
    required this.vatRate,
    required this.otherAddition,
    required this.otherDeduction,
    required this.deposite,
    required this.currencyRate,
    required this.status,
    this.statusName,
    this.billTo,
    this.billAddress,
    this.billContactNo,
    this.paymentType,
    this.narration,
    this.refNo,
    required this.branchId,
    required this.compId,
    required this.details,
  });

  factory OrderDetailMaster.fromJson(Map<String, dynamic> j) {
    final rawDetails = j['details'] as List? ?? [];
    return OrderDetailMaster(
      id: j['id'] ?? 0,
      orderId: j['orderId'] ?? 0,
      orderNo: j['orderNo'] ?? '',
      partyId: j['partyId'] ?? 0,
      partyName: j['partyName'],
      orderDate: j['orderDate']?.toString() ?? '',
      orderType: j['orderType'] ?? 0,
      paidAmount: (j['paidAmount'] ?? 0).toDouble(),
      netPayable: (j['netPayable'] ?? 0).toDouble(),
      netAmount: (j['netAmount'] ?? 0).toDouble(),
      discountAmount: (j['discountAmount'] ?? 0).toDouble(),
      discountRate: (j['discountRate'] ?? 0).toDouble(),
      vatAmount: (j['vatAmount'] ?? 0).toDouble(),
      vatRate: (j['vatRate'] ?? 0).toDouble(),
      otherAddition: (j['otherAddition'] ?? 0).toDouble(),
      otherDeduction: (j['otherDeduction'] ?? 0).toDouble(),
      deposite: (j['deposite'] ?? 0).toDouble(),
      currencyRate: (j['currencyRate'] ?? 0).toDouble(),
      status: j['status'] ?? 0,
      statusName: j['statusName'],
      billTo: j['billTo'],
      billAddress: j['billAddress'],
      billContactNo: j['billContactNo'],
      paymentType: j['paymentType'],
      narration: j['narration'],
      refNo: j['refNo'],
      branchId: j['branchId'] ?? 0,
      compId: j['compId'] ?? 0,
      details: rawDetails
          .map((e) => OrderDetailItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Formats "20260401" → "01 Apr 2026"
  String get formattedDate {
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
    try {
      final digits = orderDate.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length < 8) return orderDate;
      final y = digits.substring(0, 4);
      final m = int.tryParse(digits.substring(4, 6)) ?? 1;
      final d = digits.substring(6, 8);
      if (m < 1 || m > 12) return orderDate;
      return '$d ${months[m]} $y';
    } catch (_) {
      return orderDate;
    }
  }
}

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class OrderDetailEvent {}

class LoadOrderDetail extends OrderDetailEvent {
  final int id;
  LoadOrderDetail(this.id);
}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class OrderDetailState {}

class OrderDetailInitial extends OrderDetailState {}

class OrderDetailLoading extends OrderDetailState {}

class OrderDetailLoaded extends OrderDetailState {
  final OrderDetailMaster order;
  OrderDetailLoaded(this.order);
}

class OrderDetailError extends OrderDetailState {
  final String message;
  OrderDetailError(this.message);
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────

class OrderDetailBloc extends Bloc<OrderDetailEvent, OrderDetailState> {
  static const _base =
      'http://103.125.253.59:1122/api/v1/Order/GetOrderDetails';

  OrderDetailBloc() : super(OrderDetailInitial()) {
    on<LoadOrderDetail>(_fetch);
  }

  Future<void> _fetch(
    LoadOrderDetail event,
    Emitter<OrderDetailState> emit,
  ) async {
    emit(OrderDetailLoading());
    try {
      final uri = Uri.parse(
        '$_base?id=${event.id}&compId=${CurrentUser.compId}',
      );

      log('Fetching detail | id=${event.id}', name: 'OrderDetailBloc');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer ${CurrentUser.customerID}',
          'accept': '*/*',
        },
      );

      log('Response [${response.statusCode}]', name: 'OrderDetailBloc');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['status'] == true) {
          // Response shape: { status, result: { result: {...}, ... } }
          final inner = json['result']['result'] as Map<String, dynamic>;
          emit(OrderDetailLoaded(OrderDetailMaster.fromJson(inner)));
        } else {
          emit(OrderDetailError('Server returned status false'));
        }
      } else {
        emit(OrderDetailError('Failed [${response.statusCode}]'));
      }
    } catch (e) {
      log('Error: $e', name: 'OrderDetailBloc');
      emit(OrderDetailError(e.toString()));
    }
  }
}
