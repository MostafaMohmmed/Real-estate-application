import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'adaptive_navigation.dart';
import 'sign_up.dart';
import 'login.dart';
import 'package:easy_localization/easy_localization.dart';


class LoginAndSignUp extends StatefulWidget {
  const LoginAndSignUp({super.key});
  @override
  State<LoginAndSignUp> createState() => _LoginAndSignUpState();
}

class _LoginAndSignUpState extends State<LoginAndSignUp> {
  bool isLogin = true;
  bool isCompany = false;

  int _navIndex = 0; // للتمييز الحالي في القائمة

  void _handleNav(int index) async {
    setState(() => _navIndex = index);

    switch (index) {
      case 0: // اللغة: ما في تنقل، الاختيار من الـ Radio
        break;
      case 1: // عن الشركة
        _snack('about_company'.tr());
        break;
      case 2: // تواصل معنا
        _snack('contact_us'.tr());
        break;
      case 3: // الخصوصية
        _snack('privacy'.tr());
        break;
      case 4: // خروج
        _snack('logout'.tr());
        // TODO: نفّذ signOut وجّه المستخدم كما تريد
        break;
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {

    final headerColor = const Color(0xFF5A46FF);
    final wide = isWideScreen(context);

    final content = SafeArea(
      key: ValueKey('login_${context.locale.languageCode}'), // ✅

      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          children: [
            // الهيدر البنفسجي
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
                      padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
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
                            isLogin ? 'Login'.tr() : 'Register'.tr(),
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
                                label: Text('User'.tr()),
                                selected: !isCompany,
                                onSelected: (_) => setState(() => isCompany = false),
                                selectedColor: headerColor.withOpacity(0.12),
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: Text('Company'.tr()),
                                selected: isCompany,
                                onSelected: (_) => setState(() => isCompany = true),
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

                          // تبديل Login/Signup
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isLogin
                                    ? "Don't have an account?".tr()
                                    : 'Already have account?'.tr(),
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              TextButton(
                                onPressed: () => setState(() => isLogin = !isLogin),
                                child:
                                Text(isLogin ? 'Sign Up'.tr() : 'Login'.tr()),
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

            const SizedBox(height: 32),
          ],
        ),
      ),
    );

    // ✅ إذا الشاشة واسعة: Rail ثابت + محتوى
    // ✅ إذا ضيقة: Drawer مع أيقونة في الـ AppBar
    return Scaffold(
      appBar: wide
          ? null
          : AppBar(
        title: Text('RoofLine'.tr()),
      ),
      drawer: wide
          ? null
          : AdaptiveNavigation(
        selectedIndex: _navIndex,
        onDestinationSelected: _handleNav,
      ),
      body: Row(
        children: [
          if (wide)
            SizedBox(
              width: 88,
              child: AdaptiveNavigation(
                selectedIndex: _navIndex,
                onDestinationSelected: _handleNav,
              ),
            ),
          Expanded(child: content),
        ],
      ),
    );
  }
}
/// 🔧 هذه تضيفها تحت الكلاس أو في utils.dart
bool isWideScreen(BuildContext context) {
  return MediaQuery.of(context).size.width >= 900;
}