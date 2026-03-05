import 'package:flutter/material.dart';
import 'package:marketing/services/auth_service.dart';
import 'package:marketing/views/home/navigator_view.dart';
import 'package:marketing/views/login-register/login.dart';

class AuthCheckPage extends StatefulWidget {
  const AuthCheckPage({super.key});

  @override
  State<AuthCheckPage> createState() => _AuthCheckPageState();
}

class _AuthCheckPageState extends State<AuthCheckPage> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService().isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) {
          return NavigatorView();
        }

        return const LoginView();
      },
    );
  }
}
