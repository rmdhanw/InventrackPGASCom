part of 'carpool_bloc.dart';

abstract class CarpoolState {}

class CarpoolStateInitial extends CarpoolState {}

class CarpoolStateLoadingAdd extends CarpoolState {}

class CarpoolStateLoadingEdit extends CarpoolState {}

class CarpoolStateLoadingDelete extends CarpoolState {}

class CarpoolStateCompleteAdd extends CarpoolState {}

class CarpoolStateCompleteEdit extends CarpoolState {}

class CarpoolStateCompleteDelete extends CarpoolState {}

class CarpoolStateFetched extends CarpoolState {
  final List<Map<String, dynamic>> carpoolList;
  CarpoolStateFetched(this.carpoolList);
}

class CarpoolStateError extends CarpoolState {
  final String message;
  CarpoolStateError(this.message);
}
