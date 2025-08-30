import 'package:flutter/material.dart';

class Sign_Up extends StatefulWidget {
  final bool isCompany;
  const Sign_Up({super.key, this.isCompany = false});

  @override
  State<Sign_Up> createState() => _Sign_UpState();
}

class _Sign_UpState extends State<Sign_Up> {
  bool passwordVisible = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView( // ✅ يمنع Overflow
      child: Column(
        key: const ValueKey('signup_form'),
        mainAxisSize: MainAxisSize.min,
        children: [
          // Full Name
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
              hintText: 'Full Name',
              filled: true,
              fillColor: const Color(0xFFF2F3F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),

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

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (widget.isCompany) {
                  // signup company
                } else {
                  // signup user
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A43EB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                minimumSize: const Size.fromHeight(52),
                elevation: 0,
              ),
              child: const Text('Register',style: TextStyle(
                color: Color(0xFFFFFFFF)
              ),),
            ),
          ),
        ],
      ),
    );
  }
}
