import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../providers/api_service.dart';
import '../../models/user.dart';

class ApproveBorrowScreen extends StatefulWidget {
  final User user;
  const ApproveBorrowScreen({super.key, required this.user});

  @override
  _ApproveBorrowScreenState createState() => _ApproveBorrowScreenState();
}

class _ApproveBorrowScreenState extends State<ApproveBorrowScreen> {
  final ApiService _api = ApiService();
  late Future<List<dynamic>> _listFuture; // Danh sách chờ duyệt

  // Biến lưu thống kê từ API
  Map<String, int> _stats = {
    'choDuyet': 0,
    'daDuyet': 0,
    'tuChoi': 0
  };

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  void _refreshAll() {
    setState(() {
      _listFuture = _api.getPendingBorrowRequests(); // Load danh sách chờ
    });
    _loadStats(); // Load số liệu thống kê
  }

  Future<void> _loadStats() async {
    final stats = await _api.getApprovalStats();
    if(mounted) setState(() => _stats = stats);
  }

  // Xử lý duyệt
  void _approve(int maPhieu) async {
    bool success = await _api.approveRequest(maPhieu, widget.user.entityId);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã duyệt thành công!"), backgroundColor: Colors.green));
      _refreshAll(); // Reload cả list và stats
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi duyệt (Có thể hết sách)"), backgroundColor: Colors.red));
    }
  }

  // Xử lý từ chối (Cần thêm API từ chối ở bước sau, tạm thời giả lập UI reload)
  void _reject(int maPhieu) {
    // TODO: Bạn nên thêm API RejectRequest(maPhieu) vào Backend và Service tương tự ApproveRequest
    // Ở đây ta giả lập reload để thấy sự thay đổi nếu có API
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận từ chối"),
        content: const Text("Bạn có chắc muốn từ chối yêu cầu này không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chức năng từ chối đang phát triển")));
            },
            child: const Text("Từ chối", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Chuyển sang màn hình xem lịch sử
  void _viewHistory(String type, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistoryListScreen(type: type, title: title),
      ),
    ).then((_) => _refreshAll()); // Refresh khi quay lại
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Duyệt mượn sách", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.black), onPressed: _refreshAll)
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _listFuture,
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final pendingList = snapshot.data ?? [];

          return Column(
            children: [
              // 1. PHẦN THỐNG KÊ (HEADER) - Có thể bấm được
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    _buildStatCard("Chờ duyệt", _stats['choDuyet'] ?? 0, Colors.orange, const Color(0xFFFFF3E0), null), // Không cần bấm
                    const SizedBox(width: 10),
                    _buildStatCard("Đã duyệt", _stats['daDuyet'] ?? 0, Colors.green, const Color(0xFFE8F5E9), () => _viewHistory('approved', 'Lịch Sử Đã Duyệt')),
                    const SizedBox(width: 10),
                    _buildStatCard("Từ chối", _stats['tuChoi'] ?? 0, Colors.red, const Color(0xFFFFEBEE), () => _viewHistory('rejected', 'Lịch Sử Từ Chối')),
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Align(alignment: Alignment.centerLeft, child: Text("Yêu cầu mới", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              ),

              // 2. DANH SÁCH YÊU CẦU CHỜ DUYỆT
              Expanded(
                child: pendingList.isEmpty
                    ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment_turned_in_outlined, size: 60, color: Colors.grey[300]),
                    const SizedBox(height: 10),
                    const Text("Không có yêu cầu mới", style: TextStyle(color: Colors.grey)),
                  ],
                ))
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: pendingList.length,
                  itemBuilder: (ctx, i) => _buildRequestCard(pendingList[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color textColor, Color bgColor, VoidCallback? onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: onTap != null ? Border.all(color: textColor.withOpacity(0.3)) : null, // Viền nhẹ nếu bấm được
          ),
          child: Column(
            children: [
              Text(title, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 5),
              Text("$count", style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(dynamic item) {
    final books = item['sachMuon'] as List;
    final String dateString = item['ngayMuon'] ?? "";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: const CircleAvatar(backgroundColor: Color(0xFFE3F2FD), child: Icon(Icons.person, color: Colors.blue)),
          title: Text(item['tenSinhVien'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          subtitle: Text("Mã phiếu: #${item['maPhieu']}", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(color: Colors.grey, thickness: 0.2),
                  ...books.map((b) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.book, color: Colors.purple, size: 18),
                        const SizedBox(width: 10),
                        Expanded(child: Text(b['tenSach'], style: const TextStyle(fontWeight: FontWeight.w500))),
                        Text("x${b['soLuong']}", style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  )),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text("Ngày mượn: $dateString", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853), foregroundColor: Colors.white),
                          onPressed: () => _approve(item['maPhieu']),
                          child: const Text("Duyệt"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                          onPressed: () => _reject(item['maPhieu']),
                          child: const Text("Từ chối"),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- MÀN HÌNH XEM LỊCH SỬ ---
class HistoryListScreen extends StatelessWidget {
  final String type; // 'approved' or 'rejected'
  final String title;

  const HistoryListScreen({super.key, required this.type, required this.title});

  @override
  Widget build(BuildContext context) {
    final ApiService api = ApiService();

    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 1),
      body: FutureBuilder<List<dynamic>>(
        future: api.getHistoryRequests(type),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Không có dữ liệu lịch sử"));

          final list = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              Color statusColor = type == 'approved' ? Colors.green : Colors.red;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: Icon(type == 'approved' ? Icons.check_circle : Icons.cancel, color: statusColor, size: 30),
                  title: Text(item['tenSinhVien'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${item['sachMuon'].length} loại sách • ${item['ngayMuon']}"),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Text(item['trangThai'], style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}