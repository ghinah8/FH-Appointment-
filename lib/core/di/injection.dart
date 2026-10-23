import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/auth_usecases.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/login_cubit.dart';
import '../../features/auth/presentation/cubit/register_cubit.dart';
import '../../features/auth/presentation/cubit/verify_email_cubit.dart';

import '../../features/booking/data/datasources/booking_remote_data_source.dart';
import '../../features/booking/data/repositories/booking_repository_impl.dart';
import '../../features/booking/domain/repositories/booking_repository.dart';
import '../../features/booking/domain/usecases/booking_usecases.dart';
import '../../features/booking/presentation/cubit/appointments_admin_cubit.dart';
import '../../features/booking/presentation/cubit/booking_cubit.dart';
import '../../features/booking/presentation/cubit/appointments_cubit.dart';

final sl = GetIt.instance;

/// تسجيل كل الاعتماديات. تُستدعى بعد Supabase.initialize().
Future<void> initDependencies() async {
  // ---- core ----
  sl.registerLazySingleton<SupabaseClient>(
    () => Supabase.instance.client,
  );

  // ---- features/auth ----
  sl
    ..registerLazySingleton(() => AuthRemoteDataSource(sl()))
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(sl()),
    )
    ..registerLazySingleton(() => GetCurrentUser(sl()))
    ..registerLazySingleton(() => SignIn(sl()))
    ..registerLazySingleton(() => SignUp(sl()))
    ..registerLazySingleton(() => SignOut(sl()))
    ..registerLazySingleton(() => GetUniversities(sl()))
    ..registerLazySingleton(() => ResendVerification(sl()))
    ..registerLazySingleton(() => SendPasswordReset(sl()))
    ..registerLazySingleton(
      () => AuthCubit(
        repository: sl(),
        getCurrentUser: sl(),
        signOut: sl(),
      ),
    )
    ..registerFactory(
      () => LoginCubit(
        signIn: sl(),
        resendVerification: sl(),
        sendPasswordReset: sl(),
      ),
    )
    ..registerFactory(
      () => RegisterCubit(
        getUniversities: sl(),
        signUp: sl(),
      ),
    )
    ..registerFactory(() => VerifyEmailCubit(sl()))

    // ---- features/booking ----
    ..registerLazySingleton(() => BookingRemoteDataSource(sl()))
    ..registerLazySingleton<BookingRepository>(
      () => BookingRepositoryImpl(sl()),
    )
    ..registerLazySingleton(() => GetAvailableSlots(sl()))
    ..registerLazySingleton(() => RequestAppointment(sl()))
    ..registerLazySingleton(() => GetMyAppointments(sl()))
    ..registerLazySingleton(() => GetPendingAppointments(sl()))
    ..registerLazySingleton(() => DecideAppointment(sl()))
    ..registerFactory(
      () => BookingCubit(
        getAvailableSlots: sl(),
        requestAppointment: sl(),
      ),
    )
    ..registerFactory(
      () => AppointmentsCubit(
        getMyAppointments: sl(),
      ),
    )
    ..registerFactory(
      () => AppointmentsAdminCubit(
        getPendingAppointments: sl(),
        decideAppointment: sl(),
      ),
    );
}
