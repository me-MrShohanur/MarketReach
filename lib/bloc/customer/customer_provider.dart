import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marketing/services/models/customer.dart';
import 'package:marketing/services/provider/customer_service.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class CustomerEvent {}

class LoadCustomers extends CustomerEvent {}

class SelectCustomer extends CustomerEvent {
  final CustomerModel customer;
  SelectCustomer(this.customer);
}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class CustomerState {}

class CustomerInitial extends CustomerState {}

class CustomerLoading extends CustomerState {}

class CustomerLoaded extends CustomerState {
  final List<CustomerModel> customers;
  final CustomerModel? selectedCustomer;

  CustomerLoaded({required this.customers, this.selectedCustomer});

  CustomerLoaded copyWith({
    List<CustomerModel>? customers,
    CustomerModel? selectedCustomer,
  }) {
    return CustomerLoaded(
      customers: customers ?? this.customers,
      selectedCustomer: selectedCustomer ?? this.selectedCustomer,
    );
  }
}

class CustomerError extends CustomerState {
  final String message;
  CustomerError(this.message);
}

// ─── Bloc ─────────────────────────────────────────────────────────────────────

class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final CustomerService _service;

  CustomerBloc({CustomerService? service})
    : _service = service ?? CustomerService(),
      super(CustomerInitial()) {
    on<LoadCustomers>(_onLoadCustomers);
    on<SelectCustomer>(_onSelectCustomer);
  }

  Future<void> _onLoadCustomers(
    LoadCustomers event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    try {
      final customers = await _service.getCustomers();

      // Auto-select if only one customer is returned
      final autoSelected = customers.length == 1 ? customers.first : null;

      if (autoSelected != null) {
        log(
          name: 'Auto-selected accountId:',
          autoSelected.accountId.toString(),
        );
      }

      emit(
        CustomerLoaded(customers: customers, selectedCustomer: autoSelected),
      );
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  void _onSelectCustomer(SelectCustomer event, Emitter<CustomerState> emit) {
    if (state is CustomerLoaded) {
      final current = state as CustomerLoaded;
      log(name: 'Selected accountId:', event.customer.accountId.toString());
      emit(current.copyWith(selectedCustomer: event.customer));
    }
  }
}
