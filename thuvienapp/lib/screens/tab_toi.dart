import 'package:flutter/material.dart';
import 'login_screen.dart'; // Để làm chức năng đăng xuất

class TabToi extends StatelessWidget {
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
            Text("Độc Giả: Nguyễn Văn A", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text("TK: sv01", style: TextStyle(color: Colors.grey)),
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
                // Quay về màn hình đăng nhập
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
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