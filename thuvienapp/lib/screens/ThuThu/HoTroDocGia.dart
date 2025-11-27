import 'package:flutter/material.dart';
import '../../providers/api_service.dart';
import '../../models/user.dart';

class SupportReaderScreen extends StatefulWidget {
  final User user;
  const SupportReaderScreen({super.key, required this.user});

  @override
  _SupportReaderScreenState createState() => _SupportReaderScreenState();
}

class _SupportReaderScreenState extends State<SupportReaderScreen> {
  final ApiService _api = ApiService();
  late Future<List<dynamic>> _listFuture;

  // Biến đếm thống kê
  int _countCho = 0;
  int _countXuLy = 0; // Tạm thời map 'Chờ trả lời' vào đây hoặc tách riêng nếu backend có status này
  int _countXong = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _listFuture = _api.getAllQuestions();
    });
  }

  // Hàm hiển thị dialog trả lời
  void _showReplyDialog(int maHoiDap) {
    final txtController = TextEditingController();
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Phản hồi độc giả"),
          content: TextField(
            controller: txtController,
            decoration: const InputDecoration(
              hintText: "Nhập nội dung câu trả lời...",
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
            ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                onPressed: () async {
                  if (txtController.text.trim().isEmpty) return;
                  bool ok = await _api.replyQuestion(maHoiDap, widget.user.entityId, txtController.text);
                  Navigator.pop(context);
                  if(ok) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã gửi phản hồi!"), backgroundColor: Colors.green));
                    _refresh(); // Reload list
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi gửi phản hồi"), backgroundColor: Colors.red));
                  }
                },
                child: const Text("Gửi")
            )
          ],
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Nền trắng sạch
      appBar: AppBar(
        title: const Text("Yêu Cầu Hỗ Trợ", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.black), onPressed: _refresh)
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _listFuture,
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final list = snapshot.data ?? [];

          // Tính toán thống kê
          _countCho = list.where((x) => x['trangthai'] == 'Chờ trả lời').length;
          _countXong = list.where((x) => x['trangthai'] == 'Đã trả lời').length;
          // Giả sử: Hiện tại DB chỉ có 2 trạng thái, ta gán tạm 'Xử lý' = 0 hoặc logic khác tùy bạn
          _countXuLy = 0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. THANH THỐNG KÊ
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
                child: Row(
                  children: [
                    _buildStatBox("Chờ", _countCho, Colors.orange, const Color(0xFFFFF3E0)),
                    const SizedBox(width: 10),
                    _buildStatBox("Xử lý", _countXuLy, Colors.blue, const Color(0xFFE3F2FD)),
                    const SizedBox(width: 10),
                    _buildStatBox("Xong", _countXong, Colors.green, const Color(0xFFE8F5E9)),
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text("Yêu Cầu Hỗ Trợ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),

              // 2. DANH SÁCH YÊU CẦU
              Expanded(
                child: list.isEmpty
                    ? const Center(child: Text("Chưa có câu hỏi nào."))
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: list.length,
                  itemBuilder: (ctx, i) {
                    return _buildSupportCard(list[i]);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Widget ô thống kê
  Widget _buildStatBox(String label, int count, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bg, // Màu nền nhạt
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text("$count", style: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // Widget thẻ yêu cầu (Card)
  Widget _buildSupportCard(dynamic item) {
    bool isDone = item['trangthai'] == "Đã trả lời";
    bool isPending = item['trangthai'] == "Chờ trả lời";

    // Cấu hình màu sắc & Icon dựa trên trạng thái
    Color themeColor = isDone ? Colors.green : (isPending ? Colors.orange : Colors.blue);
    IconData iconData = isDone ? Icons.check : (isPending ? Icons.access_time_filled : Icons.chat_bubble);
    Color bgIcon = isDone ? const Color(0xFFE8F5E9) : (isPending ? const Color(0xFFFFF3E0) : const Color(0xFFE3F2FD));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
          ],
          border: Border.all(color: Colors.grey.shade100)
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgIcon,
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: themeColor, size: 24),
          ),
          title: Text(
            item['tenSinhVien'] ?? "Sinh viên ẩn danh",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hiển thị 1 phần nội dung câu hỏi làm tiêu đề phụ
              Text(
                  item['cauhoi'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13)
              ),
              const SizedBox(height: 4),
              Text(item['thoiGian'] ?? "", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            ],
          ),

          // NỘI DUNG KHI MỞ RỘNG
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Khung nội dung câu hỏi đầy đủ
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Nội dung:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(item['cauhoi'], style: const TextStyle(fontSize: 14, height: 1.4)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Nếu đã trả lời -> Hiển thị câu trả lời
                  if (isDone)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.withOpacity(0.3))
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Phản hồi của bạn:", style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(item['traloi'] ?? "", style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black87)),
                        ],
                      ),
                    ),

                  // Nếu chưa trả lời -> Hiển thị nút Phản hồi
                  if (!isDone)
                    SizedBox(
                      height: 45,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black, // Màu nút đen giống design
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        ),
                        onPressed: () => _showReplyDialog(item['mahoidap']),
                        icon: const Icon(Icons.chat_bubble_outline, size: 18),
                        label: const Text("Phản hồi", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}