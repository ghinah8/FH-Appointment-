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

final sl = GetIt.instance;

/// تسجيل كل الاعتماديات. تُستدعى بعد Supabase.initialize().
Future<void> initDependencies() async {
  // ---- core ----
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

  // ---- features/auth ----
  sl
    ..registerLazySingleton(() => AuthRemoteDataSource(sl()))
    ..registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()))
    ..registerLazySingleton(() => GetCurrentUser(sl()))
    ..registerLazySingleton(() => SignIn(sl()))
    ..registerLazySingleton(() => SignUp(sl()))
    ..registerLazySingleton(() => SignOut(sl()))
    ..registerLazySingleton(() => GetUniversities(sl()))
    ..registerLazySingleton(() => ResendVerification(sl()))
    ..registerLazySingleton(() => SendPasswordReset(sl()))
    // جلسة التطبيق: نسخة واحدة طوال عمر التطبيق
    ..registerLazySingleton(() => AuthCubit(
          repository: sl(),
          getCurrentUser: sl(),
          signOut: sl(),
        ))
    // نماذج الصفحات: نسخة جديدة لكل صفحة
    ..registerFactory(() => LoginCubit(
          signIn: sl(),
          resendVerification: sl(),
          sendPasswordReset: sl(),
        ))
    ..registerFactory(() => RegisterCubit(
          getUniversities: sl(),
          signUp: sl(),
        ))
    ..registerFactory(() => VerifyEmailCubit(sl()));
}
