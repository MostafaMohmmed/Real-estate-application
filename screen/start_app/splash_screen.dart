import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'on_boarding_screen.dart';

class Splash_Screen extends StatefulWidget {
  const Splash_Screen({super.key});

  @override
  State<Splash_Screen> createState() => _Splash_ScreenState();
}

class _Splash_ScreenState extends State<Splash_Screen> {
  Timer? _timer;
  bool _didRoute = false;

  @override
  void initState() {
    super.initState();
    // توجيه مرّة واحدة فقط بعد 3 ثواني
    _timer = Timer(const Duration(seconds: 3), _goNextOnce);
  }

  void _goNextOnce() {
    if (_didRoute || !mounted) return;
    _didRoute = true;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const On_Boarding_screen()),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFC),
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 0,
        backgroundColor: const Color(0xFFFCFCFC),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'images/logo_splash_2025.png',
              width: size.width * 0.8,
              height: size.height * 0.4,
              fit: BoxFit.contain,
            ),
            SizedBox(height: size.height * 0.02),
            Text(
              'ARCHETEZ',
              style: GoogleFonts.poppins(
                color: const Color(0xFF04364A),
                fontWeight: FontWeight.bold,
                fontSize: size.width * 0.1,
              ),
            ),
            SizedBox(height: size.height * 0.01),
            Text(
              'Construct Your Dreams',
              style: GoogleFonts.inter(
                color: const Color(0xFF4A43EC),
                fontWeight: FontWeight.w400,
                fontSize: size.width * 0.04,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
