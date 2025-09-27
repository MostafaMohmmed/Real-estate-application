// lib/screen/company/company_change_password.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyChangePassword extends StatefulWidget {
  const CompanyChangePassword({super.key});

  @override
  State<CompanyChangePassword> createState() => _CompanyChangePasswordState();
}

class _CompanyChangePasswordState extends State<CompanyChangePassword> {
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _addCompanySecurityNotification(String uid) async {
    try {
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(uid)
          .collection('notifications')
          .add({
        'title': 'Password updated',
        'body': 'Your company password has been changed.',
        'type': 'Security',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // لا توقف العملية لو فشل تسجيل الإشعار
    }
  }

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
          decoration: const InputDecoration(labelText: 'Current password'),
        ),
        actions: [
          TextButton(
            onPressed: () { result = null; Navigator.pop(context); },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () { result = ctrl.text.trim(); Navigator.pop(context); },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result;
  }

  Future<bool> _reauthWithPasswordAndRetry({
    required User user,
    required String newPass,
  }) async {
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
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPass);
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

  Future<void> _handleResetPassword() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnack('You are not signed in.');
        setState(() => _isSubmitting = false);
        return;
      }

      final isPasswordProvider = user.providerData.any((p) => p.providerId == 'password');
      if (!isPasswordProvider) {
        _showSnack(
          'This account uses a social provider. Use email reset or sign in again with the provider.',
        );
        setState(() => _isSubmitting = false);
        return;
      }

      final newPass = _newCtrl.text.trim();
      final confirm = _confirmCtrl.text.trim();

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

      try {
        await user.updatePassword(newPass);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          final ok = await _reauthWithPasswordAndRetry(user: user, newPass: newPass);
          if (!ok) {
            setState(() => _isSubmitting = false);
            return;
          }
        } else {
          rethrow;
        }
      }

      await _addCompanySecurityNotification(user.uid);
      _showSnack('Password updated successfully.');
      _newCtrl.clear();
      _confirmCtrl.clear();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        _showSnack('Password is too weak. Try a stronger one.');
      } else {
        _showSnack('Failed to update password: ${e.message ?? e.code}.');
      }
    } catch (_) {
      _showSnack('Unexpected error occurred.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

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
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: size.width * 0.13,
                        backgroundColor: Colors.grey.shade200,
                        child: Icon(Icons.lock_reset, color: primaryColor, size: size.width * 0.15),
                      ),
                      SizedBox(height: size.height * 0.02),
                      Text("Change Your Password",
                          style: TextStyle(
                              color: Colors.black, fontSize: size.width * 0.045, fontWeight: FontWeight.bold)),
                      SizedBox(height: size.height * 0.01),
                      Text(
                        "Enter a new password below to change your password.",
                        style: TextStyle(color: Colors.grey[700], fontSize: size.width * 0.035),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: size.height * 0.04),

                Text("New Password*",
                    style: TextStyle(color: Colors.black, fontSize: size.width * 0.04, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _newCtrl,
                  obscureText: _obscureNew,
                  decoration: InputDecoration(
                    hintText: "Enter new password",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscureNew = !_obscureNew),
                    ),
                  ),
                ),

                SizedBox(height: size.height * 0.02),

                Text("Re-enter New Password*",
                    style: TextStyle(color: Colors.black, fontSize: size.width * 0.04, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    hintText: "Confirm new password",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                ),

                SizedBox(height: size.height * 0.03),

                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Your password must contain:",
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.done, color: Color(0xFF08905E), size: 20),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text("At least 10 characters in length",
                                  style: TextStyle(fontSize: 14, color: Color(0xFF08905E))),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: size.height * 0.05),

                SizedBox(
                  width: double.infinity,
                  height: size.height * 0.07,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
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
                        : Text("Reset Password",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: size.width * 0.045,
                            fontWeight: FontWeight.bold)),
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
