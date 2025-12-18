import 'package:flutter/material.dart';
import '../../models/sach.dart';
import '../../providers/api_service.dart';

class ThemSachMoiScreen extends StatefulWidget {
  const ThemSachMoiScreen({super.key});

  @override
  State<ThemSachMoiScreen> createState() => _ThemSachMoiScreenState();
}

class _ThemSachMoiScreenState extends State<ThemSachMoiScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  // Controllers
  final txtTenSach = TextEditingController();
  final txtTheLoai = TextEditingController();
  final txtGiaMuon = TextEditingController();
  final txtMoTa = TextEditingController();
  final txtHinhAnh = TextEditingController();
  final txtSoLuongBanDau = TextEditingController();

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      // Tạo đối tượng sách tạm
      Sach newBook = Sach(
        masach: 0, // ID tự tăng
        tensach: txtTenSach.text,
        theLoai: txtTheLoai.text,
        giamuon: double.tryParse(txtGiaMuon.text) ?? 0,
        soluongton: int.tryParse(txtSoLuongBanDau.text) ?? 0,
        moTa: txtMoTa.text,
        hinhanh: txtHinhAnh.text,
      );

      bool success = await _apiService.addSach(newBook);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Thêm sách thành công!")));
        Navigator.pop(context, true); // Trả về true để màn hình trước reload
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi khi thêm sách")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Thêm Sách Mới Vào DB"), backgroundColor: Colors.orange),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(controller: txtTenSach, decoration: const InputDecoration(labelText: "Tên sách"), validator: (v) => v!.isEmpty ? "Cần nhập tên" : null),
              TextFormField(controller: txtTheLoai, decoration: const InputDecoration(labelText: "Thể loại")),
              TextFormField(controller: txtGiaMuon, decoration: const InputDecoration(labelText: "Giá mượn"), keyboardType: TextInputType.number),
              TextFormField(controller: txtSoLuongBanDau, decoration: const InputDecoration(labelText: "Số lượng tồn ban đầu"), keyboardType: TextInputType.number),
              TextFormField(controller: txtHinhAnh, decoration: const InputDecoration(labelText: "Link hình ảnh (URL)")),
              TextFormField(controller: txtMoTa, decoration: const InputDecoration(labelText: "Mô tả"), maxLines: 3),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, minimumSize: const Size(double.infinity, 50)),
                child: const Text("LƯU VÀO CƠ SỞ DỮ LIỆU", style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        ),
      ),
    );
  }
}