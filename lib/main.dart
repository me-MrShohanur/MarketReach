import 'package:flutter/material.dart';
import 'package:marketing/constants/routes.dart';
import 'package:marketing/views/home/home_view.dart';
import 'package:marketing/views/login-register/login.dart';
import 'package:marketing/views/login-register/register.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      routes: {
        loginRoute: (context) => const LoginView(),
        registerRoute: (context) => const RegisterView(),
      },
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: LoginView(),
    );
  }
}
