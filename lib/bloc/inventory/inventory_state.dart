part of 'inventory_bloc.dart';

abstract class InventoryState extends Equatable {
  const InventoryState();

  @override
  List<Object> get props => [];
}

class InventoryInitial extends InventoryState {}

class InventoryLoading extends InventoryState {}

class InventoryLoaded extends InventoryState {
  final List<String> categories;

  const InventoryLoaded({required this.categories});

  @override
  List<Object> get props => [categories];
}

class CategoriesLoaded extends InventoryState {
  final List<String> categories;

  const CategoriesLoaded(this.categories);

  @override
  List<Object> get props => [categories];
}

class InventorySuccess extends InventoryState {
  final String message;

  const InventorySuccess(this.message);

  @override
  List<Object> get props => [message];
}

class InventoryError extends InventoryState {
  final String message;

  const InventoryError(this.message);

  @override
  List<Object> get props => [message];
}

class ItemLoaded extends InventoryState {
  final String namaBarang;
  final String kategori;

  const ItemLoaded({
    required this.namaBarang,
    required this.kategori,
  });

  @override
  List<Object> get props => [namaBarang, kategori];
}

class InventoryStateCompleteEdit extends InventoryState {
  final String message;

  const InventoryStateCompleteEdit(this.message);

  @override
  List<Object> get props => [message];
}
