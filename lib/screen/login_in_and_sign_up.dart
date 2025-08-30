import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login.dart';
import 'sign_up.dart';

class LoginAndSignUp extends StatefulWidget {
  const LoginAndSignUp({super.key});
  @override
  State<LoginAndSignUp> createState() => _LoginAndSignUpState();
}

class _LoginAndSignUpState extends State<LoginAndSignUp> {
  bool isLogin = true;
  bool isCompany = false; // اختيار شركة/مستخدم

  @override
  Widget build(BuildContext context) {
    final headerColor = const Color(0xFF5A46FF);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24, // يرفع المحتوى مع الكيبورد
          ),
          child: Column(
            children: [
              // الهيدر الأزرق
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
              ),

              // الكارد
              Transform.translate(
                offset: const Offset(0, -90),
                child: Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
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
                          children: [
                            Text(
                              isLogin ? 'Login' : 'Register',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // اختيار نوع الحساب
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ChoiceChip(
                                  label: const Text('User'),
                                  selected: !isCompany,
                                  onSelected: (_) =>
                                      setState(() => isCompany = false),
                                  selectedColor: headerColor.withOpacity(0.12),
                                ),
                                const SizedBox(width: 8),
                                ChoiceChip(
                                  label: const Text('Company'),
                                  selected: isCompany,
                                  onSelected: (_) =>
                                      setState(() => isCompany = true),
                                  selectedColor: headerColor.withOpacity(0.12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // المحتوى
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              transitionBuilder: (child, anim) =>
                                  FadeTransition(opacity: anim, child: child),
                              child: isLogin
                                  ? LogIn(isCompany: isCompany)
                                  : Sign_Up(isCompany: isCompany),
                            ),

                            const SizedBox(height: 10),

                            // زر التبديل
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isLogin
                                      ? "Don't have an account?"
                                      : 'Already have account?',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      setState(() => isLogin = !isLogin),
                                  child: Text(isLogin ? 'Sign Up' : 'Login'),
                                )
                              ],
                            ),
                          ],
                        ),
                      ),

                      // الزخرفة البنفسجية
                      Positioned(
                        top: -14,
                        left: (MediaQuery.of(context).size.width - 36) / 2 - 60,
                        child: Container(
                          width: 120,
                          height: 28,
                          decoration: BoxDecoration(
                            color: headerColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: headerColor.withOpacity(0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // سوشيال
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _circleSocial(icon: Icons.facebook),
                        const SizedBox(width: 12),
                        _circleSocial(icon: Icons.g_mobiledata),
                        const SizedBox(width: 12),
                        _circleSocial(icon: Icons.apple),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32), // بدل Expanded
            ],
          ),
        ),
      ),
    );
  }

  static Widget _circleSocial({required IconData icon}) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Color(0xFFD5DEE7), width: 2),
        color: Colors.white,
      ),
      child: Icon(icon, size: 28, color: Colors.black54),
    );
  }
}
