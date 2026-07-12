// ════════════════════════════════════════════════════════════════════════════
// BLOC  (Event + State + Bloc in one file)
// lib/bloc/challan-details/challan_details_bloc.dart
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marketing/bloc/chalan-details/repository/chalan_details_repo.dart';
import 'package:marketing/services/models/chalan_details.dart';

import 'package:marketing/services/provider/current_user.dart';

// ── Events ───────────────────────────────────────────────────────────────────

abstract class ChallanDetailsEvent {}

class FetchChallanDetails extends ChallanDetailsEvent {
  final int challanId;
  FetchChallanDetails({required this.challanId});
}

// ── States ───────────────────────────────────────────────────────────────────

abstract class ChallanDetailsState {}

class ChallanDetailsInitial extends ChallanDetailsState {}

class ChallanDetailsLoading extends ChallanDetailsState {}

class ChallanDetailsLoaded extends ChallanDetailsState {
  final ChallanDetailsModel details;
  ChallanDetailsLoaded(this.details);
}

class ChallanDetailsError extends ChallanDetailsState {
  final String message;
  ChallanDetailsError(this.message);
}

// ── Bloc ─────────────────────────────────────────────────────────────────────

class ChallanDetailsBloc
    extends Bloc<ChallanDetailsEvent, ChallanDetailsState> {
  final ChallanDetailsRepository repository;

  ChallanDetailsBloc({required this.repository})
    : super(ChallanDetailsInitial()) {
    on<FetchChallanDetails>(_onFetch);
  }

  Future<void> _onFetch(
    FetchChallanDetails event,
    Emitter<ChallanDetailsState> emit,
  ) async {
    emit(ChallanDetailsLoading());
    try {
      final details = await repository.getChallanDetails(
        partyId: CurrentUser.customerID, // static getter
        compId: CurrentUser.compId, // static getter
        challanId: event.challanId,
        token: CurrentUser.token, // static getter
      );
      emit(ChallanDetailsLoaded(details));
    } catch (e) {
      emit(ChallanDetailsError(e.toString()));
    }
  }
}
