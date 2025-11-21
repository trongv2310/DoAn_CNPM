import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../login_screen.dart';
import 'NhapSach.dart'; // Sẽ tạo ở bước sau

class StoreKeeperHomeScreen extends StatelessWidget {
  final User user;

  const StoreKeeperHomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Thủ Kho: ${user.hoVaTen}"),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
            },
          )
        ],
      ),
      body: GridView.count(
        padding: EdgeInsets.all(20),
        crossAxisCount: 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        children: [
          _buildMenuCard(context, Icons.add_box, "Nhập Hàng", () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => ImportGoodsScreen(user: user)));
          }),
          _buildMenuCard(context, Icons.output, "Thanh Lý", () {
            // TODO: Làm màn hình thanh lý tương tự nhập hàng
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Chức năng đang phát triển")));
          }),
          _buildMenuCard(context, Icons.inventory, "Kho Sách", () {
            // Có thể tái sử dụng màn hình danh sách sách nhưng thêm cột Số Lượng Tồn
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Chức năng đang phát triển")));
          }),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 4,
        color: Colors.orange[50],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.orange[800]),
            SizedBox(height: 10),
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange[900])),
          ],
        ),
      ),
    );
  }
}