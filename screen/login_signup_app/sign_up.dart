// lib/screen/login_signup_app/sign_up.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

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
  final _phoneController = TextEditingController();     // ⬅️ جديد
  final _passwordController = TextEditingController();

  bool _passwordVisible = false;
  bool _loading = false;

  StreamSubscription<String>? _tokenSub;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();                         // ⬅️ جديد
    _passwordController.dispose();
    _tokenSub?.cancel();
    super.dispose();
  }

  Future<void> _addNotification({
    required String uid,
    required String title,
    required String body,
    required String type,
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

  String _authErrorMsg(FirebaseAuthException e) {
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

  String _firestoreErrorMsg(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'You don’t have permission to write to Firestore. Check your rules and publish them.';
      default:
        return 'Failed to save data: ${e.code}';
    }
  }

  /// إنشاء/تأكيد الملف في Firestore وتخزين الهاتف.
  Future<void> _ensureProfile({
    required String uid,
    required bool isCompany,
    required String fullName,
    required String email,
    String? phone, // ⬅️ جديد
  }) async {
    final col = isCompany ? 'companies' : 'users';
    final ref = FirebaseFirestore.instance.collection(col).doc(uid);

    final data = <String, dynamic>{
      'fullName': fullName.trim(),
      'email': email.trim().toLowerCase(),
      'role': isCompany ? 'company' : 'user',
      'createdAt': FieldValue.serverTimestamp(),
      if ((phone ?? '').trim().isNotEmpty) 'phone': phone!.trim(), // ⬅️ جديد
    };

    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set(data);
    } else {
      // تحديث دمجيّ — لا نكتب createdAt مرة أخرى
      await ref.set({
        if (fullName.trim().isNotEmpty) 'fullName': fullName.trim(),
        if ((phone ?? '').trim().isNotEmpty) 'phone': phone!.trim(), // ⬅️ جديد
      }, SetOptions(merge: true));
    }
  }

  /// تحديث الهاتف لاحقًا لو حصلنا عليه من Google (غالبًا null).
  Future<void> _upsertPhoneIfAvailable(User user) async {
    final phoneFromAuth = (user.phoneNumber ?? '').trim(); // عادةً null في Google
    if (phoneFromAuth.isEmpty) return;

    final col = widget.isCompany ? 'companies' : 'users';
    await FirebaseFirestore.instance.collection(col).doc(user.uid).set({
      'phone': phoneFromAuth,
    }, SetOptions(merge: true));
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      UserCredential cred;
      bool didCreate = true;

      try {
        cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
          didCreate = false;
        } else {
          rethrow;
        }
      }

      final user = cred.user ?? FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Auth failed: no currentUser');
      }

      // اختيارياً: حدّث الاسم الظاهر في FirebaseAuth
      if (_nameController.text.trim().isNotEmpty) {
        await user.updateDisplayName(_nameController.text.trim());
      }

      // إنشاء/تحديث الملف في Firestore + الهاتف
      await _ensureProfile(
        uid: user.uid,
        isCompany: widget.isCompany,
        fullName: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text, // ⬅️ جديد
      );

      // لو جوجل بالمستقبل أعطانا رقم هاتف في user.phoneNumber
      await _upsertPhoneIfAvailable(user); // لن يغيّر شيئًا إن كان null

      // إشعارات فورية محلية
      await ForegroundNotifier.instance.start(user.uid);

      // حفظ توكن FCM
      await _saveFcmTokenForAccount(
        uid: user.uid,
        isCompany: widget.isCompany,
      );

      // إشعار داخلي
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
      } catch (_) {}

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
      _phoneController.clear();          // ⬅️ جديد
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
      debugPrint('🔥 Firestore error: code=${e.code} | message=${e.message}');
    } catch (e, st) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error: $e')),
      );
      debugPrint('❌ Unexpected error: $e\n$st');
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
            // Full name
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

            // Email
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

            // Phone (optional but recommended)
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.phone_outlined, color: Colors.grey),
                hintText: 'Phone number',
                filled: true,
                fillColor: const Color(0xFFF2F3F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              // اجعلها اختيارية أو فعّل التحقق حسب رغبتك
              validator: (v) {
                final value = (v ?? '').trim();
                if (value.isEmpty) return null; // اختياري
                // تحقق بسيط جداً
                final ok = RegExp(r'^[0-9+\-\s]{6,}$').hasMatch(value);
                return ok ? null : 'Enter a valid phone number';
              },
            ),
            const SizedBox(height: 12),

            // Password
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
