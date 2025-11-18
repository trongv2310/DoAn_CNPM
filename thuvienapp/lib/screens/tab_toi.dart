import 'package:flutter/material.dart';
import 'login_screen.dart'; // Để làm chức năng đăng xuất
import '../models/user.dart';
import 'storekeeper/import_goods_screen.dart';
import 'storekeeper/liquidation_screen.dart';
import 'storekeeper/inventory_check_screen.dart';

class TabToi extends StatelessWidget {
  final User user;
  const TabToi({super.key, required this.user});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 50),
            // Avatar
            CircleAvatar(radius: 50, backgroundColor: Colors.blue[100], child: Icon(Icons.person, size: 50, color: Colors.blue)),
            SizedBox(height: 10),
            Text(
                user.hoVaTen, // Hiển thị Họ và Tên thật
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
            ),
            Text(
                "TK: ${user.tenDangNhap}", // Hiển thị Tên đăng nhập thật
                style: const TextStyle(color: Colors.grey)
            ),
            SizedBox(height: 30),
            // === PHẦN RIÊNG CHO THỦ KHO (MaQuyen = 3) ===
            if (user.maQuyen == 3) ...[
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 10, bottom: 5),
                child: Align(alignment: Alignment.centerLeft, child: Text("QUẢN LÝ KHO", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange))),
              ),
              _buildStoreKeeperItem(context, Icons.add_box, "Nhập Hàng Mới", Colors.green, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ImportGoodsScreen(user: user)));
              }),
              _buildStoreKeeperItem(context, Icons.delete_sweep, "Thanh Lý Sách", Colors.red, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => LiquidationScreen(user: user)));
              }),
              _buildStoreKeeperItem(context, Icons.inventory, "Kiểm Kê Kho (Xem tồn)", Colors.blue, () {
                // Có thể tái sử dụng API lấy sách để hiển thị list có số lượng tồn
                Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryCheckScreen()));
              }),
              Divider(thickness: 5, color: Colors.grey[100]),
            ],

            // Các mục menu
            _buildProfileItem(Icons.history, "Lịch sử mượn"),
            _buildProfileItem(Icons.favorite, "Sách yêu thích"),
            _buildProfileItem(Icons.settings, "Cài đặt"),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text("Đăng xuất", style: TextStyle(color: Colors.red)),
              onTap: () {
                // Quay về màn hình đăng nhập
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
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

  Widget _buildStoreKeeperItem(BuildContext context, IconData icon, String title, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildProfileItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: () {},
    );
  }
}