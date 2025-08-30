import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../modle/page_view_image.dart';
import 'homePage.dart';
import 'login_in_and_sign_up.dart';

class On_Boarding_screen extends StatefulWidget {
  const On_Boarding_screen({super.key});

  @override
  State<On_Boarding_screen> createState() => _On_Boarding_screenState();
}

class _On_Boarding_screenState extends State<On_Boarding_screen> {
  PageController pageController = PageController();
  List<On_borarding_Image> listitem_view_page = [
    On_borarding_Image(
      imageList: 'images/on_boarding.png',
      title: '''Discover Properties Around You
                ''',
      decreption: '''Find houses, apartments, or land with
an interactive map covering all regions 
                and neighborhoods.
''',
    ),
    On_borarding_Image(
      imageList: 'images/on_boarding_2.png',
      title: '''Your Ideal Property, Just a Tap Away
      ''',
      decreption: '''Looking to buy or rent? Easily filter 
listings to match your exact needs
                       and budget.
      ''',
    ),
    On_borarding_Image(
      imageList: 'images/on_boarding_3.png',
      title: '''Chat Directly with Owners and Agents
      ''',
      decreption: '''Message property owners in real-time 
get updates, and close deals faster—no
                       middlemen.
''',
    ),
  ];

  int pageInt = 0;

  @override
  void initState() {
    pageController = PageController(initialPage: 0);
    super.initState();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: false, // يمنع التصغير عند فتح الكيبورد ويحل بعض الـoverflow
      backgroundColor: Colors.white,
      body: SafeArea(
        child: PageView.builder(
          itemCount: listitem_view_page.length,
          controller: pageController,
          onPageChanged: (int index) {
            setState(() {
              pageInt = index;
            });
          },
          itemBuilder: (context, index) {
            // نستخدم LayoutBuilder للحصول على الارتفاع المتاح بدقّة
            return LayoutBuilder(
              builder: (context, constraints) {
                // مسافة padding رأسياً (نستخدم clamp لمنع قيم كبيرة على شاشات صغيرة/كبيرة)
                final double verticalPadding = (constraints.maxHeight * 0.05).clamp(12.0, 40.0);
                final double horizontalPadding = (constraints.maxWidth * 0.05).clamp(8.0, 32.0);

                // نخصم بعض المساحات للـ title و description و bottom row
                // ونحسب ارتفاع الصورة كجزء من المساحة المتبقية
                final double reservedForTextAndButtons = 220.0; // تقديري، يمكن تعديله
                final double availableForImage = (constraints.maxHeight - verticalPadding * 2 - reservedForTextAndButtons)
                    .clamp(100.0, constraints.maxHeight * 0.55);

                return SingleChildScrollView(
                  // نضع minHeight = available height حتى يظهر المحتوى بارتفاع الصفحة ولو لم يكفي
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding, vertical: verticalPadding),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        // لا تستخدم mainAxisAlignment.center لأننا نريد أن تكون العناصر قابلة للتمدد والتمرير
                        children: [
                          // Title
                          Text(
                            listitem_view_page[index].title,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: (constraints.maxWidth * 0.05).clamp(14.0, 22.0),
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF000000),
                            ),
                          ),

                          SizedBox(height: constraints.maxHeight * 0.02),

                          // الصورة بارتفاع محسوب من availableForImage
                          SizedBox(
                            height: availableForImage,
                            width: double.infinity,
                            child: Image.asset(
                              listitem_view_page[index].imageList,
                              fit: BoxFit.contain,
                            ),
                          ),

                          SizedBox(height: constraints.maxHeight * 0.02),

                          // Description (حجم الخط مرن)
                          Text(
                            listitem_view_page[index].decreption,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: (constraints.maxWidth * 0.045).clamp(12.0, 18.0),
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF000000),
                            ),
                          ),

                          SizedBox(height: constraints.maxHeight * 0.03),

                          // Bottom row (Skip / Dots / Next)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () {
                                  // skip action
                                },
                                child: Text(
                                  "Skip",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: (constraints.maxWidth * 0.04).clamp(12.0, 16.0),
                                  ),
                                ),
                              ),
                              Row(
                                children: List.generate(listitem_view_page.length, (i) {
                                  return Container(
                                    margin: EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.01),
                                    width: (constraints.maxWidth * 0.025).clamp(6.0, 12.0),
                                    height: (constraints.maxWidth * 0.025).clamp(6.0, 12.0),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: pageInt == i ? Colors.blue : Colors.grey[300],
                                    ),
                                  );
                                }),
                              ),
                              TextButton(
                                onPressed: () {
                                  if (pageInt == listitem_view_page.length - 1) {
                                    Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(builder: (context) => LoginAndSignUp()));
                                  } else {
                                    pageController.animateToPage(
                                      pageInt + 1,
                                      duration: const Duration(milliseconds: 500),
                                      curve: Curves.easeOutQuad,
                                    );
                                  }
                                },
                                child: Text(
                                  pageInt == listitem_view_page.length - 1 ? "Start" : "Next",
                                  style: GoogleFonts.inter(
                                    fontSize: (constraints.maxWidth * 0.045).clamp(12.0, 16.0),
                                    fontWeight: FontWeight.w500,
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