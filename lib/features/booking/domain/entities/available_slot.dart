import 'package:equatable/equatable.dart';

class AvailableSlot extends Equatable {
  const AvailableSlot({required this.startsAt, required this.endsAt});

  final DateTime startsAt;
  final DateTime endsAt;

  @override
  List<Object?> get props => [startsAt, endsAt];
}
