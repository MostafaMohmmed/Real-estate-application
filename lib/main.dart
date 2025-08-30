import 'package:final_iug_2025/screen/homePage.dart';
import 'package:final_iug_2025/screen/login_in_and_sign_up.dart';
import 'package:final_iug_2025/screen/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(1080, 2340), // ✅ تم تحديث الحجم
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false, // ✅ لغينا شارة الـ Debug
          home: child,
        );
      },
      child: const Splash_Screen(),
    );
  }
}
