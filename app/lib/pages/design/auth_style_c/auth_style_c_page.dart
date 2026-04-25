import 'package:flutter/material.dart';
import 'login_page_c.dart';
import 'register_page_c.dart';
import 'forgot_password_page_c.dart';

class AuthStyleCPage extends StatelessWidget {
  const AuthStyleCPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TabBarView(
      children: [
        LoginPageC(),
        RegisterPageC(),
        ForgotPasswordPageC(),
      ],
    );
  }
}
