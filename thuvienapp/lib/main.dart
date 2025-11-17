import 'package:flutter/material.dart';
// Import màn hình đăng nhập để gọi nó đầu tiên
import 'screens/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Tắt chữ "Debug" màu đỏ ở góc phải
      title: 'Ứng Dụng Thư Viện',

      // Cấu hình màu sắc chủ đạo cho toàn App
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true, // Sử dụng chuẩn thiết kế mới đẹp hơn
        scaffoldBackgroundColor: Colors.white,
      ),

      // QUAN TRỌNG: Màn hình đầu tiên chạy là Đăng Nhập
      home: LoginScreen(),
    );
  }
}