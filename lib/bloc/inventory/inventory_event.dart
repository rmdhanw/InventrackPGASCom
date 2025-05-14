part of 'inventory_bloc.dart';

abstract class InventoryEvent extends Equatable {
  const InventoryEvent();

  @override
  List<Object> get props => [];
}

class LoadCategories extends InventoryEvent {}

class AddInventoryItem extends InventoryEvent {
  final String kategori;
  final String nomorSerial;
  final String namaBarang;

  const AddInventoryItem({
    required this.kategori,
    required this.nomorSerial,
    required this.namaBarang,
  });

  @override
  List<Object> get props => [kategori, nomorSerial, namaBarang];
}

class AddTransaction extends InventoryEvent {
  final String kategori;
  final String nomorSerial;
  final String namaBarang;
  final String status;
  final String kondisi;
  final String keterangan;

  const AddTransaction({
    required this.kategori,
    required this.nomorSerial,
    required this.namaBarang,
    required this.status,
    required this.kondisi,
    required this.keterangan,
  });

  @override
  List<Object> get props =>
      [kategori, nomorSerial, namaBarang, status, kondisi, keterangan];
}

class LoadItemBySerial extends InventoryEvent {
  final String serialNumber;

  const LoadItemBySerial(this.serialNumber);

  @override
  List<Object> get props => [serialNumber];
}

class DeleteInventoryItem extends InventoryEvent {
  final String nomorSerial;

  const DeleteInventoryItem(this.nomorSerial);

  @override
  List<Object> get props => [nomorSerial];
}

class InventoryEventEditInventory extends InventoryEvent {
  final String id;
  final String namaBarang;
  final String nomorSerial;
  final String kategori;
  final String tanggal;

  const InventoryEventEditInventory({
    required this.id,
    required this.namaBarang,
    required this.nomorSerial,
    required this.kategori,
    required this.tanggal,
  });

  @override
  List<Object> get props => [id, namaBarang, nomorSerial, kategori, tanggal];
}
