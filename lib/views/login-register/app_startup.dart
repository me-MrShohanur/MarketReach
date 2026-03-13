import 'dart:developer';

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
  late Future<bool> _loginCheckFuture;

  @override
  void initState() {
    super.initState();
    _loginCheckFuture = _checkLogin();
  }

  Future<bool> _checkLogin() async {
    final token = await AuthService().getToken();
    log(name: '🔐 AuthCheckPage', 'Token is: $token');

    return token != null && token.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _loginCheckFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        log(name: '🔐 AuthCheckPage', 'snapshot.data = ${snapshot.data}');
        log(name: '🔐 AuthCheckPage', 'snapshot.error = ${snapshot.error}');

        if (snapshot.data == true) {
          return const NavigatorView();
        }

        return const LoginView();
      },
    );
  }
}
