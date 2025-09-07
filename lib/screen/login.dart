import 'package:final_iug_2025/screen/homePage.dart';
import 'package:final_iug_2025/screen/reset_password.dart';
import 'package:final_iug_2025/screen/settings.dart';
import 'package:flutter/material.dart';

import 'Company/company_home_page.dart';

class LogIn extends StatefulWidget {
  final bool isCompany;
  const LogIn({super.key, this.isCompany = false});

  @override
  State<LogIn> createState() => _LogInState();
}

class _LogInState extends State<LogIn> {
  bool passwordVisible = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView( // ✅ عشان يمنع overflow
      child: Column(
        key: const ValueKey('login_form'),
        mainAxisSize: MainAxisSize.min,
        children: [
          // Email
          TextField(
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
              hintText: 'Email',
              filled: true,
              fillColor: const Color(0xFFF2F3F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Password
          TextField(
            obscureText: !passwordVisible,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
              suffixIcon: IconButton(
                icon: Icon(
                  passwordVisible ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () =>
                    setState(() => passwordVisible = !passwordVisible),
              ),
              hintText: 'Password',
              filled: true,
              fillColor: const Color(0xFFF2F3F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ResetPasswordPage()),
                      );
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        fontSize: 17,
                        decoration: TextDecoration.underline,
                        color: Color(0xFF6A798A),
                      ),
                    ),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (widget.isCompany) {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const CompanyHomePage()));
                  } else {
                    // login user
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const homePage()),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A43EB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  minimumSize: const Size(120, 44),
                  elevation: 0,
                ),
                child: const Text('Login',style: TextStyle(
    color: Color(0xFFFFFFFF)))
              ),
            ],
          ),
        ],
      ),
    );
  }
}
