import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../providers/api_service.dart';
import '../login_screen.dart';

// Import các màn hình chức năng
import 'DuyetMuon.dart';
import 'TraSachPhat.dart';
import 'HoTroDocGia.dart';
import '../Admin/BaoCaoTongHop.dart';
import 'DuyetGiaHan.dart';

class LibrarianHomeScreen extends StatefulWidget {
  final User user;

  const LibrarianHomeScreen({super.key, required this.user});

  @override
  State<LibrarianHomeScreen> createState() => _LibrarianHomeScreenState();
}

class _LibrarianHomeScreenState extends State<LibrarianHomeScreen> {
  // Khởi tạo đầy đủ các key với giá trị 0
  Map<String, int> _stats = {
    'choDuyet': 0,
    'yeuCauTra': 0,
    'cauHoiMoi': 0,
    'yeuCauGiaHan': 0,
  };
  bool _isLoading = true;
  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _api.getLibrarianStats();
    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Trang chủ thủ thư", style: TextStyle(fontSize: 18)),
            Text("Xin chào, ${widget.user.hoVaTen}",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400)),
          ],
        ),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            // Thẻ 1: Duyệt mượn
            _buildListCard(
              context,
              title: "Duyệt mượn sách",
              subtitle: _isLoading ? "Đang tải..." : "${_stats['choDuyet'] ?? 0} yêu cầu chờ",
              icon: Icons.fact_check_outlined,
              color: const Color(0xFF00C853),
              isBadgeVisible: (_stats['choDuyet'] ?? 0) > 0,
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => ApproveBorrowScreen(user: widget.user)));
                _loadStats();
              },
            ),

            const SizedBox(height: 16),

            // Thẻ 2: Trả Sách & Phạt
            _buildListCard(
              context,
              title: "Trả sách & phạt",
              subtitle: _isLoading ? "Đang tải..." : "${_stats['yeuCauTra'] ?? 0} yêu cầu trả",
              icon: Icons.assignment_return_outlined,
              color: const Color(0xFFFF6D00),
              isBadgeVisible: (_stats['yeuCauTra'] ?? 0) > 0,
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => ReturnAndFineScreen(user: widget.user)));
                _loadStats();
              },
            ),

            const SizedBox(height: 16),

            // [CẬP NHẬT] Thẻ 3: Duyệt Gia Hạn
            _buildListCard(
              context,
              title: "Duyệt gia hạn",
              // SỬA Ở ĐÂY: Thêm ?? 0 để tránh hiển thị null
              subtitle: _isLoading ? "Đang tải..." : "${_stats['yeuCauGiaHan'] ?? 0} yêu cầu gia hạn",
              icon: Icons.update,
              color: Colors.purple,
              isBadgeVisible: (_stats['yeuCauGiaHan'] ?? 0) > 0,
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => ApproveExtensionScreen(user: widget.user)));
                _loadStats();
              },
            ),

            const SizedBox(height: 16),

            // Thẻ 4: Hỗ trợ độc giả
            _buildListCard(
              context,
              title: "Hỗ trợ độc giả",
              subtitle: _isLoading ? "Đang tải..." : "${_stats['cauHoiMoi'] ?? 0} câu hỏi mới",
              icon: Icons.headset_mic_outlined,
              color: const Color(0xFF2962FF),
              isBadgeVisible: (_stats['cauHoiMoi'] ?? 0) > 0,
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => SupportReaderScreen(user: widget.user)));
                _loadStats();
              },
            ),

            const SizedBox(height: 16),

            // Thẻ 5: Thống kê
            _buildListCard(
              context,
              title: "Thống kê",
              subtitle: "Xem báo cáo tổng hợp",
              icon: Icons.bar_chart_rounded,
              color: const Color(0xFFAA00FF),
              isBadgeVisible: false,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => AdminReportsScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isBadgeVisible,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                if (isBadgeVisible)
                  Positioned(
                    top: -5,
                    right: -5,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: isBadgeVisible ? Colors.redAccent : Colors.grey[600], fontWeight: isBadgeVisible ? FontWeight.w600 : FontWeight.normal)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 24),
          ],
        ),
      ),
    );
  }
}