import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// صفحاتك بعد تسجيل الدخول
import 'package:final_iug_2025/screen/user/homePage.dart';
import 'package:final_iug_2025/screen/login_signup_app/reset_password.dart';
import '../../services/company_bootstrap.dart';
import '../../services/plan_service.dart';
import '../Company/company_home_page.dart';

// سوشيال (Google)
import 'package:google_sign_in/google_sign_in.dart';

// Firebase Messaging لحفظ FCM token
import 'package:firebase_messaging/firebase_messaging.dart';

// مستمع الإشعارات المحلي
import 'package:final_iug_2025/services/foreground_notifier.dart';

// الترجمة
import 'package:easy_localization/easy_localization.dart';

class LogIn extends StatefulWidget {
  final bool isCompany;
  const LogIn({super.key, this.isCompany = false});

  @override
  State<LogIn> createState() => _LogInState();
}

class _LogInState extends State<LogIn> {
  bool passwordVisible = false;
  bool _loading = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // لإدارة onTokenRefresh
  StreamSubscription<String>? _tokenSub;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _tokenSub?.cancel();
    super.dispose();
  }

  void _show(String msgKey) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msgKey.tr())),
    );
  }

  // ===================== إضافة إشعار بحسب نوع الحساب (User/Company) =====================
  Future<void> _addNotification({
    required String uid,
    required String titleKey,
    required String bodyKey,
    required String type, // 'Account' | 'Security' | ...
    required bool isCompany,
  }) async {
    try {
      final root = isCompany ? 'companies' : 'users';
      await FirebaseFirestore.instance
          .collection(root)
          .doc(uid)
          .collection('notifications')
          .add({
        'title': titleKey.tr(),
        'body': bodyKey.tr(),
        'type': type,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('⚠️ Failed to add notification: $e');
    }
  }

  // ===================== حفظ/تحديث FCM token تحت الحساب الصحيح =====================
  Future<void> _saveFcmTokenForAccount({
    required String uid,
    required bool isCompany,
  }) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      final col = isCompany ? 'companies' : 'users';
      final tokensRef = FirebaseFirestore.instance
          .collection(col)
          .doc(uid)
          .collection('tokens')
          .doc(token);

      await tokensRef.set({
        'createdAt': FieldValue.serverTimestamp(),
        'platform': 'flutter',
      }, SetOptions(merge: true));

      _tokenSub?.cancel();
      _tokenSub = FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        await FirebaseFirestore.instance
            .collection(col)
            .doc(uid)
            .collection('tokens')
            .doc(newToken)
            .set({
          'createdAt': FieldValue.serverTimestamp(),
          'platform': 'flutter',
        }, SetOptions(merge: true));
      });
    } catch (e) {
      debugPrint('⚠️ Failed to save FCM token: $e');
    }
  }

  // ----------------- Firestore helpers -----------------
  Future<String?> _fetchRoleOnly(String uid) async {
    final uSnap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (uSnap.exists) return (uSnap.data()?['role'] ?? 'user').toString();

    final cSnap = await FirebaseFirestore.instance.collection('companies').doc(uid).get();
    if (cSnap.exists) return (cSnap.data()?['role'] ?? 'company').toString();

    return null;
  }

  Future<void> _ensureUserProfile(User user) async {
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'fullName': user.displayName ?? 'User',
        'email': user.email?.toLowerCase(),
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _navigateByRole(String role) async {
    if (!mounted) return;
    if (role == 'company') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CompanyHomePage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const homePage()),
      );
    }
  }

  // ----------------- Email/Password login -----------------
  Future<void> _login() async {
    final email = _emailController.text.trim();
    final pass  = _passwordController.text.trim();

    final emailOk = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
    if (!emailOk) return _show('auth.errors.invalid_email');
    if (pass.length < 6) return _show('auth.errors.password_min');

    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );
      final uid = cred.user!.uid;

      final role = await _fetchRoleOnly(uid);
      if (role == null) {
        _show('auth.errors.no_profile');
        await FirebaseAuth.instance.signOut();
        return;
      }

      // ✅ للشركة فقط: ضمان إنشاء وثيقة الشركة + 5 مجاني أول مرة
      if (role == 'company') {
        await CompanyBootstrap.ensureCompanyDoc(initialFree: 5);
        await _ensurePhonePresent(uid: uid, isCompany: true);
      }

      // إشعار نجاح تسجيل الدخول حسب نوع الحساب
      await _addNotification(
        uid: uid,
        titleKey: 'notif.signin_success_title',
        bodyKey: 'notif.signin_success_body',
        type: 'Account',
        isCompany: role == 'company',
      );

      // مستمع الإشعارات المحلي
      await ForegroundNotifier.instance.start(uid);

      // حفظ FCM token للحساب الصحيح
      await _saveFcmTokenForAccount(
        uid: uid,
        isCompany: role == 'company',
      );

      await _navigateByRole(role);
    } on FirebaseAuthException catch (e) {
      final map = {
        'user-not-found': 'auth.errors.user_not_found',
        'wrong-password': 'auth.errors.wrong_password',
        'invalid-email': 'auth.errors.invalid_email',
        'user-disabled': 'auth.errors.user_disabled',
        'too-many-requests': 'auth.errors.too_many_requests',
        'network-request-failed': 'auth.errors.network',
      };
      _show(map[e.code] ?? 'auth.errors.signin_failed');
    } catch (_) {
      _show('common.unexpected');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }


  // ----------------- Helper: clear Google session safely -----------------
  Future<void> _clearGoogleSessionSafely() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}

    final g = GoogleSignIn();
    try {
      final isIn = await g.isSignedIn();
      if (isIn) await g.signOut();
    } catch (_) {}

    try {
      await g.disconnect();
    } catch (_) {}
  }

  // ----------------- Google Sign-In (User only) -----------------
  Future<void> _signInWithGoogle() async {
    if (widget.isCompany) {
      _show('auth.errors.company_google_forbidden');
      return;
    }
    setState(() => _loading = true);
    try {
      await _clearGoogleSessionSafely();

      final g = GoogleSignIn();
      final googleUser = await g.signIn();
      if (googleUser == null) {
        setState(() => _loading = false);
        return; // cancel
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );
      final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCred.user!;
      final role = await _fetchRoleOnly(user.uid);

      if (role == 'company') {
        await FirebaseAuth.instance.signOut();
        _show('auth.errors.email_belongs_company');
        return;
      }

      if (role == null) {
        await _ensureUserProfile(user);
      }

      // إشعار نجاح تسجيل الدخول بجوجل (User فقط)
      await _addNotification(
        uid: user.uid,
        titleKey: 'notif.google_signin_title',
        bodyKey: 'notif.google_signin_body',
        type: 'Account',
        isCompany: false,
      );

      // مستمع الإشعارات المحلي
      await ForegroundNotifier.instance.start(user.uid);

      // حفظ FCM token
      await _saveFcmTokenForAccount(
        uid: user.uid,
        isCompany: false,
      );

      // اطلب رقم الجوال لو مش محفوظ
      await _ensurePhonePresent(uid: user.uid, isCompany: false);

      await _navigateByRole('user');
    } on FirebaseAuthException catch (e) {
      debugPrint('Google sign-in failed: ${e.code}');
      _show('auth.errors.google_failed');
    } catch (_) {
      _show('common.unexpected');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ----------------- Placeholders (Apple / Facebook) -----------------
  void _underDevelopment() => _show('common.under_dev');

  /// يطلب رقم الجوال مرة واحدة إذا لم يكن محفوظًا، ثم يحفظه في Firestore.
  Future<void> _ensurePhonePresent({
    required String uid,
    required bool isCompany,
  }) async {
    final col = isCompany ? 'companies' : 'users';
    final ref = FirebaseFirestore.instance.collection(col).doc(uid);
    final snap = await ref.get();
    final existing = (snap.data() ?? {});
    final already = (existing['phone'] ?? '').toString().trim();

    if (already.isNotEmpty) return;

    String? phone = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final c = TextEditingController();
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16, right: 16, top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'phone.add_title'.tr(),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: c,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'phone.hint'.tr(),
                  filled: true,
                  border: const OutlineInputBorder(borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  final raw = c.text.trim();
                  final ok = RegExp(r'^[0-9+\-\s]{6,}$').hasMatch(raw);
                  if (!ok) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('phone.invalid'.tr())),
                    );
                    return;
                  }
                  Navigator.pop(ctx, raw);
                },
                child: Text('common.save'.tr()),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );

    if (phone == null || phone.trim().isEmpty) return;
    await ref.set({'phone': phone.trim()}, SetOptions(merge: true));
  }

  // ----------------- UI -----------------
  @override
  Widget build(BuildContext context) {
    final showSocial = !widget.isCompany;

    return SingleChildScrollView(
      child: Column(
        key: const ValueKey('login_form'),
        mainAxisSize: MainAxisSize.min,
        children: [
          // Email
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
              hintText: 'auth.email'.tr(),
              filled: true,
              fillColor: const Color(0xFFF2F3F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Password
          TextField(
            controller: _passwordController,
            obscureText: !passwordVisible,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
              suffixIcon: IconButton(
                icon: Icon(
                  passwordVisible ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () => setState(() => passwordVisible = !passwordVisible),
              ),
              hintText: 'auth.password'.tr(),
              filled: true,
              fillColor: const Color(0xFFF2F3F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _loading
                        ? null
                        : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ResetPasswordPage(),
                        ),
                      );
                    },
                    child: Text(
                      'auth.forgot_password'.tr(),
                      style: const TextStyle(
                        fontSize: 17,
                        decoration: TextDecoration.underline,
                        color: Color(0xFF6A798A),
                      ),
                    ),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _loading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A43EB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  minimumSize: const Size(120, 44),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Text(
                  'auth.login'.tr(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),

          // -------- Social (User only) --------
          if (showSocial) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                const Expanded(child: Divider(thickness: 1)),
                const SizedBox(width: 8),
                Text('auth.or_continue_with'.tr()),
                const SizedBox(width: 8),
                const Expanded(child: Divider(thickness: 1)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _socialButton(
                    label: 'auth.google'.tr(),
                    icon: Icons.g_mobiledata,
                    onTap: _loading ? null : _signInWithGoogle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _socialButton(
                    label: 'auth.facebook'.tr(),
                    icon: Icons.facebook,
                    onTap: _loading ? null : _underDevelopment,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _socialButton(
                    label: 'auth.apple'.tr(),
                    icon: Icons.apple,
                    onTap: _loading ? null : _underDevelopment,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static Widget _socialButton({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD5DEE7), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
