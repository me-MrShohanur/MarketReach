import 'package:flutter/material.dart';
import 'package:marketing/constants/routes.dart';
import 'package:marketing/views/home/create_order_view.dart';
import 'package:marketing/views/home/navigator_view.dart';
import 'package:marketing/views/login-register/app_startup.dart';
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
        homeRoute: (context) => const NavigatorView(),
        createOrderRoute: (context) => const CreateOrderView(),
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const AuthCheckPage(),
    );
  }
}
