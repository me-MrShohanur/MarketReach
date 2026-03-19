import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:marketing/services/models/products_model.dart';

import 'package:marketing/services/provider/product_service.dart';

// ── Events ────────────────────────────────────────────────────────────────────
abstract class ProductEvent {}

class FetchProducts extends ProductEvent {
  final int categoryId;
  FetchProducts({required this.categoryId});
}

// ── States ────────────────────────────────────────────────────────────────────
abstract class ProductState {}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class ProductLoaded extends ProductState {
  final List<ProductModel> products;
  ProductLoaded(this.products);
}

class ProductError extends ProductState {
  final String message;
  ProductError(this.message);
}

// ── BLoC ──────────────────────────────────────────────────────────────────────
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductService _service = ProductService();

  ProductBloc() : super(ProductInitial()) {
    on<FetchProducts>(_onFetch);
  }

  Future<void> _onFetch(FetchProducts event, Emitter<ProductState> emit) async {
    emit(ProductLoading());
    try {
      final products = await _service.getProducts(categoryId: event.categoryId);
      emit(ProductLoaded(products));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }
}
