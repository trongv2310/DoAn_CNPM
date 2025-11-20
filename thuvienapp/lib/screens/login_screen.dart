import 'package:flutter/material.dart';
import '../providers/api_service.dart';
import 'package:provider/provider.dart';     // 1. THÊM DÒNG NÀY
import '../providers/user_provider.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  void _handleLogin() async {
    setState(() => _isLoading = true);

    final user = await _apiService.login(_userController.text, _passController.text);

    setState(() => _isLoading = false);

    if (user != null) {
      // --- THÊM DÒNG NÀY ---
      // Lưu user vào provider để toàn bộ app có thể truy cập
      Provider.of<UserProvider>(context, listen: false).setUser(user);
      // --- HẾT PHẦN THÊM ---

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Xin chào ${user.hoVaTen}!")));
      Navigator.pushReplacement(
        context,
        // SỬA DÒNG NÀY: Truyền biến user vào HomeScreen
        MaterialPageRoute(builder: (_) => HomeScreen(user: user)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Sai tài khoản hoặc mật khẩu!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.library_books, size: 80, color: Colors.blue),
                SizedBox(height: 20),
                Text("ĐĂNG NHẬP", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 30),
                TextField(
                  controller: _userController,
                  decoration: InputDecoration(labelText: "Tài khoản", border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _passController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: "Mật khẩu", border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
                ),
                SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading ? CircularProgressIndicator(color: Colors.white) : Text("Đăng Nhập"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}