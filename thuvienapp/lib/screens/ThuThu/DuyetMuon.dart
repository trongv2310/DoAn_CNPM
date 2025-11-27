import 'package:flutter/material.dart';
import '../../providers/api_service.dart';
import '../../models/user.dart';

class ApproveBorrowScreen extends StatefulWidget {
  final User user;
  const ApproveBorrowScreen({required this.user});

  @override
  _ApproveBorrowScreenState createState() => _ApproveBorrowScreenState();
}

class _ApproveBorrowScreenState extends State<ApproveBorrowScreen> {
  final ApiService _api = ApiService();
  late Future<List<dynamic>> _listFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() { _listFuture = _api.getPendingBorrowRequests(); });
  }

  void _approve(int maPhieu) async {
    bool success = await _api.approveRequest(maPhieu, widget.user.entityId);
    if(success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã duyệt phiếu #$maPhieu"), backgroundColor: Colors.green));
      _refresh();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi duyệt (Có thể hết sách)"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Duyệt Yêu Cầu Mượn")),
      body: FutureBuilder<List<dynamic>>(
        future: _listFuture,
        builder: (ctx, snapshot) {
          if(!snapshot.hasData) return Center(child: CircularProgressIndicator());
          if(snapshot.data!.isEmpty) return Center(child: Text("Không có yêu cầu nào."));

          return ListView.builder(
            padding: EdgeInsets.all(10),
            itemCount: snapshot.data!.length,
            itemBuilder: (ctx, i) {
              final item = snapshot.data![i];
              final books = item['sachMuon'] as List;
              return Card(
                margin: EdgeInsets.only(bottom: 10),
                child: ExpansionTile(
                  title: Text("SV: ${item['tenSinhVien']}"),
                  subtitle: Text("Ngày hẹn trả: ${item['hanTra']}"),
                  leading: CircleAvatar(child: Text("${item['maPhieu']}")),
                  children: [
                    ...books.map((b) => ListTile(
                      title: Text(b['tenSach']),
                      trailing: Text("x${b['soLuong']}"),
                      dense: true,
                    )),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: Size(double.infinity, 40)),
                        onPressed: () => _approve(item['maPhieu']),
                        child: Text("DUYỆT PHIẾU NÀY", style: TextStyle(color: Colors.white)),
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}