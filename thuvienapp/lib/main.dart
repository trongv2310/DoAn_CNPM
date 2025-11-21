import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Thư viện Provider
import 'providers/user_provider.dart';   // Provider quản lý User
import 'providers/borrow_cart_provider.dart'; // Provider quản lý Giỏ hàng
import 'screens/login_screen.dart';

void main() {
  runApp(
    // Cung cấp Provider cho toàn bộ ứng dụng
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => BorrowCartProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ứng Dụng Thư Viện',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: LoginScreen(),
    );
  }
}