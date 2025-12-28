import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart';
import '../models/user.dart';
import '../providers/user_provider.dart';
import '../providers/borrow_cart_provider.dart';

// Import các màn hình chức năng
import 'ThuKho/NhapSach.dart';
import 'ThuKho/ThanhLy.dart';
import 'ThuKho/CheckTonKho.dart';
import 'ThuKho/LichSuNhapSach.dart';
import 'ThuKho/BaoCao.dart';
import 'DoiMatKhau.dart';
import 'Admin/QuanLyTaiKhoan.dart';
import 'Admin/NhatKyHeThong.dart';
import 'Admin/BaoCaoTongHop.dart';
import 'ThuThu/ThuThuHome.dart';

class TabToi extends StatelessWidget {
  final User? user;
  const TabToi({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // Dùng watch để cập nhật khi UserProvider thay đổi
    final userProvider = context.watch<UserProvider>().user;

    // --- KIỂM TRA NẾU LÀ KHÁCH ---
    if (userProvider == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_circle_outlined, size: 80, color: Colors.grey),
              const SizedBox(height: 20),
              const Text("Bạn đang ở chế độ khách", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text("Vui lòng đăng nhập để xem thông tin cá nhân\nvà sử dụng các chức năng nâng cao.", textAlign: TextAlign.center),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => LoginScreen()),
                          (route) => false);
                },
                child: const Text("Đăng nhập ngay"),
              )
            ],
          ),
        ),
      );
    }
    // -----------------------------

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 50),
            CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blue[100],
                child: const Icon(Icons.person, size: 50, color: Colors.blue)
            ),
            const SizedBox(height: 10),

            Text(
                userProvider.hoVaTen,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
            ),
            Text(
                "TK: ${userProvider.tenDangNhap} | ID: ${userProvider.entityId} ",
                style: const TextStyle(color: Colors.grey)
            ),
            const SizedBox(height: 30),

            // === MENU ADMIN (Hiện nếu MaQuyen = 1) ===
            if (userProvider.maQuyen == 1) ...[
              _buildSectionHeader("QUẢN TRỊ HỆ THỐNG", Colors.redAccent),
              _buildMenuItem(context, Icons.people_alt, "Quản lý tài khoản", () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => UserManagementScreen()));
              }),
              _buildMenuItem(context, Icons.history_edu, "Nhật ký hệ thống", () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const NhatKyHeThong()));
              }),
              _buildMenuItem(context, Icons.analytics, "Xem báo cáo tổng hợp", () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => AdminReportsScreen()));
              }),
              Divider(thickness: 5, color: Colors.grey[100]),
            ],

            // === MENU THỦ THƯ (Hiện nếu MaQuyen = 2) ===
            if (userProvider.maQuyen == 2) ...[
              _buildSectionHeader("QUẢN LÝ THƯ VIỆN", Colors.blue[800]!),
              _buildMenuItem(context, Icons.dashboard, "Trang chủ thủ thư", () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => LibrarianHomeScreen(user: userProvider)));
              }),
              Divider(thickness: 5, color: Colors.grey[100]),
            ],

            // === MENU THỦ KHO (Hiện nếu MaQuyen = 3) ===
            if (userProvider.maQuyen == 3) ...[
              _buildSectionHeader("QUẢN LÝ KHO", Colors.orange),
              _buildMenuItem(context, Icons.add_box, "Nhập hàng mới", () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ImportGoodsScreen(user: userProvider)));
              }),
              _buildMenuItem(context, Icons.delete_sweep, "Thanh lý sách", () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => LiquidationScreen(user: userProvider)));
              }),
              _buildMenuItem(context, Icons.library_books, "Quản lý sách & Tồn kho", () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryCheckScreen())); // Class đã đổi logic ở trên
              }),
              _buildMenuItem(context, Icons.history, "Lịch sử nhập", () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ImportHistoryScreen(user: userProvider)));
              }),
              _buildMenuItem(context, Icons.bar_chart, "Báo cáo thu/chi", () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const BaoCaoThuChiScreen()));
              }),
              Divider(thickness: 5, color: Colors.grey[100]),
            ],

            // === MENU CHUNG ===
            _buildProfileItem(Icons.history, "Lịch sử mượn"),
            _buildProfileItem(Icons.favorite, "Sách yêu thích"),

            ListTile(
              leading: const Icon(Icons.lock, color: Colors.blue),
              title: const Text("Đổi mật khẩu"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ChangePasswordScreen(user: userProvider)));
              },
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Đăng xuất", style: TextStyle(color: Colors.red)),
              onTap: () {
                context.read<UserProvider>().logout();
                context.read<BorrowCartProvider>().clear();
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => LoginScreen()),
                        (route) => false
                );
              },
            )
          ],
        ),
      ),
    );
  }

  // Tiêu đề cho các nhóm chức năng
  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 10, bottom: 5),
      child: Align(
          alignment: Alignment.centerLeft,
          child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color))
      ),
    );
  }

  // Menu Item đã chỉnh sửa: Đồng bộ style với các chức năng cơ bản (Icon xanh, không nền)
  Widget _buildMenuItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue), // Màu xanh đồng nhất
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }

  // Menu Item cho phần chung (không có sự kiện onTap cụ thể trong code gốc)
  Widget _buildProfileItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: () {},
    );
  }
}