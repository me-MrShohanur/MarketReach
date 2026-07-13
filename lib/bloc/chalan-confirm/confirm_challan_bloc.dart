import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marketing/bloc/chalan-confirm/repo/challan_confirm.dart';

import 'package:marketing/services/provider/current_user.dart';

// TODO: point this at wherever your logged-in user session actually lives.
// You said it's a singleton like `CurrentUser.compId` — import that here.
// e.g. import 'package:marketing/services/current_user.dart';

// ════════════════════════════════════════════════════════════════════════════
// EVENT
// ════════════════════════════════════════════════════════════════════════════

/// A Bloc's events describe "things that happened" — usually user actions.
/// We only need one: the user tapped Confirm. challanId is passed in because
/// it belongs to the *page* calling this Bloc, not to the user session.
abstract class ConfirmChallanEvent {}

class ConfirmChallanRequested extends ConfirmChallanEvent {
  final int challanId;

  ConfirmChallanRequested({required this.challanId});
}

// ════════════════════════════════════════════════════════════════════════════
// STATE
// ════════════════════════════════════════════════════════════════════════════

/// States describe "what the UI should currently look like". Keeping these
/// as separate classes (instead of one class with a status enum + nullable
/// fields) is what lets BlocBuilder's `if (state is X)` checks stay simple
/// and exhaustive-feeling.
abstract class ConfirmChallanState {}

class ConfirmChallanInitial extends ConfirmChallanState {}

class ConfirmChallanLoading extends ConfirmChallanState {}

class ConfirmChallanSuccess extends ConfirmChallanState {}

class ConfirmChallanFailure extends ConfirmChallanState {
  final String error;

  /// true  → server responded 200 but the body was literally `false`
  ///         (request was understood, confirm just didn't go through —
  ///         e.g. already confirmed by someone else, invalid state, etc.)
  /// false → thrown exception: bad status code, network error, bad body
  final bool wasServerRejection;

  ConfirmChallanFailure(this.error, {this.wasServerRejection = false});
}

// ════════════════════════════════════════════════════════════════════════════
// BLOC
// ════════════════════════════════════════════════════════════════════════════

class ConfirmChallanBloc
    extends Bloc<ConfirmChallanEvent, ConfirmChallanState> {
  final ConfirmChallanRepository repository;

  ConfirmChallanBloc({required this.repository})
    : super(ConfirmChallanInitial()) {
    on<ConfirmChallanRequested>(_onConfirmChallanRequested);
  }

  Future<void> _onConfirmChallanRequested(
    ConfirmChallanRequested event,
    Emitter<ConfirmChallanState> emit,
  ) async {
    emit(ConfirmChallanLoading());
    try {
      // ─── compId comes from the current user, NOT from the event ─────────
      // This is the key structural decision: challanId is page-context,
      // compId is session-context. Mixing them into the event would force
      // every call site to know about the user session, which defeats the
      // point of having one.
      final int compId = CurrentUser.compId; // <-- wire this to your singleton
      final String token = CurrentUser.token; // <-- and this

      final bool confirmed = await repository.confirmChallanReceived(
        challanId: event.challanId,
        compId: compId,
        token: token,
      );

      if (confirmed) {
        emit(ConfirmChallanSuccess());
      } else {
        // HTTP 200, but the server's boolean body was `false` — the
        // request was received but the confirm did not go through.
        emit(
          ConfirmChallanFailure(
            'Server could not confirm this challan. Please try again.',
            wasServerRejection: true,
          ),
        );
      }
    } on ConfirmChallanApiException catch (e) {
      // Non-200 status, network failure, or unparseable body.
      emit(ConfirmChallanFailure(e.message));
    } catch (e) {
      emit(ConfirmChallanFailure(e.toString()));
    }
  }
}
