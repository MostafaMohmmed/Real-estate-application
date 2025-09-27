import 'package:flutter/material.dart';

// ===== NEW: Firebase Auth لتغيير كلمة السر =====
import 'package:firebase_auth/firebase_auth.dart'; // updatePassword(), reauthenticateWithCredential()
// ===== NEW: Cloud Firestore لتسجيل إشعار نجاح التغيير =====
import 'package:cloud_firestore/cloud_firestore.dart'; // users/{uid}/notifications
// ================================================

class ChangePassword extends StatefulWidget {
  const ChangePassword({super.key});

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // ===== NEW: حقول التحكم بالنص + حالة زر التحميل =====
  final TextEditingController _newCtrl = TextEditingController();     // كلمة السر الجديدة
  final TextEditingController _confirmCtrl = TextEditingController(); // تأكيد كلمة السر
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false; // loader
  // =================================================================

  @override
  void dispose() {
    // تنظيف الـ Controllers لمنع تسريب الذاكرة
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ===== مساعد لعرض SnackBar =====
  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
  // ==================================================================

  // ===== NEW: إضافة إشعار داخل Firestore بعد النجاح =====
  Future<void> _addNotificationSecurityUpdated(String uid) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .add({
        'title': 'Password updated',
        'body': 'Your password has been changed.',
        'type': 'Security', // لفلترة الإشعارات لاحقاً
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // لو فشل تسجيل الإشعار، لا نوقف العملية — فقط لوج
      debugPrint('⚠️ Failed to add notification: $e');
    }
  }
  // ==================================================================

  // ===== NEW: Dialog يطلب كلمة المرور الحالية لإعادة المصادقة (email/password فقط) =====
  Future<String?> _askCurrentPasswordDialog() async {
    final ctrl = TextEditingController();
    String? result;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Re-authentication required'),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Current password',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              result = null;
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              result = ctrl.text.trim();
              Navigator.pop(context);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result;
  }
  // ==================================================================

  // ===== NEW: إعادة المصادقة عبر كلمة المرور ثم إعادة المحاولة =====
  Future<bool> _reauthWithPasswordAndRetry({
    required User user,
    required String newPass,
  }) async {
    // هذه الطريقة مناسبة لحسابات email/password فقط
    final email = user.email;
    if (email == null) {
      _showSnack('Please sign in again and retry.');
      return false;
    }
    final current = await _askCurrentPasswordDialog();
    if (current == null || current.isEmpty) {
      _showSnack('Operation cancelled.');
      return false;
    }

    try {
      final cred = EmailAuthProvider.credential(email: email, password: current);
      await user.reauthenticateWithCredential(cred); // إعادة مصادقة ناجحة
      await user.updatePassword(newPass);            // أعِد المحاولة
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        _showSnack('Current password is incorrect.');
      } else {
        _showSnack('Re-authentication failed: ${e.code}');
      }
      return false;
    } catch (_) {
      _showSnack('Unexpected error during re-auth.');
      return false;
    }
  }
  // ==================================================================

  // ===== NEW: الدالة الأساسية لتغيير كلمة السر =====
  Future<void> _handleResetPassword() async {
    if (_isSubmitting) return;              // حماية من النقر المزدوج
    setState(() => _isSubmitting = true);   // شغّل اللودر

    try {
      // 0) التحقق من مزوّد تسجيل الدخول:
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnack('You are not signed in.');
        setState(() => _isSubmitting = false);
        return;
      }

      // (عربي) لو المستخدم مسجل بجوجل/آبل/فيسبوك، تغيير الباسورد مباشرة غير منطقي.
      // الافضل توجهه لاستخدام "Reset Password" بالإيميل أو إعادة المصادقة مع مزود الهوية.
      final isPasswordProvider = user.providerData.any((p) => p.providerId == 'password');
      if (!isPasswordProvider) {
        _showSnack(
          'This account uses a social provider. Please use "Reset Password" via email or re-sign in with the provider.',
        );
        setState(() => _isSubmitting = false);
        return;
      }

      // 1) التحقق المحلي من القيم
      final newPass = _newCtrl.text.trim();
      final confirm = _confirmCtrl.text.trim();

      // سياسة بسيطة: 10 أحرف كحد أدنى (مطابقة للكرت)
      if (newPass.isEmpty || confirm.isEmpty) {
        _showSnack('Please fill all required fields.');
        setState(() => _isSubmitting = false);
        return;
      }
      if (newPass.length < 10) {
        _showSnack('Password must be at least 10 characters.');
        setState(() => _isSubmitting = false);
        return;
      }
      if (newPass != confirm) {
        _showSnack('Passwords do not match.');
        setState(() => _isSubmitting = false);
        return;
      }

      // 2) تنفيذ التحديث عبر Firebase
      try {
        await user.updatePassword(newPass);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          // يتطلب إعادة مصادقة: نطلب الباسورد الحالي ونعيد المحاولة
          final ok = await _reauthWithPasswordAndRetry(user: user, newPass: newPass);
          if (!ok) {
            setState(() => _isSubmitting = false);
            return;
          }
        } else {
          rethrow;
        }
      }

      // 3) نجاح: إشعار + واجهة
      await _addNotificationSecurityUpdated(user.uid); // سجل إشعار Security في Firestore
      _showSnack('Password updated successfully.');
      _newCtrl.clear();
      _confirmCtrl.clear();
    } on FirebaseAuthException catch (e) {
      // أخطاء Auth الشائعة
      if (e.code == 'weak-password') {
        _showSnack('Password is too weak. Try a stronger one.');
      } else {
        _showSnack('Failed to update password: ${e.message ?? e.code}.');
      }
    } catch (e) {
      _showSnack('Unexpected error occurred.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false); // أطفئ اللودر
    }
  }
  // ===================================================================

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const primaryColor = Color(0xff22577A);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Change Password",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.06,
            vertical: size.height * 0.02,
          ),
          child: Form(
            key: _formKey, // (اختياري) جاهز لو حبيت تضيف Validators لاحقًا
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// أيقونة
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: size.width * 0.13,
                        backgroundColor: Colors.grey.shade200,
                        child: Icon(
                          Icons.lock_reset,
                          color: primaryColor,
                          size: size.width * 0.15,
                        ),
                      ),
                      SizedBox(height: size.height * 0.02),
                      Text(
                        "Change Your Password",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: size.width * 0.045,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: size.height * 0.01),
                      Text(
                        "Enter a new password below to change your password.",
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: size.width * 0.035,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: size.height * 0.04),

                /// New Password
                Text(
                  "New Password*",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: size.width * 0.04,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),

                // ===== ربط الحقل بـ _newCtrl =====
                TextFormField(
                  controller: _newCtrl,
                  obscureText: _obscureNew,
                  decoration: InputDecoration(
                    hintText: "Enter new password",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 12,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNew ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureNew = !_obscureNew;
                        });
                      },
                    ),
                  ),
                ),

                SizedBox(height: size.height * 0.02),

                /// Confirm Password
                Text(
                  "Re-enter New Password*",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: size.width * 0.04,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),

                // ===== ربط الحقل بـ _confirmCtrl =====
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    hintText: "Confirm new password",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 12,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirm = !_obscureConfirm;
                        });
                      },
                    ),
                  ),
                ),

                SizedBox(height: size.height * 0.03),

                /// Password Rules
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Your password must contain:",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.done, color: Color(0xFF08905E), size: 20),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                "At least 10 characters in length",
                                style: TextStyle(fontSize: 14, color: Color(0xFF08905E)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: size.height * 0.05),

                /// Reset Button
                SizedBox(
                  width: double.infinity,
                  height: size.height * 0.07,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    // ===== زر يربط الدالة الكاملة (تشمل reauth + إشعار) =====
                    onPressed: _isSubmitting ? null : _handleResetPassword,
                    child: _isSubmitting
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : Text(
                      "Reset Password",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size.width * 0.045,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
