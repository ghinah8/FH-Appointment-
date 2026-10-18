import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/university.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth_usecases.dart';
import 'login_cubit.dart' show FormStatus;

class RegisterState extends Equatable {
  const RegisterState({
    this.universities = const [],
    this.universitiesLoading = true,
    this.status = FormStatus.initial,
    this.error,
    this.needsVerification = true,
  });

  final List<University> universities;
  final bool universitiesLoading;
  final FormStatus status;
  final String? error;
  final bool needsVerification;

  RegisterState copyWith({
    List<University>? universities,
    bool? universitiesLoading,
    FormStatus? status,
    String? error,
    bool? needsVerification,
  }) =>
      RegisterState(
        universities: universities ?? this.universities,
        universitiesLoading: universitiesLoading ?? this.universitiesLoading,
        status: status ?? this.status,
        error: error,
        needsVerification: needsVerification ?? this.needsVerification,
      );

  @override
  List<Object?> get props =>
      [universities, universitiesLoading, status, error, needsVerification];
}

class RegisterCubit extends Cubit<RegisterState> {
  RegisterCubit({
    required GetUniversities getUniversities,
    required SignUp signUp,
  })  : _getUniversities = getUniversities,
        _signUp = signUp,
        super(const RegisterState());

  final GetUniversities _getUniversities;
  final SignUp _signUp;

  Future<void> loadUniversities() async {
    emit(state.copyWith(universitiesLoading: true));
    final res = await _getUniversities(const NoParams());
    res.fold(
      (f) => emit(state.copyWith(
          universitiesLoading: false,
          status: FormStatus.failure,
          error: f.message)),
      (list) => emit(state.copyWith(
          universities: list, universitiesLoading: false, status: FormStatus.initial)),
    );
  }

  Future<void> submit(SignUpData data) async {
    emit(state.copyWith(status: FormStatus.loading));
    final res = await _signUp(data);
    res.fold(
      (f) => emit(state.copyWith(status: FormStatus.failure, error: f.message)),
      (needsVerification) => emit(state.copyWith(
          status: FormStatus.success, needsVerification: needsVerification)),
    );
  }
}
