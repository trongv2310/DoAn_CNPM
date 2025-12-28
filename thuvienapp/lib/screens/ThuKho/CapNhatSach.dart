import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/sach.dart';
import '../../providers/api_service.dart';

class CapNhatSachScreen extends StatefulWidget {
  final Sach sach;

  const CapNhatSachScreen({Key? key, required this.sach}) : super(key: key);

  @override
  _CapNhatSachScreenState createState() => _CapNhatSachScreenState();
}

class _CapNhatSachScreenState extends State<CapNhatSachScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _tenSachController;
  late TextEditingController _giaMuonController;
  late TextEditingController _moTaController;
  late TextEditingController _soLuongController;
  late TextEditingController _theLoaiController;

  int? _selectedTacGia;
  int? _selectedNXB;

  // [MỚI] Biến trạng thái
  String? _selectedTrangThai;
  final List<String> _listTrangThai = ["Có sẵn", "Đã hết"];

  List<Map<String, dynamic>> _listTacGia = [];
  List<Map<String, dynamic>> _listNXB = [];

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tenSachController = TextEditingController(text: widget.sach.tensach);
    _giaMuonController = TextEditingController(text: widget.sach.giamuon.toInt().toString());
    _moTaController = TextEditingController(text: widget.sach.moTa);
    _soLuongController = TextEditingController(text: widget.sach.soluongton.toString());
    _theLoaiController = TextEditingController(text: widget.sach.theLoai);

    _selectedTacGia = (widget.sach.matg > 0) ? widget.sach.matg : null;
    _selectedNXB = (widget.sach.manxb > 0) ? widget.sach.manxb : null;

    // [MỚI] Khởi tạo trạng thái
    _selectedTrangThai = widget.sach.trangThai;
    if (_selectedTrangThai == null || !_listTrangThai.contains(_selectedTrangThai)) {
      _selectedTrangThai = "Có sẵn";
    }

    _loadDropdownData();
  }

  Future<void> _loadDropdownData() async {
    final tacGias = await ApiService().getTacGiaList();
    final nxbs = await ApiService().getNXBList();
    if (mounted) {
      setState(() {
        _listTacGia = tacGias;
        _listNXB = nxbs;
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedTacGia == null || _selectedNXB == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn Tác giả và NXB!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    Map<String, String> data = {
      'Tensach': _tenSachController.text,
      'Giamuon': _giaMuonController.text,
      'Mota': _moTaController.text,
      'Soluongton': _soLuongController.text,
      'Theloai': _theLoaiController.text,
      'Matg': _selectedTacGia.toString(),
      'Manxb': _selectedNXB.toString(),
      // [MỚI] Gửi giá trị từ Dropdown
      'Trangthai': _selectedTrangThai ?? "Có sẵn",
    };

    bool success = await ApiService().updateSachFull(
        widget.sach.masach,
        data,
        _imageFile
    );

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thành công!'), backgroundColor: Colors.green));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thất bại!'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cập Nhật Sách Toàn Diện")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 120, height: 160,
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[200]
                    ),
                    child: _imageFile != null
                        ? Image.file(_imageFile!, fit: BoxFit.cover)
                        : (widget.sach.hinhanh != null && widget.sach.hinhanh!.isNotEmpty
                        ? Image.network(ApiService.getImageUrl(widget.sach.hinhanh), fit: BoxFit.cover, errorBuilder: (_,__,___)=>const Icon(Icons.add_a_photo))
                        : const Icon(Icons.add_a_photo, size: 50, color: Colors.grey)),
                  ),
                ),
              ),
              const Center(child: Padding(padding: EdgeInsets.all(8.0), child: Text("Chạm ảnh để thay đổi"))),

              const SizedBox(height: 20),
              TextFormField(
                controller: _tenSachController,
                decoration: const InputDecoration(labelText: "Tên sách", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Không được để trống" : null,
              ),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _giaMuonController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Giá mượn", border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? "Nhập giá" : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _soLuongController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Số lượng tồn", border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? "Nhập SL" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _theLoaiController,
                decoration: const InputDecoration(labelText: "Thể loại", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),

              DropdownButtonFormField<int>(
                value: _selectedTacGia,
                decoration: const InputDecoration(labelText: "Tác giả (*)", border: OutlineInputBorder()),
                items: _listTacGia.map((e) => DropdownMenuItem<int>(value: e['id'], child: Text(e['ten']))).toList(),
                onChanged: (val) => setState(() => _selectedTacGia = val),
                validator: (val) => val == null ? "Vui lòng chọn Tác giả" : null,
              ),
              const SizedBox(height: 15),

              DropdownButtonFormField<int>(
                value: _selectedNXB,
                decoration: const InputDecoration(labelText: "Nhà xuất bản (*)", border: OutlineInputBorder()),
                items: _listNXB.map((e) => DropdownMenuItem<int>(value: e['id'], child: Text(e['ten']))).toList(),
                onChanged: (val) => setState(() => _selectedNXB = val),
                validator: (val) => val == null ? "Vui lòng chọn NXB" : null,
              ),
              const SizedBox(height: 15),

              // [MỚI] DROPDOWN TRẠNG THÁI
              DropdownButtonFormField<String>(
                value: _selectedTrangThai,
                decoration: const InputDecoration(labelText: "Trạng thái", border: OutlineInputBorder()),
                items: _listTrangThai.map((e) => DropdownMenuItem<String>(value: e, child: Text(e))).toList(),
                onChanged: (val) => setState(() => _selectedTrangThai = val),
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _moTaController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: "Mô tả", border: OutlineInputBorder()),
              ),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                  onPressed: _isLoading ? null : _saveChanges,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("LƯU THAY ĐỔI", style: TextStyle(fontSize: 18)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}