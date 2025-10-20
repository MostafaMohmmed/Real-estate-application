import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';

// مشروعك
import 'screen/firebase_options/firebase_options.dart';
import 'screen/start_app/splash_screen.dart';
import 'screen/login_signup_app/login_in_and_sign_up.dart';
import 'services/foreground_notifier.dart';
import 'services/fcm_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await ForegroundNotifier.instance.init();
  await FirebaseMessaging.instance.requestPermission();

  final sp = await SharedPreferences.getInstance();
  final seenOnboarding = sp.getBool('onboarding_seen') ?? false;

  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      saveLocale: true,
      child: MyApp(seenOnboarding: seenOnboarding),
    ),
  );
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setupMessageHandlers(navigatorKey);
    });
  }

  @override
  Widget build(BuildContext context) {
    final homeWidget =
    widget.seenOnboarding ?  LoginAndSignUp() : const Splash_Screen();

    return ScreenUtilInit(
      designSize: const Size(1080, 2340),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: const Color(0xFF5A46FF),
            brightness: Brightness.light,
          ),
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          home: homeWidget,
        );
      },
    );
  }
}
