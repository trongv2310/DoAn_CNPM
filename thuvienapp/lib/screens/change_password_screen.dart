import 'package:flutter/material.dart';
import '../models/user.dart';
import '../providers/api_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  final User user;
  const ChangePasswordScreen({Key? key, required this.user}) : super(key: key);

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _oldPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  void _submit() async {
    if (_newPassController.text != _confirmPassController.text) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Mật khẩu xác nhận không khớp!")));
      return;
    }
    if (_newPassController.text.isEmpty) return;

    setState(() => _isLoading = true);
    bool success = await _apiService.doiMatKhau(widget.user.maTaiKhoan, _oldPassController.text, _newPassController.text);
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đổi mật khẩu thành công!")));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Mật khẩu cũ không đúng!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Đổi Mật Khẩu")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(controller: _oldPassController, obscureText: true, decoration: InputDecoration(labelText: "Mật khẩu cũ", border: OutlineInputBorder())),
            SizedBox(height: 15),
            TextField(controller: _newPassController, obscureText: true, decoration: InputDecoration(labelText: "Mật khẩu mới", border: OutlineInputBorder())),
            SizedBox(height: 15),
            TextField(controller: _confirmPassController, obscureText: true, decoration: InputDecoration(labelText: "Nhập lại mật khẩu mới", border: OutlineInputBorder())),
            SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading ? CircularProgressIndicator() : Text("LƯU THAY ĐỔI"),
              ),
            )
          ],
        ),
      ),
    );
  }
}