import 'package:flutter/material.dart';
import '../../providers/api_service.dart';
import '../../models/user.dart';

class SupportReaderScreen extends StatefulWidget {
  final User user;
  const SupportReaderScreen({required this.user});

  @override
  _SupportReaderScreenState createState() => _SupportReaderScreenState();
}

class _SupportReaderScreenState extends State<SupportReaderScreen> {
  final ApiService _api = ApiService();

  void _showReplyDialog(int maHoiDap) {
    final txtController = TextEditingController();
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Trả lời độc giả"),
          content: TextField(
            controller: txtController,
            decoration: InputDecoration(hintText: "Nhập câu trả lời..."),
            maxLines: 3,
          ),
          actions: [
            TextButton(onPressed: ()=>Navigator.pop(context), child: Text("Hủy")),
            ElevatedButton(
                onPressed: () async {
                  bool ok = await _api.replyQuestion(maHoiDap, widget.user.entityId, txtController.text);
                  Navigator.pop(context);
                  if(ok) setState((){}); // Reload list
                },
                child: Text("Gửi")
            )
          ],
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Hỗ Trợ Độc Giả")),
      body: FutureBuilder<List<dynamic>>(
        future: _api.getAllQuestions(),
        builder: (ctx, snapshot) {
          if(!snapshot.hasData) return Center(child: CircularProgressIndicator());
          final list = snapshot.data!;
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (ctx, i) {
              final item = list[i];
              bool isReplied = item['trangthai'] == "Đã trả lời";
              return Card(
                color: isReplied ? Colors.grey[200] : Colors.white,
                child: ListTile(
                  leading: Icon(Icons.person_outline),
                  title: Text(item['cauhoi'], style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Bởi: ${item['tenSinhVien']} - ${item['thoiGian']}"),
                      if(isReplied) Text("Đã trả lời: ${item['traloi']}", style: TextStyle(color: Colors.green))
                    ],
                  ),
                  trailing: !isReplied
                      ? IconButton(icon: Icon(Icons.reply, color: Colors.blue), onPressed: () => _showReplyDialog(item['mahoidap']))
                      : Icon(Icons.check, color: Colors.green),
                ),
              );
            },
          );
        },
      ),
    );
  }
}