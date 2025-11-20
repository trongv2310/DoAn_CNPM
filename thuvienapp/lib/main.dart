// FILE: main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';  // 1. THÊM import này
import 'providers/user_provider.dart';   // 2. THÊM import này
import 'providers/borrow_cart_provider.dart'; // 3. THÊM import này
import 'screens/login_screen.dart';

void main() {
  runApp(
    // 4. BỌC 'MyApp' bằng 'MultiProvider'
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
      home: LoginScreen(), // Màn hình đầu tiên vẫn là Login
    );
  }
}