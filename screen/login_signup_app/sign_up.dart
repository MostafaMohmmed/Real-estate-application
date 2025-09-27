import 'dart:async';                                  // NEW: لاشتراك onTokenRefresh
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';    // ⬅️ Auth لإنشاء/تسجيل دخول المستخدمين
import 'package:cloud_firestore/cloud_firestore.dart';// ⬅️ Firestore لقراءة/كتابة البيانات
import 'package:firebase_messaging/firebase_messaging.dart'; // ⬅️ توكن FCM
// NEW: مستمع الإشعارات المحلية (صوت فوري بدون دفع)
import 'package:final_iug_2025/services/foreground_notifier.dart';

class Sign_Up extends StatefulWidget {
  final bool isCompany;
  const Sign_Up({super.key, this.isCompany = false});

  @override
  State<Sign_Up> createState() => _Sign_UpState();
}

class _Sign_UpState extends State<Sign_Up> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _passwordVisible = false;
  bool _loading = false;

  // ===================== NEW: مرجع لاشتراك onTokenRefresh =====================
  // (عربي) لازم Subscription مش Stream — عشان نقدر نعمل cancel في dispose
  StreamSubscription<String>? _tokenSub;
  // ============================================================================

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    // NEW: ألغِ الاشتراك لو كان شغّال
    _tokenSub?.cancel();
    super.dispose();
  }

  // ===================== NEW: دالة إضافة إشعار داخل Firestore =====================
  // (عربي) هذه الدالة تكتب إشعار تحت مسار المستخدم: users/{uid}/notifications/{autoId}
  // حقول الإشعار: title, body, type (Account/Security/...), isRead=false, createdAt=serverTimestamp
  Future<void> _addNotification({
    required String uid,
    required String title,
    required String body,
    required String type, // مثال: Account
  }) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .add({
      'title': title,
      'body': body,
      'type': type,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
  // =========================================================================

  // ===================== NEW: حفظ توكن الإشعارات تحت الحساب =====================
  // (عربي) نخزن التوكن كـ document id = token (يدمج تلقائيًا)، ونحدّثه عند تغيّر التوكن
  Future<void> _saveFcmTokenForAccount({
    required String uid,
    required bool isCompany,
  }) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      final col = isCompany ? 'companies' : 'users';
      final ref = FirebaseFirestore.instance
          .collection(col)
          .doc(uid)
          .collection('tokens')
          .doc(token);

      await ref.set({
        'createdAt': FieldValue.serverTimestamp(),
        'platform': 'flutter',
      }, SetOptions(merge: true));

      // (عربي) لو تغيّر التوكن لاحقًا، نسجّله مباشرة
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
      // (عربي) فشل حفظ التوكن لا يجب أن يوقف عملية التسجيل — فقط لوج
      debugPrint('⚠️ Failed to save FCM token: $e');
    }
  }
  // ============================================================================

  String _authErrorMsg(FirebaseAuthException e) {                  // ⬅️ ترجمة أخطاء Auth لرسائل مفهومة
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Invalid email format.';
      case 'weak-password':
        return 'Password is too weak (at least 6 characters).';
      case 'network-request-failed':
        return 'Network error. Please try again later.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      default:
        return 'Sign up failed: ${e.code}';
    }
  }

  String _firestoreErrorMsg(FirebaseException e) {                 // ⬅️ ترجمة أخطاء Firestore
    switch (e.code) {
      case 'permission-denied':
        return 'You don’t have permission to write to Firestore. Check your rules and publish them.';
      default:
        return 'Failed to save data: ${e.code}';
    }
  }

  Future<void> _ensureProfile({                                   // ⬅️ إنشاء/تأكيد وثيقة المستخدم
    required String uid,
    required bool isCompany,
    required String fullName,
    required String email,
  }) async {
    final col = isCompany ? 'companies' : 'users';                 // ⬅️ نختار التجميعة حسب الدور
    final ref = FirebaseFirestore.instance
        .collection(col)
        .doc(uid);

    print('📄 Will write Firestore => $col/$uid');

    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'fullName': fullName.trim(),
        'email': email.trim().toLowerCase(),
        'role': isCompany ? 'company' : 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('✅ Firestore write done');
    } else {
      print('ℹ️ Doc already exists, skipping set');
    }

    final readback = await ref.get();
    print('🔎 Read-back exists=${readback.exists} data=${readback.data()}');
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      UserCredential cred;                                         // ⬅️ نتيجة Auth
      bool didCreate = true;                                       // NEW: هل كان Sign up جديد أم Sign in قديم؟

      try {
        cred = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // (عربي) لو الإيميل موجود، نحاول تسجيل دخول بنفس البيانات
          cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
          didCreate = false; // NEW: هذا Sign in لحساب موجود
        } else {
          rethrow;
        }
      }

      final user = cred.user ?? FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Auth failed: no currentUser');
      }

      // ===================== NEW: تحديث displayName من الاسم المُدخل (اختياري) =====================
      if (_nameController.text.trim().isNotEmpty) {
        await user.updateDisplayName(_nameController.text.trim());
      }

      // ⬅️ نضمن ملف Firestore (users/companies) حسب الدور
      await _ensureProfile(
        uid: user.uid,
        isCompany: widget.isCompany,
        fullName: _nameController.text,
        email: _emailController.text,
      );

      // ===================== NEW: ابدأ مستمع الإشعارات المحلي فورًا =====================
      // (عربي) تشغيل الصوت/الإشعار بدون ما تفتح صفحة Notifications
      await ForegroundNotifier.instance.start(user.uid);
      // =====================================================================

      // ===================== NEW: حفظ FCM token تحت الحساب المناسب =====================
      await _saveFcmTokenForAccount(
        uid: user.uid,
        isCompany: widget.isCompany,
      );
      // ==============================================================================

      // ===================== NEW: إرسال إشعار إلى Firestore حسب النتيجة =====================
      try {
        if (didCreate) {
          await _addNotification(
            uid: user.uid,
            title: 'Welcome to your account',
            body: 'Your sign up is complete. Explore listings now.',
            type: 'Account',
          );
        } else {
          await _addNotification(
            uid: user.uid,
            title: 'Signed in successfully',
            body: 'You are now signed in.',
            type: 'Account',
          );
        }
      } catch (e) {
        // (عربي) لو فشل تسجيل الإشعار، ما نكسر تجربة المستخدم — فقط لوج
        print('⚠️ Failed to add notification: $e');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            didCreate
                ? '✅ Account created and data saved'
                : '✅ Signed in (existing account)',
          ),
        ),
      );

      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_authErrorMsg(e))),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_firestoreErrorMsg(e))),
      );
      print('🔥 Firestore error: code=${e.code} | message=${e.message}');
    } catch (e, st) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error: $e')),
      );
      print('❌ Unexpected error: $e\n$st');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          key: const ValueKey('signup_form'),
          mainAxisSize: MainAxisSize.min,
          children: [
            // (UI فقط)
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
                hintText: 'Full Name',
                filled: true,
                fillColor: const Color(0xFFF2F3F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Full name is required' : null,
            ),
            const SizedBox(height: 12),

            // (UI فقط)
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                hintText: 'Email',
                filled: true,
                fillColor: const Color(0xFFF2F3F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (v) {
                final value = (v ?? '').trim();
                if (value.isEmpty) return 'Email is required';
                final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value);
                return ok ? null : 'Invalid email format';
              },
            ),
            const SizedBox(height: 12),

            // (UI فقط)
            TextFormField(
              controller: _passwordController,
              obscureText: !_passwordVisible,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                suffixIcon: IconButton(
                  icon: Icon(
                    _passwordVisible ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                ),
                hintText: 'Password',
                filled: true,
                fillColor: const Color(0xFFF2F3F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (v) => (v != null && v.trim().length >= 6)
                  ? null
                  : 'Password must be at least 6 characters',
            ),
            const SizedBox(height: 16),

            // (UI فقط)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A43EB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  minimumSize: const Size.fromHeight(52),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Register', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
