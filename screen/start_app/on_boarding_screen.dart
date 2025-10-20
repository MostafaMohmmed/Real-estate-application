import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../modle/page_view_image.dart';
import '../login_signup_app/login_in_and_sign_up.dart';

class On_Boarding_screen extends StatefulWidget {
  const On_Boarding_screen({super.key});

  @override
  State<On_Boarding_screen> createState() => _On_Boarding_screenState();
}

class _On_Boarding_screenState extends State<On_Boarding_screen> {
  final PageController pageController = PageController();

  // استعمل مفاتيح ترجمة بدل نصوص مباشرة
  final List<On_borarding_Image> listitem_view_page = [
    On_borarding_Image(
      imageList: 'assets/images/on_boarding.png',
      title: 'onb.discover.title',
      decreption: 'onb.discover.desc',
    ),
    On_borarding_Image(
      imageList: 'assets/images/on_boarding_2.png',
      title: 'onb.ideal.title',
      decreption: 'onb.ideal.desc',
    ),
    On_borarding_Image(
      imageList: 'assets/images/on_boarding_3.png',
      title: 'onb.chat.title',
      decreption: 'onb.chat.desc',
    ),
  ];

  int pageInt = 0;
  bool _didRouteOnce = false; // يمنع التنقّل المزدوج

  Future<void> _finishAndGoLogin() async {
    if (_didRouteOnce || !mounted) return;
    _didRouteOnce = true;

    final sp = await SharedPreferences.getInstance();
    await sp.setBool('onboarding_seen', true);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginAndSignUp()),
    );
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.language),
        label: Text('language'.tr()),
        onPressed: () async {
          final isArabic = context.locale.languageCode == 'ar';
          await context.setLocale(isArabic ? const Locale('en') : const Locale('ar'));
        },
      ),
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: PageView.builder(
          itemCount: listitem_view_page.length,
          controller: pageController,
          onPageChanged: (int index) => setState(() => pageInt = index),
          itemBuilder: (context, index) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final double vPad = (constraints.maxHeight * 0.05).clamp(12.0, 40.0);
                final double hPad = (constraints.maxWidth * 0.05).clamp(8.0, 32.0);
                const double reserved = 220.0;
                final double imgH = (constraints.maxHeight - vPad * 2 - reserved)
                    .clamp(100.0, constraints.maxHeight * 0.55);

                final item = listitem_view_page[index];

                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Title
                          Text(
                            item.title.tr(),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: (constraints.maxWidth * 0.05).clamp(14.0, 22.0),
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF000000),
                            ),
                          ),
                          SizedBox(height: constraints.maxHeight * 0.02),

                          // Image
                          SizedBox(
                            height: imgH,
                            width: double.infinity,
                            child: Image.asset(item.imageList, fit: BoxFit.contain),
                          ),
                          SizedBox(height: constraints.maxHeight * 0.02),

                          // Description
                          Text(
                            item.decreption.tr(),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: (constraints.maxWidth * 0.045).clamp(12.0, 18.0),
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF000000),
                            ),
                          ),
                          SizedBox(height: constraints.maxHeight * 0.03),

                          // Bottom row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: _finishAndGoLogin, // Skip
                                child: Text(
                                  'onb.actions.skip'.tr(),
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: (constraints.maxWidth * 0.04).clamp(12.0, 16.0),
                                  ),
                                ),
                              ),
                              Row(
                                children: List.generate(listitem_view_page.length, (i) {
                                  final active = pageInt == i;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: EdgeInsets.symmetric(
                                      horizontal: constraints.maxWidth * 0.01,
                                    ),
                                    width: active ? 12 : 8,
                                    height: active ? 12 : 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: active ? Colors.blue : Colors.grey[300],
                                    ),
                                  );
                                }),
                              ),
                              TextButton(
                                onPressed: () {
                                  if (pageInt == listitem_view_page.length - 1) {
                                    _finishAndGoLogin(); // Start
                                  } else {
                                    pageController.animateToPage(
                                      pageInt + 1,
                                      duration: const Duration(milliseconds: 400),
                                      curve: Curves.easeOutQuad,
                                    );
                                  }
                                },
                                child: Text(
                                  pageInt == listitem_view_page.length - 1
                                      ? 'onb.actions.start'.tr()
                                      : 'onb.actions.next'.tr(),
                                  style: GoogleFonts.inter(
                                    fontSize: (constraints.maxWidth * 0.045).clamp(12.0, 16.0),
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF4A43EC),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
