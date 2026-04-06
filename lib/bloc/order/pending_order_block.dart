// lib/bloc/order/pending_order_block.dart

import 'dart:convert';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:marketing/constants/api_values.dart';
import 'package:marketing/services/provider/current_user.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class OrderListItem {
  final int id;
  final int orderId;
  final String orderNo;
  final int partyId;
  final String partyName;
  final String orderDate;
  final int orderType;
  final double paidAmount;
  final double netPayable;
  final int status;
  final String statusName;
  final double balance;

  const OrderListItem({
    required this.id,
    required this.orderId,
    required this.orderNo,
    required this.partyId,
    required this.partyName,
    required this.orderDate,
    required this.orderType,
    required this.paidAmount,
    required this.netPayable,
    required this.status,
    required this.statusName,
    required this.balance,
  });

  factory OrderListItem.fromJson(Map<String, dynamic> j) => OrderListItem(
    id: j['id'] ?? 0,
    orderId: j['orderId'] ?? 0,
    orderNo: j['orderNo'] ?? '',
    partyId: j['partyId'] ?? 0,
    partyName: j['partyName'] ?? '',
    orderDate: j['orderDate']?.toString() ?? '',
    orderType: j['orderType'] ?? 0,
    paidAmount: (j['paidAmount'] ?? 0).toDouble(),
    netPayable: (j['netPayable'] ?? 0).toDouble(),
    status: j['status'] ?? 0,
    statusName: j['statusName'] ?? 'Pending',
    balance: (j['balance'] ?? 0).toDouble(),
  );

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

abstract class OrderListEvent {}

class LoadOrderList extends OrderListEvent {
  final String fromDate;
  final String toDate;
  final List<int> statusFilter;

  LoadOrderList({
    required this.fromDate,
    required this.toDate,
    this.statusFilter = const [],
  });
}

class PreloadOrderList extends OrderListEvent {
  final List<OrderListItem> orders;
  final List<int> statusFilter;

  PreloadOrderList({required this.orders, this.statusFilter = const []});
}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class OrderListState {}

class OrderListInitial extends OrderListState {}

class OrderListLoading extends OrderListState {}

class OrderListLoaded extends OrderListState {
  final List<OrderListItem> orders;
  OrderListLoaded(this.orders);
}

class OrderListError extends OrderListState {
  final String message;
  OrderListError(this.message);
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────

class OrderListBloc extends Bloc<OrderListEvent, OrderListState> {
  static const _url = '${BaseUrl.apiBase}/api/${V.v1}/${EndPoint.getOrderList}';

  OrderListBloc() : super(OrderListInitial()) {
    on<LoadOrderList>(_fetch);
    on<PreloadOrderList>(_preload);
  }

  // Instantly emit already-fetched data — no API call
  void _preload(PreloadOrderList event, Emitter<OrderListState> emit) {
    var list = event.orders;
    if (event.statusFilter.isNotEmpty) {
      list = list.where((o) => event.statusFilter.contains(o.status)).toList();
    }
    emit(OrderListLoaded(list));
  }

  Future<void> _fetch(LoadOrderList event, Emitter<OrderListState> emit) async {
    emit(OrderListLoading());
    try {
      final body = jsonEncode({
        'fromDate': event.fromDate,
        'toDate': event.toDate,
        'compId': CurrentUser.compId,
        'userID': CurrentUser.userId,
        'partyId': 0,
        'orderType': 7,
      });

      log(
        'Fetching orders | from=${event.fromDate} to=${event.toDate} '
        'filter=${event.statusFilter}',
        name: 'OrderListBloc',
      );

      final response = await http.post(
        Uri.parse(_url),
        headers: {
          'Authorization': 'Bearer ${CurrentUser.token}',
          'Content-Type': 'application/json',
          'accept': '*/*',
        },
        body: body,
      );

      log(
        'Response [${response.statusCode}]: ${response.body.length} chars',
        name: 'OrderListBloc',
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['status'] == true) {
          var list = (json['result'] as List)
              .map((e) => OrderListItem.fromJson(e as Map<String, dynamic>))
              .toList();

          if (event.statusFilter.isNotEmpty) {
            list = list
                .where((o) => event.statusFilter.contains(o.status))
                .toList();
          }

          log('After filter: ${list.length} orders', name: 'OrderListBloc');
          emit(OrderListLoaded(list));
        } else {
          emit(OrderListError('Server returned status false'));
        }
      } else {
        emit(OrderListError('Failed [${response.statusCode}]'));
      }
    } catch (e) {
      log('Error: $e', name: 'OrderListBloc');
      emit(OrderListError(e.toString()));
    }
  }
}

// // lib/bloc/order/order_list_provider.dart

// import 'dart:convert';
// import 'dart:developer';

// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:http/http.dart' as http;

// import 'package:marketing/constants/api_values.dart';
// import 'package:marketing/services/provider/current_user.dart';

// // ─── Model ────────────────────────────────────────────────────────────────────

// class OrderListItem {
//   final int id;
//   final int orderId;
//   final String orderNo;
//   final int partyId;
//   final String partyName;
//   final String orderDate;
//   final int orderType;
//   final double paidAmount;
//   final double netPayable;
//   final int status;
//   final String statusName;
//   final double balance;

//   const OrderListItem({
//     required this.id,
//     required this.orderId,
//     required this.orderNo,
//     required this.partyId,
//     required this.partyName,
//     required this.orderDate,
//     required this.orderType,
//     required this.paidAmount,
//     required this.netPayable,
//     required this.status,
//     required this.statusName,
//     required this.balance,
//   });

//   factory OrderListItem.fromJson(Map<String, dynamic> j) => OrderListItem(
//     id: j['id'] ?? 0,
//     orderId: j['orderId'] ?? 0,
//     orderNo: j['orderNo'] ?? '',
//     partyId: j['partyId'] ?? 0,
//     partyName: j['partyName'] ?? '',
//     orderDate: j['orderDate']?.toString() ?? '',
//     orderType: j['orderType'] ?? 0,
//     paidAmount: (j['paidAmount'] ?? 0).toDouble(),
//     netPayable: (j['netPayable'] ?? 0).toDouble(),
//     status: j['status'] ?? 0,
//     statusName: j['statusName'] ?? 'Pending',
//     balance: (j['balance'] ?? 0).toDouble(),
//   );

//   /// Formats various date formats → "01 Apr 2026"
//   /// Handles: "20260401", "2026-04-01", "2026/04/01"
//   String get formattedDate {
//     const months = [
//       '',
//       'Jan',
//       'Feb',
//       'Mar',
//       'Apr',
//       'May',
//       'Jun',
//       'Jul',
//       'Aug',
//       'Sep',
//       'Oct',
//       'Nov',
//       'Dec',
//     ];
//     try {
//       // Strip any separators so we always work with digits only
//       final digits = orderDate.replaceAll(RegExp(r'[^0-9]'), '');
//       if (digits.length < 8) return orderDate;
//       final y = digits.substring(0, 4);
//       final m = int.tryParse(digits.substring(4, 6)) ?? 1;
//       final d = digits.substring(6, 8);
//       if (m < 1 || m > 12) return orderDate; // safety guard
//       return '$d ${months[m]} $y';
//     } catch (_) {
//       return orderDate; // fallback to raw string
//     }
//   }
// }

// // ─── Events ───────────────────────────────────────────────────────────────────

// abstract class OrderListEvent {}

// class LoadOrderList extends OrderListEvent {
//   final String fromDate; // "yyyyMMdd"
//   final String toDate; // "yyyyMMdd"

//   LoadOrderList({required this.fromDate, required this.toDate});
// }

// class RefreshOrderList extends OrderListEvent {
//   final String fromDate;
//   final String toDate;
//   RefreshOrderList({required this.fromDate, required this.toDate});
// }

// // ─── States ───────────────────────────────────────────────────────────────────

// abstract class OrderListState {}

// class OrderListInitial extends OrderListState {}

// class OrderListLoading extends OrderListState {}

// class OrderListLoaded extends OrderListState {
//   final List<OrderListItem> orders;
//   OrderListLoaded(this.orders);
// }

// class OrderListError extends OrderListState {
//   final String message;
//   OrderListError(this.message);
// }

// // ─── BLoC ─────────────────────────────────────────────────────────────────────

// class OrderListBloc extends Bloc<OrderListEvent, OrderListState> {
//   static const _url = '${BaseUrl.apiBase}/api/${V.v1}/${EndPoint.getOrderList}';

//   OrderListBloc() : super(OrderListInitial()) {
//     on<LoadOrderList>(_fetch);
//     on<RefreshOrderList>(
//       (e, emit) =>
//           _fetch(LoadOrderList(fromDate: e.fromDate, toDate: e.toDate), emit),
//     );
//   }

//   Future<void> _fetch(LoadOrderList event, Emitter<OrderListState> emit) async {
//     emit(OrderListLoading());
//     try {
//       final body = jsonEncode({
//         'fromDate': event.fromDate,
//         'toDate': event.toDate,
//         'compId': CurrentUser.compId,
//         'userID': CurrentUser.userId,
//         'partyId': 0,
//         'orderType': 7,
//       });

//       log(
//         'Fetching orders | from=${event.fromDate} to=${event.toDate}',
//         name: 'OrderListBloc',
//       );

//       final response = await http.post(
//         Uri.parse(_url),
//         headers: {
//           'Authorization': 'Bearer ${CurrentUser.token}',
//           'Content-Type': 'application/json',
//           'accept': '*/*',
//         },
//         body: body,
//       );

//       log(
//         'Response [${response.statusCode}]: ${response.body.length}',
//         name: 'OrderListBloc',
//       );

//       if (response.statusCode == 200) {
//         log(name: EndPoint.getOrderList, _url);
//         log('Request body: $body', name: 'OrderListBloc');
//         final json = jsonDecode(response.body) as Map<String, dynamic>;
//         if (json['status'] == true) {
//           final list = (json['result'] as List)
//               .map((e) => OrderListItem.fromJson(e as Map<String, dynamic>))
//               .toList();
//           emit(OrderListLoaded(list));
//         } else {
//           emit(OrderListError('Server returned status false'));
//         }
//       } else {
//         emit(OrderListError('Failed [${response.statusCode}]'));
//       }
//     } catch (e) {
//       log('Error: $e', name: 'OrderListBloc');
//       emit(OrderListError(e.toString()));
//     }
//   }
// }
