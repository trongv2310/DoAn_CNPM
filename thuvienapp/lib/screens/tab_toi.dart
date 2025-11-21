import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart';
import '../models/user.dart';
import '../providers/user_provider.dart';
import '../providers/borrow_cart_provider.dart';

// Import các màn hình chức năng của Thủ Kho
import 'ThuKho/NhapSach.dart';
import 'ThuKho/ThanhLy.dart';
import 'ThuKho/CheckTonKho.dart';
import 'ThuKho/LichSuNhapSach.dart';
import 'ThuKho/BaoCao.dart';
import 'DoiMatKhau.dart';

class TabToi extends StatelessWidget {
  final User user;
  const TabToi({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // Dùng watch để cập nhật khi UserProvider thay đổi
    // Nếu provider null (lỗi), fallback về biến user truyền vào
    final userProvider = context.watch<UserProvider>().user ?? user;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 50),
            CircleAvatar(radius: 50, backgroundColor: Colors.blue[100], child: const Icon(Icons.person, size: 50, color: Colors.blue)),
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

            // === MENU THỦ KHO (Hiện nếu MaQuyen = 3) ===
            if (userProvider.maQuyen == 3) ...[
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 10, bottom: 5),
                child: Align(alignment: Alignment.centerLeft, child: Text("QUẢN LÝ KHO", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange))),
              ),
              _buildThuKhoItem(context, Icons.add_box, "Nhập Hàng Mới", Colors.green, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ImportGoodsScreen(user: userProvider)));
              }),
              _buildThuKhoItem(context, Icons.delete_sweep, "Thanh Lý Sách", Colors.red, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => LiquidationScreen(user: userProvider)));
              }),
              _buildThuKhoItem(context, Icons.inventory, "Kiểm Kê Kho", Colors.blue, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryCheckScreen()));
              }),
              _buildThuKhoItem(context, Icons.history, "Lịch Sử Nhập", Colors.purple, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ImportHistoryScreen(user: userProvider)));
              }),
              _buildThuKhoItem(context, Icons.bar_chart, "Báo Cáo Thu/Chi", Colors.teal, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen()));
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
                // Xóa dữ liệu trong Provider và về màn hình Login
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

  String _getRoleName(int id) {
    if(id == 1) return "Admin";
    if(id == 2) return "Thủ thư";
    if(id == 3) return "Thủ kho";
    return "Độc giả";
  }

  Widget _buildThuKhoItem(BuildContext context, IconData icon, String title, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildProfileItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: () {},
    );
  }
}