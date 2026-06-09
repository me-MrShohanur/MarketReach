// lib/bloc/order/update_challan_provider.dart

import 'dart:convert';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:marketing/services/provider/current_user.dart';

// ─── Request Model ────────────────────────────────────────────────────────────

class UpdateChallanRequest {
  final int id; // detail row id
  final int challanId; // challan id
  final int qty; // updated qty
  final String notes; // notes / remarks
  final DateTime returnDate;

  const UpdateChallanRequest({
    required this.id,
    required this.challanId,
    required this.qty,
    required this.notes,
    required this.returnDate,
  });

  /// Formats DateTime → "yyyyMMdd"  e.g. "20260705"
  static String _fmtDate(DateTime d) =>
      '${d.year}'
      '${d.month.toString().padLeft(2, '0')}'
      '${d.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {
    'id': id,
    'compId': CurrentUser.compId, // always from CurrentUser
    'challanId': challanId,
    'qty': qty,
    'notes': notes,
    'returnDate': _fmtDate(returnDate),
  };
}

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class UpdateChallanEvent {}

class SubmitUpdateChallan extends UpdateChallanEvent {
  final UpdateChallanRequest request;
  SubmitUpdateChallan(this.request);
}

class ResetUpdateChallan extends UpdateChallanEvent {}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class UpdateChallanState {}

class UpdateChallanInitial extends UpdateChallanState {}

class UpdateChallanLoading extends UpdateChallanState {}

class UpdateChallanSuccess extends UpdateChallanState {
  final String message;
  UpdateChallanSuccess(this.message);
}

class UpdateChallanFailure extends UpdateChallanState {
  final String error;
  UpdateChallanFailure(this.error);
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────

class UpdateChallanBloc extends Bloc<UpdateChallanEvent, UpdateChallanState> {
  static const _url =
      'http://103.125.253.59:1122/api/v1/Order/UpdateChallanDeatails';

  UpdateChallanBloc() : super(UpdateChallanInitial()) {
    on<SubmitUpdateChallan>(_onSubmit);
    on<ResetUpdateChallan>((_, emit) => emit(UpdateChallanInitial()));
  }

  Future<void> _onSubmit(
    SubmitUpdateChallan event,
    Emitter<UpdateChallanState> emit,
  ) async {
    emit(UpdateChallanLoading());

    final body = jsonEncode(event.request.toJson());

    // ── Full request log ───────────────────────────────────────────────────
    log('━━━━ UPDATE CHALLAN REQUEST ━━━━', name: 'UpdateChallanBloc');
    log('URL      : $_url', name: 'UpdateChallanBloc');
    log('compId   : ${CurrentUser.compId}', name: 'UpdateChallanBloc');
    log('id       : ${event.request.id}', name: 'UpdateChallanBloc');
    log('challanId: ${event.request.challanId}', name: 'UpdateChallanBloc');
    log('qty      : ${event.request.qty}', name: 'UpdateChallanBloc');
    log('notes    : ${event.request.notes}', name: 'UpdateChallanBloc');
    log(
      'returnDate: ${UpdateChallanRequest._fmtDate(event.request.returnDate)}',
      name: 'UpdateChallanBloc',
    );
    log('body     : $body', name: 'UpdateChallanBloc');
    log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'UpdateChallanBloc');

    try {
      final response = await http
          .post(
            Uri.parse(_url),
            headers: {
              'accept': '*/*',
              'Authorization': 'Bearer ${CurrentUser.token}',
              'Content-Type': 'application/json',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      log(
        'Response [${response.statusCode}]: ${response.body}',
        name: 'UpdateChallanBloc',
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['status'] == true) {
          emit(UpdateChallanSuccess('Challan updated successfully.'));
        } else {
          emit(
            UpdateChallanFailure(
              json['message']?.toString() ?? 'Server returned status false',
            ),
          );
        }
      } else if (response.statusCode == 400) {
        // Parse ASP.NET validation errors
        String readable = 'Validation error';
        try {
          final err = jsonDecode(response.body) as Map<String, dynamic>;
          if (err.containsKey('errors')) {
            final errors = err['errors'] as Map<String, dynamic>;
            readable = errors.entries
                .map((e) => '${e.key}: ${(e.value as List).first}')
                .join('\n');
          } else if (err.containsKey('title')) {
            readable = err['title'] as String;
          }
        } catch (_) {
          readable = response.body;
        }
        emit(UpdateChallanFailure(readable));
      } else if (response.statusCode == 401) {
        emit(UpdateChallanFailure('Session expired. Please login again.'));
      } else {
        emit(
          UpdateChallanFailure(
            'Failed [${response.statusCode}]: ${response.body}',
          ),
        );
      }
    } catch (e) {
      log('Error: $e', name: 'UpdateChallanBloc');
      emit(UpdateChallanFailure('Network error: $e'));
    }
  }
}
