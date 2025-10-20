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
  final pin  = TextEditingController();

  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: const Text('Admin login'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Admin email',
              hintText: 'admin@gmail.com',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: pass,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: pin,
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'PIN', hintText: '123456'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Continue')),
      ],
    ),
  );

  if (ok != true) return false;

  try {
    // 1) تسجيل دخول بالبريد/الباس
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email.text.trim(),
      password: pass.text,
    );

    // 2) قراءة PIN من Firestore (محمي بالقواعد isAdminEmail)
    final snap = await FirebaseFirestore.instance.collection('config').doc('admin').get();
    final realPin = (snap.data()?['pin'] ?? '').toString();

    if (pin.text.trim() == realPin && realPin.isNotEmpty) {
      return true; // ✅ مسموح
    }

    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wrong PIN')));
    }
    return false;
  } on FirebaseAuthException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Auth failed: ${e.code}')));
    }
    return false;
  } on FirebaseException catch (e) {
    // لو البريد مش ضمن isAdminEmail → permission-denied
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${e.code}')));
    }
    await FirebaseAuth.instance.signOut();
    return false;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    await FirebaseAuth.instance.signOut();
    return false;
  }
}
