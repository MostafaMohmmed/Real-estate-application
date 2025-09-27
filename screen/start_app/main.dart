import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options/firebase_options.dart';
import 'splash_screen.dart';
import '../login_signup_app/login_in_and_sign_up.dart';

// إشعارات (لو عندك هذه الخدمات)
import '../../services/foreground_notifier.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// NEW
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // (اختياري) تهيئة الإشعارات المحلية + القناة
  await ForegroundNotifier.instance.init();

  // (اختياري) طلب صلاحية الإشعارات
  await FirebaseMessaging.instance.requestPermission();

  // NEW: نقرأ هل الـ Onboarding تمّ
  final sp = await SharedPreferences.getInstance();
  final seenOnboarding = sp.getBool('onboarding_seen') ?? false;

  runApp(MyApp(seenOnboarding: seenOnboarding));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.seenOnboarding});
  final bool seenOnboarding;

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(1080, 2340),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: child,
        );
      },
      // NEW: لو شوهد الـ Onboarding → نروح مباشرة لواجهة الدخول
      child: seenOnboarding ? LoginAndSignUp() : const Splash_Screen(),
    );
  }
}
