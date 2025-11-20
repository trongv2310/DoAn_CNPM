// FILE: screens/tab_toi.dart

import 'package:flutter/material.dart';
import 'login_screen.dart'; // Để làm chức năng đăng xuất
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/borrow_cart_provider.dart'; // 1. THÊM import này
import '../models/user.dart';

class TabToi extends StatelessWidget {
  final User user;
  const TabToi({super.key, required this.user});
  @override
  Widget build(BuildContext context) {
    // 2. Lấy thông tin user thật từ provider
    // Dùng .watch() để widget tự cập nhật khi user thay đổi
    final user = context.watch<UserProvider>().user;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 50),
            // Avatar
            CircleAvatar(radius: 50, backgroundColor: Colors.blue[100], child: Icon(Icons.person, size: 50, color: Colors.blue)),
            SizedBox(height: 10),

            // 3. SỬA: Hiển thị tên và TK thật (có kiểm tra null)
            Text(
                user?.hoVaTen ?? "Độc Giả",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
            ),
            Text(
                "TK: ${user?.tenDangNhap ?? '...'}",
                style: TextStyle(color: Colors.grey)
            ),
            SizedBox(height: 30),

            // Các mục menu
            _buildProfileItem(Icons.history, "Lịch sử mượn"),
            _buildProfileItem(Icons.favorite, "Sách yêu thích"),
            _buildProfileItem(Icons.settings, "Cài đặt"),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text("Đăng xuất", style: TextStyle(color: Colors.red)),
              onTap: () {
                // 4. SỬA: Xử lý logout provider
                // Dùng .read() bên trong 1 hàm
                context.read<UserProvider>().logout();
                context.read<BorrowCartProvider>().clear(); // Dọn dẹp giỏ hàng

                // Quay về màn hình đăng nhập và xóa hết lịch sử (ngăn bấm back)
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => LoginScreen()),
                        (route) => false // Xóa tất cả các màn hình cũ
                );
              },
            )
          ],
        ),
      ),
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