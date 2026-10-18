import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth_usecases.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  const AuthState._(this.status, this.user);

  const AuthState.unknown() : this._(AuthStatus.unknown, null);
  const AuthState.authenticated(AppUser user)
      : this._(AuthStatus.authenticated, user);
  const AuthState.unauthenticated() : this._(AuthStatus.unauthenticated, null);

  final AuthStatus status;
  final AppUser? user;

  @override
  List<Object?> get props => [status, user];
}

/// حالة الجلسة العامة للتطبيق (يستمع لها الراوتر).
class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required AuthRepository repository,
    required GetCurrentUser getCurrentUser,
    required SignOut signOut,
  })  : _getCurrentUser = getCurrentUser,
        _signOut = signOut,
        super(const AuthState.unknown()) {
    _sub = repository.onAuthChanged.listen((_) => refresh());
    refresh();
  }

  final GetCurrentUser _getCurrentUser;
  final SignOut _signOut;
  late final StreamSubscription<void> _sub;

  Future<void> refresh() async {
    final result = await _getCurrentUser(const NoParams());
    result.fold(
      (_) => emit(const AuthState.unauthenticated()),
      (user) => emit(
        user == null
            ? const AuthState.unauthenticated()
            : AuthState.authenticated(user),
      ),
    );
  }

  Future<void> signOut() async {
    await _signOut(const NoParams());
    emit(const AuthState.unauthenticated());
  }

  @override
  Future<void> close() async {
    await _sub.cancel();
    return super.close();
  }
}
