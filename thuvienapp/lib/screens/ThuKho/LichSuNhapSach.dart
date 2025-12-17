import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../providers/api_service.dart';

class ImportHistoryScreen extends StatefulWidget {
  final User user;
  const ImportHistoryScreen({Key? key, required this.user}) : super(key: key);

  @override
  _ImportHistoryScreenState createState() => _ImportHistoryScreenState();
}

class _ImportHistoryScreenState extends State<ImportHistoryScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _apiService.fetchLichSuNhap(widget.user.entityId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Lịch sử nhập hàng"), backgroundColor: Colors.orange),
      body: FutureBuilder<List<dynamic>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text("Chưa có phiếu nhập nào"));

          final list = snapshot.data!;
          return ListView.builder(
            padding: EdgeInsets.all(10),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              final chiTiet = item['chiTiet'] as List;

              return Card(
                margin: EdgeInsets.only(bottom: 15),
                elevation: 3,
                child: ExpansionTile(
                  // Thông tin tóm tắt bên ngoài
                  leading: Icon(Icons.assignment, color: Colors.orange),
                  title: Text("Phiếu #${item['mapn']} - ${item['ngayNhap']}", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Tổng tiền: ${item['tongtien']} đ", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),

                  // Chi tiết sách bên trong khi bấm xổ xuống
                  children: chiTiet.map<Widget>((sach) {
                    return ListTile(
                      contentPadding: EdgeInsets.only(left: 30, right: 20),
                      title: Text(sach['tenSach']),
                      subtitle: Text("${sach['soluong']} cuốn x ${sach['gianhap']} đ"),
                      trailing: Text("${sach['thanhTien']} đ"),
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}