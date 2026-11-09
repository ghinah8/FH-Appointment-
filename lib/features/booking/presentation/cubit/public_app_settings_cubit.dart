import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/admin_dashboard_data.dart';
import '../../domain/usecases/admin_dashboard_usecases.dart';

abstract class PublicAppSettingsState extends Equatable {
  const PublicAppSettingsState();

  @override
  List<Object?> get props => [];
}

class PublicAppSettingsLoading extends PublicAppSettingsState {
  const PublicAppSettingsLoading();
}

class PublicAppSettingsLoaded extends PublicAppSettingsState {
  const PublicAppSettingsLoaded(this.settings);

  final AdminAppSettings settings;

  @override
  List<Object?> get props => [settings];
}

class PublicAppSettingsError extends PublicAppSettingsState {
  const PublicAppSettingsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class PublicAppSettingsCubit extends Cubit<PublicAppSettingsState> {
  PublicAppSettingsCubit(this._actions)
      : super(const PublicAppSettingsLoading());

  final AdminDashboardUseCases _actions;

  Future<void> load() async {
    final result = await _actions.settings();
    result.fold(
      (failure) => emit(PublicAppSettingsError(failure.message)),
      (settings) => emit(PublicAppSettingsLoaded(settings)),
    );
  }
}
