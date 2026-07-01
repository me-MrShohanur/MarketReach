import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:marketing/services/models/getpening_model.dart';

import 'package:marketing/services/provider/current_user.dart';
import 'package:marketing/services/provider/pending_order_repo.dart';

//-------------------Event------------------//

abstract class PendingOrderDetailEvent {}

class FetchPendingOrderDetail extends PendingOrderDetailEvent {
  final int orderId;
  final int partyId;
  FetchPendingOrderDetail({required this.orderId, required this.partyId});
}

//-------------------State------------------//

abstract class PendingOrderDetailState {}

class PendingOrderDetailInitial extends PendingOrderDetailState {}

class PendingOrderDetailLoading extends PendingOrderDetailState {}

class PendingOrderDetailLoaded extends PendingOrderDetailState {
  final List<PendingOrderDetailModel> items;
  PendingOrderDetailLoaded(this.items);
}

class PendingOrderDetailError extends PendingOrderDetailState {
  final String message;
  PendingOrderDetailError(this.message);
}

//-------------------Bloc------------------//

class PendingOrderDetailBloc
    extends Bloc<PendingOrderDetailEvent, PendingOrderDetailState> {
  final PendingOrderDetailRepository repository;

  PendingOrderDetailBloc({required this.repository})
    : super(PendingOrderDetailInitial()) {
    on<FetchPendingOrderDetail>(_onFetch);
  }

  Future<void> _onFetch(
    FetchPendingOrderDetail event,
    Emitter<PendingOrderDetailState> emit,
  ) async {
    emit(PendingOrderDetailLoading());
    try {
      final items = await repository.getPendingOrderDetail(
        partyId: event.partyId,
        compId: CurrentUser.compId,
        orderId: event.orderId,
        token: CurrentUser.token,
      );
      emit(PendingOrderDetailLoaded(items));
    } catch (e) {
      emit(PendingOrderDetailError(e.toString()));
    }
  }
}
