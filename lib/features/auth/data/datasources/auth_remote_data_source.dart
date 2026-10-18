import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/env.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/auth_models.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._client);
  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;

  Stream<void> get onAuthChanged => _auth.onAuthStateChange.map((_) {});

  Future<AppUserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final profile = await _client
        .from('profiles')
        .select('full_name, role')
        .eq('id', user.id)
        .maybeSingle();

    return AppUserModel.fromSupabase(
      id: user.id,
      email: user.email,
      emailConfirmedAt: user.emailConfirmedAt,
      profile: profile,
    );
  }

  Future<void> signIn(String email, String password) =>
      _auth.signInWithPassword(email: email, password: password);

  /// يعيد true إذا لم تُنشأ جلسة (أي أن التحقق من البريد مطلوب).
  Future<bool> signUp(SignUpData d) async {
    final res = await _auth.signUp(
      email: d.email.trim(),
      password: d.password,
      emailRedirectTo: Env.siteUrl.isEmpty ? null : Env.siteUrl,
      // يقرأها الـ trigger handle_new_user وينشئ منها صف profiles
      data: {
        'full_name': d.fullName.trim(),
        'phone': d.phone,
        'university_id': d.universityId,
        'study_year': d.studyYear.apiValue,
        'is_graduating': d.studyYear.isGraduating,
      },
    );
    return res.session == null;
  }

  Future<void> signOut() => _auth.signOut();

  Future<List<UniversityModel>> getUniversities() async {
    final rows = await _client
        .from('universities')
        .select('id, name')
        .eq('is_active', true)
        .order('sort_order');
    return rows.map<UniversityModel>(UniversityModel.fromJson).toList();
  }

  Future<void> resendVerification(String email) =>
      _auth.resend(type: OtpType.signup, email: email);

  Future<void> sendPasswordReset(String email) => _auth.resetPasswordForEmail(
        email,
        redirectTo: Env.siteUrl.isEmpty ? null : Env.siteUrl,
      );
}
