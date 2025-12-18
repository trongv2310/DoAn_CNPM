import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import thư viện này để đọc file .env

// Import các màn hình và providers của bạn
import 'screens/login_screen.dart';
import 'providers/user_provider.dart';
import 'providers/borrow_cart_provider.dart';

void main() async {
  // 1. Đảm bảo Flutter Binding đã được khởi tạo
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Load file .env (QUAN TRỌNG: File này phải nằm ở thư mục gốc của dự án)
  // Nếu chưa tạo file .env, code sẽ báo lỗi ở đây.
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("Không tìm thấy file .env. Hãy tạo file .env ở thư mục gốc và thêm GEMINI_API_KEY vào đó.");
  }

  // 3. Chạy ứng dụng
  runApp(
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
      title: 'Quản Lý Thư Viện',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // Màn hình đầu tiên là Login
      home: LoginScreen(),
    );
  }
}