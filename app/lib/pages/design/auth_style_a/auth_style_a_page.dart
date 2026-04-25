import 'package:flutter/material.dart';
import 'login_page_a.dart';
import 'register_page_a.dart';
import 'forgot_password_page_a.dart';

class AuthStyleAPage extends StatelessWidget {
  const AuthStyleAPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TabBarView(
      children: [
        LoginPageA(),
        RegisterPageA(),
        ForgotPasswordPageA(),
      ],
    );
  }
}