// import 'dart:convert';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:http/http.dart' as http;
// import 'package:marketing/constants/api_values.dart';
// import 'package:marketing/services/provider/current_user.dart'; // Update path if needed

// // ─── Events ───────────────────────────────────────────────────────────────────
// abstract class OrderApprovalEvent {}

// class ConfirmOrderApproval extends OrderApprovalEvent {
//   final int orderId;
//   ConfirmOrderApproval(this.orderId);
// }

// // ─── States ───────────────────────────────────────────────────────────────────
// abstract class OrderApprovalState {}

// class OrderApprovalInitial extends OrderApprovalState {}

// class OrderApprovalLoading extends OrderApprovalState {}

// class OrderApprovalSuccess extends OrderApprovalState {
//   final String message;
//   OrderApprovalSuccess(this.message);
// }

// class OrderApprovalFailure extends OrderApprovalState {
//   final String error;
//   OrderApprovalFailure(this.error);
// }

// // ─── BLoC ─────────────────────────────────────────────────────────────────────
// class OrderApprovalBloc extends Bloc<OrderApprovalEvent, OrderApprovalState> {
//   OrderApprovalBloc() : super(OrderApprovalInitial()) {
//     on<ConfirmOrderApproval>(_onConfirmOrderApproval);
//   }

//   Future<void> _onConfirmOrderApproval(
//     ConfirmOrderApproval event,
//     Emitter<OrderApprovalState> emit,
//   ) async {
//     emit(OrderApprovalLoading());
//     try {
//       final uri = Uri.parse(
//         '${BaseUrl.apiBase}/api/${V.v1}/Order/SaveOrderApproval'
//         '?CompId=${CurrentUser.compId}&OrderId=${event.orderId}&Status=1',
//       );

//       final response = await http.post(
//         uri,
//         headers: {
//           'accept': '*/*',
//           'Authorization': 'Bearer ${CurrentUser.token}',
//           'content-type': 'application/json',
//         },
//       );

//       if (response.statusCode == 200) {
//         // API returns plain `true` or `false` as the body
//         final rawBody = response.body.trim().toLowerCase();
//         if (rawBody == 'true') {
//           emit(OrderApprovalSuccess('Order confirmed successfully!'));
//         } else {
//           // 200 but body is `false` — treat as a business-logic failure
//           emit(
//             OrderApprovalFailure(
//               'Order approval was not successful. Please try again.',
//             ),
//           );
//         }
//       } else {
//         // Non-200 HTTP error
//         emit(
//           OrderApprovalFailure(
//             'Server error (${response.statusCode}). Please try again.',
//           ),
//         );
//       }
//     } catch (e) {
//       emit(OrderApprovalFailure('Network error: ${e.toString()}'));
//     }
//   }
// }

import 'dart:convert';
import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:marketing/constants/api_values.dart';
import 'package:marketing/services/provider/current_user.dart'; // Update path if needed

// ─── Events ───────────────────────────────────────────────────────────────────
abstract class OrderApprovalEvent {}

/// Fired by both the "Approve" and "Reject" buttons — only `status` differs
/// between them (e.g. 1 = approve, -3 = reject). Keeping one event instead
/// of two means the Bloc/repository logic doesn't have to be duplicated;
/// only the button's onTap needs to know which status it sends.
class ConfirmOrderApproval extends OrderApprovalEvent {
  final int orderId;
  final int status;

  ConfirmOrderApproval(this.orderId, {required this.status});
}

// ─── States ───────────────────────────────────────────────────────────────────
abstract class OrderApprovalState {}

class OrderApprovalInitial extends OrderApprovalState {}

class OrderApprovalLoading extends OrderApprovalState {}

class OrderApprovalSuccess extends OrderApprovalState {
  final String message;
  OrderApprovalSuccess(this.message);
}

class OrderApprovalFailure extends OrderApprovalState {
  final String error;
  OrderApprovalFailure(this.error);
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────
class OrderApprovalBloc extends Bloc<OrderApprovalEvent, OrderApprovalState> {
  OrderApprovalBloc() : super(OrderApprovalInitial()) {
    on<ConfirmOrderApproval>(_onConfirmOrderApproval);
  }

  Future<void> _onConfirmOrderApproval(
    ConfirmOrderApproval event,
    Emitter<OrderApprovalState> emit,
  ) async {
    emit(OrderApprovalLoading());
    try {
      final uri = Uri.parse(
        '${BaseUrl.apiBase}/api/${V.v1}/Order/SaveOrderApproval'
        '?CompId=${CurrentUser.compId}&OrderId=${event.orderId}&Status=${event.status}',
      );

      final response = await http.post(
        uri,
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer ${CurrentUser.token}',
          'content-type': 'application/json',
        },
      );
      log(name: 'SaveOrderApproval', uri.toString());
      if (response.statusCode == 200) {
        // API returns plain `true` or `false` as the body
        final rawBody = response.body.trim().toLowerCase();
        if (rawBody == 'true') {
          // Message reflects which action was actually sent, since the
          // same event now covers both approve (1) and reject (-3).
          final message = event.status == 1
              ? 'Order confirmed successfully!'
              : 'Order rejected successfully!';
          emit(OrderApprovalSuccess(message));
        } else {
          // 200 but body is `false` — treat as a business-logic failure
          emit(
            OrderApprovalFailure(
              'Order approval was not successful. Please try again.',
            ),
          );
        }
      } else {
        // Non-200 HTTP error
        emit(
          OrderApprovalFailure(
            'Server error (${response.statusCode}). Please try again.',
          ),
        );
      }
    } catch (e) {
      emit(OrderApprovalFailure('Network error: ${e.toString()}'));
    }
  }
}
