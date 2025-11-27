import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../login_screen.dart';

// Import các màn hình chức năng của Thủ thư
// (Đảm bảo bạn đã tạo các file này theo hướng dẫn trước đó)
import 'DuyetMuon.dart';
import 'TraSachPhat.dart';
import 'HoTroDocGia.dart';
import '../Admin/BaoCaoTongHop.dart'; // Tái sử dụng màn hình báo cáo của Admin

class LibrarianHomeScreen extends StatelessWidget {
  final User user;

  const LibrarianHomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Trang Chủ Thủ Thư", style: TextStyle(fontSize: 18)),
            Text("Xin chào, ${user.hoVaTen}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400)),
          ],
        ),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Đăng xuất",
            onPressed: () {
              // Xử lý đăng xuất
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
                    (route) => false,
              );
            },
          )
        ],
      ),
      body: Container(
        color: Colors.grey[100], // Màu nền nhẹ
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2, // 2 cột
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            // 1. Chức năng Duyệt Mượn
            _buildMenuCard(
              context,
              icon: Icons.fact_check_outlined,
              title: "Duyệt Mượn Sách",
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ApproveBorrowScreen(user: user)),
                );
              },
            ),

            // 2. Chức năng Trả Sách & Phạt
            _buildMenuCard(
              context,
              icon: Icons.assignment_return_outlined,
              title: "Trả Sách & Phạt",
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ReturnAndFineScreen(user: user)),
                );
              },
            ),

            // 3. Chức năng Hỗ Trợ Độc Giả (Chat)
            _buildMenuCard(
              context,
              icon: Icons.support_agent,
              title: "Hỗ Trợ Độc Giả",
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SupportReaderScreen(user: user)),
                );
              },
            ),

            // 4. Chức năng Xem Báo Cáo (Tái sử dụng)
            _buildMenuCard(
              context,
              icon: Icons.analytics_outlined,
              title: "Thống Kê Báo Cáo",
              color: Colors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AdminReportsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Widget xây dựng từng ô menu
  Widget _buildMenuCard(BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      shadowColor: color.withOpacity(0.4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                color.withOpacity(0.05), // Hiệu ứng màu nhẹ góc dưới
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}