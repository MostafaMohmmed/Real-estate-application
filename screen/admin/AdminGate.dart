import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// يفتح ديالوج يطلب (Email + Password + PIN).
/// - يسجّل دخول بالبريد/الرمز
/// - يقرأ PIN الحقيقي من Firestore: config/admin.pin
/// - إن طابق → true (ويترك الجلسة مسجّلة)
/// - إن فشل → signOut ويرجع false
Future<bool> openAdminGate(BuildContext context) async {
  final email = TextEditingController();
  final pass = TextEditingController();
  final pin = TextEditingController();

  final formKey = GlobalKey<FormState>();
  bool obscurePass = true;
  bool obscurePin = true;

  // 1) Dialog UI — يجمع المدخلات فقط (التحققات البسيطة هنا)
  final submit = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.admin_panel_settings, size: 22),
                SizedBox(width: 8),
                Expanded(child: Text('Admin login')),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // email
                    TextFormField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Admin email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim());
                        return ok ? null : 'Invalid email';
                      },
                    ),
                    const SizedBox(height: 10),

                    // password
                    TextFormField(
                      controller: pass,
                      obscureText: obscurePass,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(obscurePass ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => obscurePass = !obscurePass),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (v.length < 6) return 'Min 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    // PIN
                    TextFormField(
                      controller: pin,
                      obscureText: obscurePin,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'PIN',
                        prefixIcon: const Icon(Icons.dialpad),
                        suffixIcon: IconButton(
                          icon: Icon(obscurePin ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => obscurePin = !obscurePin),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (v.trim().length < 4) return 'Too short';
                        return null;
                      },
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Enter admin credentials to open the Admin Panel.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop(false);
                },
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  // Validate here; if ok, pop true and continue the auth logic outside dialog
                  if (formKey.currentState?.validate() ?? false) {
                    Navigator.of(ctx).pop(true);
                  }
                },
                child: const Text('Continue'),
              ),
            ],
          );
        },
      );
    },
  );

  // إذا المستخدم لغى
  if (submit != true) return false;

  // 2) بعد جمع القيم — ننفّذ عملية التسجيل والتحقق من PIN كما في الأصل
  try {
    // تسجيل دخول بالبريد/الباس
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email.text.trim(),
      password: pass.text,
    );

    // قراءة PIN من Firestore (config/admin.pin)
    final snap = await FirebaseFirestore.instance.collection('config').doc('admin').get();
    final realPin = (snap.data()?['pin'] ?? '').toString();

    if (pin.text.trim() == realPin && realPin.isNotEmpty) {
      // نجاح — نبقى مسجلين الدخول ونرجع true
      return true;
    }

    // PIN خطأ → نخرج ونسجل الخروج
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wrong PIN')),
      );
    }
    return false;
  } on FirebaseAuthException catch (e) {
    // خطأ مصادقة (مثل wrong-password, user-not-found ...)
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Auth failed: ${e.code}')),
      );
    }
    return false;
  } on FirebaseException catch (e) {
    // خطأ Firestore (مثلاً permission-denied لو البريد غير مسموح بالقواعد)
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${e.code}')),
      );
    }
    await FirebaseAuth.instance.signOut();
    return false;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
    await FirebaseAuth.instance.signOut();
    return false;
  } finally {
    // تنظيف controllers (اختياري)
    email.dispose();
    pass.dispose();
    pin.dispose();
  }
}
