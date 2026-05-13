// lib/bloc/report/report_bloc.dart

import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marketing/services/models/report_model.dart';
import 'package:marketing/services/provider/current_user.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class ReportEvent {}

class LoadReport extends ReportEvent {
  final ReportParams params;
  LoadReport(this.params);
}

class ChangeReportDates extends ReportEvent {
  final DateTime startDate;
  final DateTime endDate;
  ChangeReportDates({required this.startDate, required this.endDate});
}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class ReportState {}

class ReportInitial extends ReportState {}

class ReportLoading extends ReportState {
  final ReportParams params;
  ReportLoading(this.params);
}

class ReportReady extends ReportState {
  final Uri reportUri;
  final ReportParams params;
  ReportReady({required this.reportUri, required this.params});
}

class ReportError extends ReportState {
  final String message;
  final ReportParams? params;
  ReportError(this.message, {this.params});
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────

class ReportBloc extends Bloc<ReportEvent, ReportState> {
  ReportBloc() : super(ReportInitial()) {
    on<LoadReport>(_onLoad);
    on<ChangeReportDates>(_onChangeDates);
  }

  ReportParams _lastParams = ReportParams(
    startDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
    endDate: DateTime.now(),
  );

  Future<void> _onLoad(LoadReport event, Emitter<ReportState> emit) async {
    _lastParams = event.params;
    emit(ReportLoading(event.params));
    try {
      final Uri uri = event.params.buildUri();
      log('ReportId   : ${event.params.reportId}', name: 'ReportBloc');
      log('StartDate  : ${event.params.startDate}', name: 'ReportBloc');
      log('EndDate    : ${event.params.endDate}', name: 'ReportBloc');
      log('LedgerId   : ${CurrentUser.customerID}', name: 'ReportBloc');
      log('AccountId  : ${event.params.accountId}', name: 'ReportBloc');
      log('CompId     : ${CurrentUser.compId}', name: 'ReportBloc');
      log('BranchId   : ${CurrentUser.branchId}', name: 'ReportBloc');
      log('Full URL   : $uri', name: 'ReportBloc');
      emit(ReportReady(reportUri: uri, params: event.params));
    } catch (e) {
      log('Error: $e', name: 'ReportBloc');
      emit(ReportError(e.toString(), params: event.params));
    }
  }

  Future<void> _onChangeDates(
    ChangeReportDates event,
    Emitter<ReportState> emit,
  ) async {
    final ReportParams updated = _lastParams.copyWith(
      startDate: event.startDate,
      endDate: event.endDate,
    );
    add(LoadReport(updated));
  }
}
