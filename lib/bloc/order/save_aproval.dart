import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:marketing/services/provider/current_user.dart'; // Update path if needed

// ─── Events ───────────────────────────────────────────────────────────────────
abstract class OrderApprovalEvent {}

class ConfirmOrderApproval extends OrderApprovalEvent {
  final int orderId;
  ConfirmOrderApproval(this.orderId);
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
        'http://103.125.253.59:1122/api/v1/Order/SaveOrderApproval'
        '?CompId=${CurrentUser.compId}&OrderId=${event.orderId}',
      );

      final response = await http.post(
        uri,
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer ${CurrentUser.token}',
        },
      );

      if (response.statusCode == 200) {
        // API returns plain `true` or `false` as the body
        final rawBody = response.body.trim().toLowerCase();
        if (rawBody == 'true') {
          emit(OrderApprovalSuccess('Order confirmed successfully!'));
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
