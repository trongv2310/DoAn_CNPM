import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../providers/api_service.dart';
import '../../models/user.dart';

class ReturnAndFineScreen extends StatefulWidget {
  final User user;
  const ReturnAndFineScreen({super.key, required this.user});

  @override
  _ReturnAndFineScreenState createState() => _ReturnAndFineScreenState();
}

class _ReturnAndFineScreenState extends State<ReturnAndFineScreen> {
  final ApiService _api = ApiService();
  late Future<List<dynamic>> _listFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      // Gọi API lấy danh sách sách đang chờ trả (status='Chờ trả')
      _listFuture = _api.getBorrowedBooks();
    });
  }

  // Hàm xử lý trả sách (Thủ thư xác nhận)
  void _processReturn(int maPhieu, int maSach) async {
    // Hiển thị dialog loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    // Gọi API thực hiện trả sách
    var res = await _api.traSach(maPhieu, maSach);

    if (!mounted) return;
    Navigator.pop(context); // Tắt loading

    if (res['success']) {
      double phat = 0;
      // Kiểm tra dữ liệu trả về an toàn
      if (res['data'] != null && res['data']['tienPhat'] != null) {
        phat = (res['data']['tienPhat'] as num).toDouble();
      }

      String msg = phat > 0
          ? "Đã xác nhận trả. Phạt: ${NumberFormat("#,##0").format(phat)} đ"
          : "Đã xác nhận trả sách thành công!";

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: phat > 0 ? Colors.orange : Colors.green
      ));

      _refresh(); // Tải lại danh sách sau khi trả thành công
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? "Lỗi không xác định"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Duyệt trả sách", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _refresh,
          )
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _listFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Lỗi kết nối: ${snapshot.error}"));
          }

          final list = snapshot.data ?? [];

          // Tính toán số liệu thống kê từ danh sách trả về
          int soLuongYeuCau = list.length;
          int soLuongQuaHan = list.where((e) => e['soNgayQuaHan'] > 0).length;
          double tongTienPhat = list.fold(0.0, (sum, item) => sum + ((item['phiPhat'] as num).toDouble()));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. THANH THỐNG KÊ
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    _buildStatCard("Yêu cầu", "$soLuongYeuCau", Colors.blue, Colors.blue.shade50),
                    const SizedBox(width: 10),
                    _buildStatCard("Quá hạn", "$soLuongQuaHan", Colors.red, Colors.red.shade50),
                    const SizedBox(width: 10),
                    _buildStatCard(
                        "Tổng phạt",
                        tongTienPhat > 1000000
                            ? "${(tongTienPhat/1000000).toStringAsFixed(1)}M"
                            : "${(tongTienPhat/1000).toStringAsFixed(0)}K",
                        Colors.orange,
                        Colors.orange.shade50
                    ),
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text("Yêu cầu đang chờ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ),

              // 2. DANH SÁCH CHI TIẾT
              Expanded(
                child: list.isEmpty
                    ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_turned_in_outlined, size: 60, color: Colors.grey),
                      SizedBox(height: 10),
                      Text("Chưa có yêu cầu trả sách nào", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    return _buildReturnCard(list[index]);
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
  Widget _buildStatCard(String title, String value, Color color, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 5),
            Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // Widget thẻ sách (Card)
  Widget _buildReturnCard(dynamic item) {
    bool isLate = (item['soNgayQuaHan'] ?? 0) > 0;
    double phiPhat = (item['phiPhat'] ?? 0).toDouble();

    // Màu sắc chủ đạo của thẻ
    Color themeColor = isLate ? Colors.red : Colors.blue;
    IconData icon = isLate ? Icons.warning_amber_rounded : Icons.bookmark_added;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isLate, // Tự động mở nếu quá hạn để gây chú ý
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

          // HEADER
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: themeColor),
          ),
          title: Text(item['tenDocGia'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item['tenSach'], style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (isLate)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text("Quá hạn ${item['soNgayQuaHan']} ngày", style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  if (phiPhat > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text("Phạt: ${NumberFormat("#,##0").format(phiPhat)}đ", style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  if (!isLate && phiPhat == 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                      child: const Text("Đúng hạn", style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                ],
              )
            ],
          ),

          // BODY (CHI TIẾT)
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow("Mã phiếu:", "#${item['maPhieu']}"),
                        _buildDetailRow("Mã độc giả:", "${item['maDocGia']}"),
                        _buildDetailRow("Mã sách:", "${item['maSachHienThi']}"),
                        _buildDetailRow("Ngày mượn:", item['ngayMuon']),
                        _buildDetailRow("Hạn trả:", item['hanTra'], isBold: true, valueColor: isLate ? Colors.red : Colors.black),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Nút hành động
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C853), // Màu xanh lá xác nhận
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        elevation: 0,
                      ),
                      onPressed: () => _processReturn(item['maPhieu'], item['maSach']),
                      icon: const Icon(Icons.check_circle_outline, size: 20),
                      label: const Text("Xác nhận trả sách", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, Color valueColor = Colors.black}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Text(value, style: TextStyle(color: valueColor, fontWeight: isBold ? FontWeight.bold : FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }
}