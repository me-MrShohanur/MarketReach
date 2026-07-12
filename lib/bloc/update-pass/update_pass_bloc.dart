// lib/bloc/update-password/update_password_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marketing/bloc/update-pass/repo/update_pass.dart';

import 'package:marketing/services/provider/current_user.dart';

// ── Events ────────────────────────────────────────────────────────────────────

abstract class UpdatePasswordEvent {}

class SubmitUpdatePassword extends UpdatePasswordEvent {
  final String userName;
  final String currentPassword;
  final String newPassword;

  SubmitUpdatePassword({
    required this.userName,
    required this.currentPassword,
    required this.newPassword,
  });
}

class ResetUpdatePassword extends UpdatePasswordEvent {}

// ── States ────────────────────────────────────────────────────────────────────

abstract class UpdatePasswordState {}

class UpdatePasswordInitial extends UpdatePasswordState {}

class UpdatePasswordLoading extends UpdatePasswordState {}

class UpdatePasswordSuccess extends UpdatePasswordState {}

class UpdatePasswordFailure extends UpdatePasswordState {
  // API returned a non-true result — could be "false", "Current password is
  // incorrect", "Username is not valid", etc.
  final String message;
  UpdatePasswordFailure(this.message);
}

class UpdatePasswordError extends UpdatePasswordState {
  final String message;
  UpdatePasswordError(this.message);
}

// ── Bloc ──────────────────────────────────────────────────────────────────────

class UpdatePasswordBloc
    extends Bloc<UpdatePasswordEvent, UpdatePasswordState> {
  final UpdatePasswordRepository repository;

  UpdatePasswordBloc({required this.repository})
    : super(UpdatePasswordInitial()) {
    on<SubmitUpdatePassword>(_onSubmit);
    on<ResetUpdatePassword>(_onReset);
  }

  Future<void> _onSubmit(
    SubmitUpdatePassword event,
    Emitter<UpdatePasswordState> emit,
  ) async {
    emit(UpdatePasswordLoading());
    try {
      final result = await repository.updatePassword(
        userName: event.userName,
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
        token: CurrentUser.token,
      );

      if (result.success) {
        emit(UpdatePasswordSuccess());
      } else {
        emit(UpdatePasswordFailure(result.message));
      }
    } catch (e) {
      emit(UpdatePasswordError(e.toString()));
    }
  }

  void _onReset(ResetUpdatePassword event, Emitter<UpdatePasswordState> emit) {
    emit(UpdatePasswordInitial());
  }
}
