import 'package:flutter/material.dart';
import '../providers/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  // Controllers
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  String _selectedGender = "Nam";
  DateTime _dob = DateTime(2000, 1, 1);

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passController.text != _confirmPassController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Mật khẩu xác nhận không khớp!"), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    final userData = {
      "TenDangNhap": _userController.text,
      "MatKhau": _passController.text,
      "HoVaTen": _nameController.text,
      "GioiTinh": _selectedGender,
      "NgaySinh": _dob.toIso8601String(),
      "Sdt": _phoneController.text,
      "Email": _emailController.text
    };

    final result = await _apiService.register(userData);

    setState(() => _isLoading = false);

    if (result['success']) {
      // Thành công -> Quay về Login và báo tin
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message']), backgroundColor: Colors.green));
      Navigator.pop(context);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message']), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Đăng Ký Tài Khoản"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Icon(Icons.person_add_alt_1, size: 60, color: Colors.blueAccent),
              const SizedBox(height: 20),

              _buildTextField(_userController, "Tên đăng nhập", Icons.account_circle),
              const SizedBox(height: 15),
              _buildTextField(_nameController, "Họ và tên", Icons.badge),
              const SizedBox(height: 15),

              // Hàng Giới tính & Ngày sinh
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: const InputDecoration(
                        labelText: "Giới tính",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.people),
                      ),
                      items: ["Nam", "Nữ"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (val) => setState(() => _selectedGender = val!),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                            context: context,
                            initialDate: _dob,
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now()
                        );
                        if(picked != null) setState(() => _dob = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: "Ngày sinh",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text("${_dob.day}/${_dob.month}/${_dob.year}"),
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 15),

              _buildTextField(_phoneController, "Số điện thoại", Icons.phone, type: TextInputType.phone),
              const SizedBox(height: 15),
              _buildTextField(_emailController, "Email", Icons.email, type: TextInputType.emailAddress),
              const SizedBox(height: 15),

              _buildTextField(_passController, "Mật khẩu", Icons.lock, isPass: true),
              const SizedBox(height: 15),
              _buildTextField(_confirmPassController, "Nhập lại mật khẩu", Icons.lock_outline, isPass: true),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isLoading ? null : _handleRegister,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("ĐĂNG KÝ NGAY", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPass = false, TextInputType type = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      obscureText: isPass,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator: (val) => val!.isEmpty ? "Vui lòng nhập $label" : null,
    );
  }
}