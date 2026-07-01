import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marketing/bloc/chalan-deleiver/repository/get_chalan_repo.dart';
import 'package:marketing/services/models/chalan_bill_model.dart';
import 'package:marketing/services/provider/current_user.dart';

abstract class ChallanEvent {}

class FetchChallanBill extends ChallanEvent {
  final int types;
  final int partyId;
  FetchChallanBill({this.types = 2, required this.partyId});
}

//-------------------State------------------//

abstract class ChallanState {}

class ChallanInitial extends ChallanState {}

class ChallanLoading extends ChallanState {}

class ChallanLoaded extends ChallanState {
  final List<ChallanBillModel> challans;
  ChallanLoaded(this.challans);
}

class ChallanError extends ChallanState {
  final String message;
  ChallanError(this.message);
}

//-------------------Bloc------------------//
class DeliveryListBloc extends Bloc<ChallanEvent, ChallanState> {
  final ChallanRepository repository;

  DeliveryListBloc({required this.repository}) : super(ChallanInitial()) {
    on<FetchChallanBill>(_onFetchChallanBill);
  }

  Future<void> _onFetchChallanBill(
    FetchChallanBill event,
    Emitter<ChallanState> emit,
  ) async {
    emit(ChallanLoading());
    try {
      final challans = await repository.getChallanBill(
        partyId: event.partyId,
        compId: CurrentUser.compId,
        types: event.types,
        token: CurrentUser.token,
      );
      emit(ChallanLoaded(challans));
    } catch (e) {
      emit(ChallanError(e.toString()));
    }
  }
}

// abstract class ChallanEvent {}

// class FetchChallanBill extends ChallanEvent {
//   final int types;
//   FetchChallanBill({this.types = 2});
// }

// //-------------------State------------------//

// abstract class ChallanState {}

// class ChallanInitial extends ChallanState {}

// class ChallanLoading extends ChallanState {}

// class ChallanLoaded extends ChallanState {
//   final List<ChallanBillModel> challans;
//   ChallanLoaded(this.challans);
// }

// class ChallanError extends ChallanState {
//   final String message;
//   ChallanError(this.message);
// }

// //-------------------Bloc------------------//
// class DeliveryListBloc extends Bloc<ChallanEvent, ChallanState> {
//   final ChallanRepository repository;

//   DeliveryListBloc({required this.repository}) : super(ChallanInitial()) {
//     on<FetchChallanBill>(_onFetchChallanBill);
//   }

//   Future<void> _onFetchChallanBill(
//     FetchChallanBill event,
//     Emitter<ChallanState> emit,
//   ) async {
//     emit(ChallanLoading());
//     try {
//       final challans = await repository.getChallanBill(
//         partyId: 222,
//         compId: CurrentUser.compId,
//         types: event.types,
//         token: CurrentUser.token,
//       );
//       emit(ChallanLoaded(challans));
//     } catch (e) {
//       emit(ChallanError(e.toString()));
//     }
//   }
// }
