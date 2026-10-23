import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/available_slot.dart';
import '../../domain/usecases/booking_usecases.dart';

class BookingState extends Equatable {
  const BookingState({
    this.slots = const [],
    this.isLoading = false,
    this.requestingSlot,
    this.message,
    this.isError = false,
  });
  final List<AvailableSlot> slots;
  final bool isLoading;
  final DateTime? requestingSlot;
  final String? message;
  final bool isError;

  BookingState copyWith({
    List<AvailableSlot>? slots,
    bool? isLoading,
    DateTime? requestingSlot,
    bool clearRequestingSlot = false,
    String? message,
    bool clearMessage = false,
    bool? isError,
  }) =>
      BookingState(
        slots: slots ?? this.slots,
        isLoading: isLoading ?? this.isLoading,
        requestingSlot:
            clearRequestingSlot ? null : requestingSlot ?? this.requestingSlot,
        message: clearMessage ? null : message ?? this.message,
        isError: isError ?? this.isError,
      );

  @override
  List<Object?> get props =>
      [slots, isLoading, requestingSlot, message, isError];
}

class BookingCubit extends Cubit<BookingState> {
  BookingCubit(
      {required GetAvailableSlots getAvailableSlots,
      required RequestAppointment requestAppointment})
      : _getAvailableSlots = getAvailableSlots,
        _requestAppointment = requestAppointment,
        super(const BookingState());

  final GetAvailableSlots _getAvailableSlots;
  final RequestAppointment _requestAppointment;

  Future<void> loadSlots() async {
    emit(state.copyWith(isLoading: true, clearMessage: true));

    final result = await _getAvailableSlots(const NoParams());

    result.fold(
      (failure) {
        debugPrint('SLOTS ERROR: ${failure.message}');
        emit(state.copyWith(
          isLoading: false,
          message: failure.message,
          isError: true,
        ));
      },
      (slots) {
        debugPrint('SLOTS COUNT: ${slots.length}');

        for (final slot in slots) {
          debugPrint(
            'SLOT: ${slot.startsAt} | ${slot.endsAt}',
          );
        }

        emit(state.copyWith(
          slots: slots,
          isLoading: false,
          clearMessage: true,
          isError: false,
        ));
      },
    );
  }

  Future<void> book(AvailableSlot slot) async {
    emit(state.copyWith(requestingSlot: slot.startsAt, clearMessage: true));
    final result = await _requestAppointment(slot.startsAt);

    result.fold(
      (failure) => emit(state.copyWith(
          clearRequestingSlot: true, message: failure.message, isError: true)),
      (_) => emit(state.copyWith(
          clearRequestingSlot: true,
          message: 'تم إرسال طلب الحجز بنجاح. بانتظار موافقة الآنسة فاطمة.',
          isError: false)),
    );
    await loadSlots();
  }
}
