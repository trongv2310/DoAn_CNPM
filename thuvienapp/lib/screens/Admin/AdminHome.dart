import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../login_screen.dart';
import 'QuanLyTaiKhoan.dart'; // Chúng ta sẽ tạo file này ở Bước 3
import 'NhatKyHeThong.dart';

class AdminHomeScreen extends StatelessWidget {
  final User user;

  const AdminHomeScreen({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Dashboard"),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Xin chào, ${user.hoVaTen}", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            Text("Vai trò: Quản trị viên hệ thống", style: TextStyle(color: Colors.grey)),
            SizedBox(height: 30),

            // Menu Grid
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                children: [
                  _buildMenuCard(
                      context,
                      Icons.people_alt,
                      "Quản Lý Tài Khoản",
                      Colors.blue,
                          () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserManagementScreen()))
                  ),
                  _buildMenuCard(
                      context,
                      Icons.bar_chart,
                      "Thống Kê Hệ Thống",
                      Colors.purple,
                          () {
                        // Có thể tái sử dụng màn hình Báo Cáo của Thủ Kho hoặc làm mới
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Chức năng đang phát triển")));
                      }
                  ),
                  _buildMenuCard(
                      context,
                      Icons.history_edu, // Icon nhật ký
                      "Nhật Ký Hệ Thống",
                      Colors.blueGrey,
                          () => Navigator.push(context, MaterialPageRoute(builder: (_) => NhatKyHeThong()))
                  ),

                  // THÊM MỚI: Nút Xem báo cáo
                  _buildMenuCard(
                      context,
                      Icons.analytics, // Icon báo cáo
                      "Xem Báo Cáo",
                      Colors.deepPurple,
                          () => Navigator.push(context, MaterialPageRoute(builder: (_) => NhatKyHeThong()))
                  ),
                  // Thêm các chức năng khác nếu cần
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, IconData icon, String title, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: color),
            SizedBox(height: 10),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
          ],
        ),
      ),
    );
  }
}