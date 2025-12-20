import 'package:flutter/material.dart';
import '../../providers/api_service.dart';

class QuanLyDanhGiaScreen extends StatefulWidget {
  const QuanLyDanhGiaScreen({Key? key}) : super(key: key);

  @override
  _QuanLyDanhGiaScreenState createState() => _QuanLyDanhGiaScreenState();
}

class _QuanLyDanhGiaScreenState extends State<QuanLyDanhGiaScreen> {
  List<dynamic> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final data = await ApiService().getAllReviews();
    if (mounted) {
      setState(() {
        _reviews = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteItem(int id) async {
    // Hiển thị hộp thoại xác nhận
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: const Text("Bạn có chắc chắn muốn xóa đánh giá này không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Xóa", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      bool success = await ApiService().deleteReview(id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Đã xóa đánh giá thành công!"), backgroundColor: Colors.green));
        _fetchData(); // Tải lại danh sách
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Lỗi khi xóa đánh giá!"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản Lý Đánh Giá"),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reviews.isEmpty
          ? const Center(child: Text("Chưa có đánh giá nào."))
          : ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: _reviews.length,
        itemBuilder: (context, index) {
          final item = _reviews[index];
          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hàng 1: Tên sách + Nút xóa
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item['tenSach'] ?? "Tên sách lỗi",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteItem(item['maDanhGia']),
                      )
                    ],
                  ),

                  // Hàng 2: Người đánh giá + Sao + Ngày
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(item['tenSinhVien'] ?? "Ẩn danh", style: const TextStyle(fontWeight: FontWeight.w500)),
                      const Spacer(),
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      Text(" ${item['diem']}/5"),
                      const SizedBox(width: 10),
                      Text(item['ngayDanhGia'] ?? "", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  const Divider(),

                  // Hàng 3: Nội dung nhận xét
                  Text(
                    item['nhanXet'] ?? "Không có nội dung",
                    style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black87),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}