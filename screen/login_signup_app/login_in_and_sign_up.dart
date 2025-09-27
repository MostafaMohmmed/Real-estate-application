import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'sign_up.dart';
import 'login.dart';

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
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
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
                                  onSelected: (_) => setState(() => isCompany = false),
                                  selectedColor: headerColor.withOpacity(0.12),
                                ),
                                const SizedBox(width: 8),
                                ChoiceChip(
                                  label: const Text('Company'),
                                  selected: isCompany,
                                  onSelected: (_) => setState(() => isCompany = true),
                                  selectedColor: headerColor.withOpacity(0.12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // المحتوى (شاشة الدخول/التسجيل)
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
                                  isLogin ? "Don't have an account?" : 'Already have account?',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                TextButton(
                                  onPressed: () => setState(() => isLogin = !isLogin),
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
              // ما في أزرار سوشيال هنا — صارت داخل LogIn للتحكّم المنطقي.
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
