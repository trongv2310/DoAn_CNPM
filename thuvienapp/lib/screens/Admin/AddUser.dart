import 'package:flutter/material.dart';
import '../../providers/api_service.dart';

class AddUserScreen extends StatefulWidget {
  @override
  _AddUserScreenState createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  // Controllers
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  // Dữ liệu mặc định
  int _selectedRole = 4; // Mặc định là Độc giả
  String _selectedGender = "Nam";
  DateTime _dob = DateTime(2000, 1, 1);

  final Map<int, String> _roles = {
    1: "Admin",
    2: "Thủ Thư",
    3: "Thủ Kho",
    4: "Độc Giả"
  };

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final userData = {
      "TenDangNhap": _userController.text,
      "MatKhau": _passController.text,
      "MaQuyen": _selectedRole,
      "HoVaTen": _nameController.text,
      "GioiTinh": _selectedGender,
      "NgaySinh": _dob.toIso8601String(),
      "Sdt": _phoneController.text,
      "Email": _emailController.text
    };

    bool success = await _apiService.addUser(userData);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Thêm tài khoản thành công!")));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Thêm thất bại (Có thể trùng tên đăng nhập/Email)")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Thêm Tài Khoản Mới")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text("Thông Tin Đăng Nhập", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
              TextFormField(
                controller: _userController,
                decoration: InputDecoration(labelText: "Tên đăng nhập"),
                validator: (v) => v!.isEmpty ? "Không được để trống" : null,
              ),
              TextFormField(
                controller: _passController,
                decoration: InputDecoration(labelText: "Mật khẩu"),
                obscureText: true,
                validator: (v) => v!.isEmpty ? "Không được để trống" : null,
              ),
              DropdownButtonFormField<int>(
                value: _selectedRole,
                decoration: InputDecoration(labelText: "Phân quyền"),
                items: _roles.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                onChanged: (val) => setState(() => _selectedRole = val!),
              ),

              SizedBox(height: 20),
              Text("Thông Tin Cá Nhân", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: "Họ và tên"),
                validator: (v) => v!.isEmpty ? "Không được để trống" : null,
              ),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: InputDecoration(labelText: "Giới tính"),
                      items: ["Nam", "Nữ"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (val) => setState(() => _selectedGender = val!),
                    ),
                  ),
                  SizedBox(width: 10),
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
                        decoration: InputDecoration(labelText: "Ngày sinh"),
                        child: Text("${_dob.day}/${_dob.month}/${_dob.year}"),
                      ),
                    ),
                  )
                ],
              ),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: "Số điện thoại"),
                keyboardType: TextInputType.phone,
              ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: "Email"),
                keyboardType: TextInputType.emailAddress,
              ),

              SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: Text("XÁC NHẬN THÊM"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}