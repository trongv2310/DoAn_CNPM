import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  final txtSoLuongBanDau = TextEditingController();

  // Biến lưu ảnh đã chọn
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  // Danh sách tác giả và NXB (lấy từ API hoặc hardcode demo)
  List<Map<String, dynamic>> _tacGiaList = [];
  List<Map<String, dynamic>> _nxbList = [];
  int?  _selectedTacGia;
  int? _selectedNXB;

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
  }

  Future<void> _loadDropdownData() async {
    // TODO:  Gọi API lấy danh sách tác giả và NXB
    // Tạm thời dùng dữ liệu mẫu
    setState(() {
      _tacGiaList = [
        {"id": 1, "ten": "J. K. Rowling"},
        {"id":  2, "ten": "Nguyễn Nhật Ánh"},
        {"id": 3, "ten": "Paulo Coelho"},
        {"id": 4, "ten":  "Khác"},
      ];
      _nxbList = [
        {"id": 1, "ten": "NXB Kim Đồng"},
        {"id": 2, "ten": "NXB Văn Học"},
        {"id": 3, "ten": "NXB Thế Giới"},
        {"id": 4, "ten": "Khác"},
      ];
      _selectedTacGia = 1;
      _selectedNXB = 1;
    });
  }

  // Chọn ảnh từ thư viện
  Future<void> _pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight:  800,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  // Chụp ảnh từ camera
  Future<void> _pickImageFromCamera() async {
    final XFile?  image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality:  85,
    );
    if (image != null) {
      setState(() {
        _selectedImage = File(image. path);
      });
    }
  }

  // Hiển thị bottom sheet chọn nguồn ảnh
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context:  context,
      builder: (context) => SafeArea(
        child:  Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.orange),
              title:  const Text('Chọn từ thư viện'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.orange),
              title:  const Text('Chụp ảnh mới'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
            if (_selectedImage != null)
              ListTile(
                leading:  const Icon(Icons. delete, color: Colors. red),
                title: const Text('Xóa ảnh đã chọn'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImage = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (! _formKey.currentState!. validate()) return;

    if (_selectedTacGia == null || _selectedNXB == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn Tác giả và Nhà xuất bản")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String uploadedImageName = ""; // Mặc định rỗng nếu không có ảnh

      // Nếu có ảnh, thử upload
      if (_selectedImage != null) {
        var result = await _apiService.uploadImage(_selectedImage! );
        if (result != null) {
          uploadedImageName = result;
        } else {
          // Nếu upload thất bại, hỏi user có muốn tiếp tục không
          bool?  continueWithoutImage = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title:  const Text("Upload ảnh thất bại"),
              content: const Text("Không thể upload ảnh.  Bạn có muốn tiếp tục lưu sách mà không có ảnh?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Hủy"),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Tiếp tục"),
                ),
              ],
            ),
          );

          if (continueWithoutImage != true) {
            setState(() => _isLoading = false);
            return;
          }
        }
      }

      // Lưu sách vào database
      bool success = await _apiService.addSachWithDetails(
        tenSach: txtTenSach.text,
        theLoai: txtTheLoai.text,
        giaMuon: double.tryParse(txtGiaMuon.text) ?? 0,
        soLuongTon: int.tryParse(txtSoLuongBanDau.text) ?? 0,
        moTa: txtMoTa.text,
        hinhAnh: uploadedImageName,
        maTacGia: _selectedTacGia!,
        maNXB: _selectedNXB!,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Thêm sách thành công! "),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lỗi khi thêm sách vào database"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Lỗi:  $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi:  $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thêm Sách Mới Vào DB"),
        backgroundColor:  Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key:  _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== PHẦN CHỌN ẢNH =====
              const Text(
                "Hình ảnh sách",
                style: TextStyle(fontWeight: FontWeight. bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration:  BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius. circular(12),
                    border: Border.all(color: Colors.orange, width: 2),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                    borderRadius:  BorderRadius.circular(10),
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                    ),
                  )
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add_photo_alternate,
                          size: 60, color: Colors.orange),
                      SizedBox(height:  8),
                      Text(
                        "Nhấn để chọn ảnh",
                        style:  TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ===== CÁC TRƯỜNG NHẬP LIỆU =====
              TextFormField(
                controller: txtTenSach,
                decoration: const InputDecoration(
                  labelText: "Tên sách *",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.book),
                ),
                validator: (v) => v!.isEmpty ?  "Vui lòng nhập tên sách" : null,
              ),
              const SizedBox(height:  12),

              // Dropdown Tác giả
              DropdownButtonFormField<int>(
                value:  _selectedTacGia,
                decoration: const InputDecoration(
                  labelText: "Tác giả *",
                  border:  OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                items: _tacGiaList.map((tg) {
                  return DropdownMenuItem<int>(
                    value: tg['id'],
                    child: Text(tg['ten']),
                  );
                }).toList(),
                onChanged:  (value) {
                  setState(() => _selectedTacGia = value);
                },
              ),
              const SizedBox(height:  12),

              // Dropdown NXB
              DropdownButtonFormField<int>(
                value: _selectedNXB,
                decoration: const InputDecoration(
                  labelText: "Nhà xuất bản *",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons. business),
                ),
                items: _nxbList.map((nxb) {
                  return DropdownMenuItem<int>(
                    value: nxb['id'],
                    child: Text(nxb['ten']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedNXB = value);
                },
              ),
              const SizedBox(height:  12),

              TextFormField(
                controller: txtTheLoai,
                decoration: const InputDecoration(
                  labelText: "Thể loại",
                  border:  OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
              ),
              const SizedBox(height:  12),

              TextFormField(
                controller: txtGiaMuon,
                decoration: const InputDecoration(
                  labelText:  "Giá mượn (VNĐ)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height:  12),

              TextFormField(
                controller: txtSoLuongBanDau,
                decoration: const InputDecoration(
                  labelText: "Số lượng tồn ban đầu",
                  border:  OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory),
                ),
                keyboardType:  TextInputType.number,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: txtMoTa,
                decoration: const InputDecoration(
                  labelText: "Mô tả",
                  border:  OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // ===== NÚT LƯU =====
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton. icon(
                  onPressed: _isLoading ? null :  _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius:  BorderRadius.circular(10),
                    ),
                  ),
                  icon:  _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color:  Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(Icons.save, color: Colors.white),
                  label:  Text(
                    _isLoading ? "ĐANG LƯU..." : "LƯU VÀO CƠ SỞ DỮ LIỆU",
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    txtTenSach. dispose();
    txtTheLoai.dispose();
    txtGiaMuon. dispose();
    txtMoTa. dispose();
    txtSoLuongBanDau. dispose();
    super.dispose();
  }
}