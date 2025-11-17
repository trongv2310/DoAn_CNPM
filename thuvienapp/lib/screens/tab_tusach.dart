import 'package:flutter/material.dart';

class TabTuSach extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Tủ Sách Của Tôi"), backgroundColor: Colors.white, elevation: 0, foregroundColor: Colors.black),
      body: ListView.builder(
        padding: EdgeInsets.all(10),
        itemCount: 5, // Giả lập 5 cuốn đang mượn
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: Container(width: 50, height: 70, color: Colors.grey[300], child: Icon(Icons.book)),
              title: Text("Sách đang mượn số ${index + 1}", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Hạn trả: 20/11/2025"),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
            ),
          );
        },
      ),
    );
  }
}