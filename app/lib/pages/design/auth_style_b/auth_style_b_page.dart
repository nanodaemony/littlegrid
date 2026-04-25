import 'package:flutter/material.dart';
import 'login_page_b.dart';
import 'register_page_b.dart';
import 'forgot_password_page_b.dart';

class AuthStyleBPage extends StatelessWidget {
  const AuthStyleBPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TabBarView(
      children: [
        LoginPageB(),
        RegisterPageB(),
        ForgotPasswordPageB(),
      ],
    );
  }
}
