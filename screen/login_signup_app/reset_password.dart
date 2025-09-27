import 'dart:async'; // NEW: لإدارة المؤقّت
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // NEW: إشعار "Reset link sent"

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  // -------- Controllers --------
  final _email = TextEditingController();

  // -------- State --------
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  // ===== NEW: المؤقت للـ Resend =====
  Timer? _timer;                 // مؤقّت داخلي
  int _secondsLeft = 0;          // 0 يعني ما في تبريد (Cooldown)
  // ===================================

  // ===== NEW: حالة صحة الإيميل لتفعيل/تعطيل الزر =====
  bool _emailValid = false;      // نحدّثها onChanged
  // ===================================

  @override
  void initState() {
    super.initState();
    // (عربي) تابع تغيّر الإيميل لتفعيل/تعطيل الزر حسب Regex
    _email.addListener(() {
      final value = _email.text.trim();
      final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value);
      if (ok != _emailValid) setState(() => _emailValid = ok);
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _timer?.cancel();            // NEW: أوقف المؤقّت عند التخلص من الصفحة
    super.dispose();
  }

  // ===== NEW: تسجيل إشعار Security في Firestore (إن كان المستخدم Signed-in) =====
  Future<void> _addResetNotificationIfSignedIn() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return; // ما بنعرف uid من الإيميل لو مش Logged-in

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .add({
        'title': 'Reset link sent',
        'body': 'We sent a reset link to your email.',
        'type': 'Security',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('⚠️ Failed to add reset notification: $e');
    }
  }
  // ============================================================================

  // ===== NEW: تشغيل مؤقّت العدّاد لمدة 60 ثانية =====
  void _startCooldown() {
    setState(() => _secondsLeft = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0); // انتهى العدّاد
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }
  // ============================================================================

  // ========================= Firebase code =========================
  Future<void> _sendResetLink() async {
    // (عربي) نعمل validate للتأكد + نطبع الإيميل بشكل موحّد
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final email = _email.text.trim().toLowerCase(); // NEW: normalize

    try {
      // 📩 إرسال رابط إعادة التعيين
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      // NEW: إشعار في Firestore إن أمكن
      await _addResetNotificationIfSignedIn();

      if (!mounted) return;
      // رسالة محايدة (ما تكشف وجود الحساب)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'If an account exists for this email, a reset link has been sent.',
          ),
        ),
      );

      // NEW: ابدأ العدّاد 60 ثانية
      _startCooldown();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final map = {
        'invalid-email': 'Invalid email address.',
        'user-not-found':
        'If an account exists for this email, a reset link will be sent.',
        'network-request-failed': 'Network error. Please check your connection.',
        'too-many-requests': 'Too many attempts. Please try again later.',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(map[e.code] ?? 'Auth error: ${e.code}')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unexpected error. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  // ======================= end Firebase code =======================

  @override
  Widget build(BuildContext context) {
    final headerColor = const Color(0xFF5A46FF);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            children: [
              // ---------------- Header ----------------
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: headerColor,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 8,
                      top: 8,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    Center(
                      child: Text(
                        "Reset Password",
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // ---------------- Card ----------------
              Transform.translate(
                offset: const Offset(0, -90),
                child: Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width - 36,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Enter your email and we'll send a reset link",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Email
                        Form(
                          key: _formKey,
                          child: TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done, // NEW: زر Done
                            onFieldSubmitted: (_) {
                              // NEW: إرسال مباشر عند الضغط على Done إذا مسموح
                              if (!_loading && _secondsLeft == 0 && _emailValid) {
                                _sendResetLink();
                              }
                            },
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.email_outlined),
                              hintText: 'Email',
                              fillColor: const Color(0xFFEFF2F5),
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (v) {
                              final value = (v ?? '').trim();
                              if (value.isEmpty) return 'Email is required';
                              final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                                  .hasMatch(value);
                              return ok ? null : 'Invalid email address';
                            },
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ===== زر الإرسال =====
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: headerColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            // NEW: نعطّل الزر أيضًا لو الإيميل غير صالح
                            onPressed: (_loading || _secondsLeft > 0 || !_emailValid)
                                ? null
                                : _sendResetLink,
                            child: _loading
                                ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                                : const Text(
                              "Send reset link",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        // ===== NEW: نص العدّاد أسفل الزر =====
                        if (_secondsLeft > 0) ...[
                          const SizedBox(height: 10),
                          Center(
                            child: Text(
                              "You can resend after $_secondsLeft s",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                        // ====================================
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
