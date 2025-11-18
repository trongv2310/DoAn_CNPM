import 'package:flutter/material.dart';
import '../providers/api_service.dart';
import 'home_screen.dart';
import 'storekeeper/storekeeper_home.dart';

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

    // Gọi hàm login từ ApiService
    final user = await _apiService.login(_userController.text, _passController.text);

    setState(() => _isLoading = false);

    if (user != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Xin chào ${user.hoVaTen}!")));

      // ĐIỀU HƯỚNG DỰA VÀO QUYỀN (MAQUYEN)
      // 1: Admin, 2: Thủ thư, 3: Thủ kho, 4: Độc giả (Check lại DB để chắc chắn số)
      if (user.maQuyen == 3) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => StoreKeeperHomeScreen(user: user)));
      } else {
        // Mặc định hoặc Độc giả về Home cũ
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
      }
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