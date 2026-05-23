import 'package:bloc/bloc.dart';
import 'package:marketing/services/challan_details.dart';
import 'package:marketing/services/models/chalan_details.dart';

// ---------------Event Classes----------------

abstract class ChallanEventDetails {
  const ChallanEventDetails();
}

class FetchChallanDetails extends ChallanEventDetails {
  final int partyId;
  final int compId;
  final int challanId;
  final String token;

  const FetchChallanDetails({
    required this.partyId,
    required this.compId,
    required this.challanId,
    required this.token,
  });
}

class ClearChallanDetails extends ChallanEventDetails {}

// ---------------State Classes----------------

abstract class ChallanState {
  const ChallanState();
}

class ChallanInitial extends ChallanState {}

class ChallanLoading extends ChallanState {}

class ChallanLoaded extends ChallanState {
  final ChallanDetail challanDetail;

  const ChallanLoaded(this.challanDetail);
}

class ChallanError extends ChallanState {
  final String message;

  const ChallanError(this.message);
}

// ---------------Bloc Implementation----------------

class ChallanBlocDetails extends Bloc<ChallanEventDetails, ChallanState> {
  final ChallanService challanService;

  ChallanBlocDetails({required this.challanService}) : super(ChallanInitial()) {
    on<FetchChallanDetails>(_onFetchChallanDetails);
    on<ClearChallanDetails>(_onClearChallanDetails);
  }

  Future<void> _onFetchChallanDetails(
    FetchChallanDetails event,
    Emitter<ChallanState> emit,
  ) async {
    emit(ChallanLoading());

    try {
      final response = await challanService.getChallanDetails(
        partyId: event.partyId,
        compId: event.compId,
        challanId: event.challanId,
        token: event.token,
      );

      if (response.result.result.isNotEmpty) {
        emit(ChallanLoaded(response.result.result.first));
      } else {
        emit(const ChallanError('No challan details found'));
      }
    } catch (e) {
      emit(ChallanError(e.toString()));
    }
  }

  void _onClearChallanDetails(
    ClearChallanDetails event,
    Emitter<ChallanState> emit,
  ) {
    emit(ChallanInitial());
  }
}
