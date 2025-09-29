import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../firebase_options/firebase_options.dart';

// شاشات البداية/الدخول
import 'splash_screen.dart';
import '../login_signup_app/login_in_and_sign_up.dart';

// إشعارات محلية (اختياري)
import '../../services/foreground_notifier.dart';

// خدمة FCM: حفظ التوكن + فتح الشات عند الضغط على الإشعار
import '../../services/fcm_service.dart'; // تأكد من المسار

// تفضيلات محلية
import 'package:shared_preferences/shared_preferences.dart';

/// مفتاح Navigator عالمي لاستخدامه مع الإشعارات
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// هاندلر رسائل FCM بالخلفية (لازم يكون top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // لازم تهيئة Firebase داخل Isolate الخلفية
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // تقدر تضيف لوج هنا لو حبيت
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // تسجيل هاندلر الخلفية
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // (اختياري) تهيئة الإشعارات المحلية
  await ForegroundNotifier.instance.init();

  // طلب صلاحية الإشعارات (iOS / Android 13+)
  await FirebaseMessaging.instance.requestPermission();

  // هل شوهد الـ Onboarding؟
  final sp = await SharedPreferences.getInstance();
  final seenOnboarding = sp.getBool('onboarding_seen') ?? false;

  runApp(MyApp(seenOnboarding: seenOnboarding));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.seenOnboarding});
  final bool seenOnboarding;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // تسجيل مستمعي رسائل FCM لفتح الشات عند الضغط على الإشعار
    // (نستدعيها مرة واحدة بعد بناء الـ context)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setupMessageHandlers(navigatorKey); // موجودة داخل services/fcm_service.dart
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(1080, 2340),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey, // مهم لفتح الشات من الإشعار
          home: child,
        );
      },
      // لو شوهد الـ Onboarding → نذهب مباشرة لواجهة الدخول
      child: widget.seenOnboarding ? const LoginAndSignUp() : const Splash_Screen(),
    );
  }
}
