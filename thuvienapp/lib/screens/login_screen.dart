import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
import '../providers/api_service.dart';
import '../providers/user_provider.dart'; // Import UserProvider
import 'home_screen.dart';
import 'dangky.dart';

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
      // LƯU USER VÀO PROVIDER ĐỂ DÙNG TOÀN APP
      // listen: false vì ta chỉ gọi hàm, không cần rebuild giao diện ở đây
      Provider.of<UserProvider>(context, listen: false).setUser(user);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Xin chào ${user.hoVaTen}!")));

      // Chuyển sang HomeScreen (gửi user kèm theo để tương thích code cũ)
      Navigator.pushReplacement(
        context,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Chưa có tài khoản? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RegisterScreen())
                        );
                      },
                      child: const Text(
                          "Đăng ký ngay",
                          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

}