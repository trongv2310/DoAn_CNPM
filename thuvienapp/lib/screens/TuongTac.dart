import 'package:flutter/material.dart';
import '../models/user.dart';
import '../providers/api_service.dart';

class InteractionScreen extends StatelessWidget {
  final User user;

  const InteractionScreen({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Sử dụng DefaultTabController để quản lý 3 tabs
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Tương Tác & Phản Hồi"),
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.question_answer), text: "Hỏi Đáp"),
              Tab(icon: Icon(Icons.feedback), text: "Góp Ý"),
              Tab(icon: Icon(Icons.star), text: "Đánh Giá"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            TabHoiDap(user: user),
            TabGopY(user: user),
            TabDanhGia(),
          ],
        ),
      ),
    );
  }
}

// ================= TAB 1: HỎI ĐÁP =================
class TabHoiDap extends StatefulWidget {
  final User user;
  const TabHoiDap({required this.user});

  @override
  _TabHoiDapState createState() => _TabHoiDapState();
}

class _TabHoiDapState extends State<TabHoiDap> {
  final ApiService _apiService = ApiService();
  final TextEditingController _questionController = TextEditingController();
  late Future<List<dynamic>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _refreshList();
  }

  void _refreshList() {
    setState(() {
      _historyFuture = _apiService.layLichSuHoiDap(widget.user.entityId);
    });
  }

  void _sendQuestion() async {
    if (_questionController.text.isEmpty) return;
    bool success = await _apiService.guiCauHoi(widget.user.entityId, _questionController.text);
    if (success) {
      _questionController.clear();
      Navigator.pop(context); // Đóng dialog
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã gửi câu hỏi!")));
      _refreshList();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gửi thất bại!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        child: Icon(Icons.add, color: Colors.white),
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text("Đặt câu hỏi cho Thủ thư"),
              content: TextField(
                controller: _questionController,
                decoration: InputDecoration(hintText: "Nhập câu hỏi của bạn..."),
                maxLines: 3,
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text("Hủy")),
                ElevatedButton(onPressed: _sendQuestion, child: Text("Gửi")),
              ],
            ),
          );
        },
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text("Bạn chưa có câu hỏi nào"));

          return ListView.builder(
            padding: EdgeInsets.all(10),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final item = snapshot.data![index];
              bool hasAnswer = item['traloi'] != null && item['traloi'].toString().isNotEmpty;

              return Card(
                child: ExpansionTile(
                  leading: Icon(Icons.help_outline, color: hasAnswer ? Colors.green : Colors.orange),
                  title: Text(item['cauhoi'], style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(item['thoiGian']),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(15),
                      color: Colors.grey[100],
                      child: Text(
                        hasAnswer ? "Trả lời: ${item['traloi']}" : "Chưa có câu trả lời từ thủ thư.",
                        style: TextStyle(color: hasAnswer ? Colors.black87 : Colors.grey),
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

// ================= TAB 2: GÓP Ý =================
class TabGopY extends StatefulWidget {
  final User user;
  const TabGopY({required this.user});

  @override
  _TabGopYState createState() => _TabGopYState();
}

class _TabGopYState extends State<TabGopY> {
  final ApiService _apiService = ApiService();
  final TextEditingController _contentController = TextEditingController();
  String _selectedType = "Cơ sở vật chất";
  final List<String> _types = ["Cơ sở vật chất", "Thái độ phục vụ", "Tài liệu sách", "Khác"];

  void _sendFeedback() async {
    if (_contentController.text.isEmpty) return;
    bool success = await _apiService.guiGopY(widget.user.entityId, _contentController.text, _selectedType);
    if (success) {
      _contentController.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Cảm ơn đóng góp của bạn!")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi khi gửi góp ý!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Loại góp ý:", style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: _selectedType,
              isExpanded: true,
              items: _types.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => _selectedType = val!),
            ),
            SizedBox(height: 20),
            Text("Nội dung:", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "Hãy cho chúng tôi biết ý kiến của bạn...",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: Icon(Icons.send, color: Colors.white),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                label: Text("GỬI GÓP Ý", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: _sendFeedback,
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ================= TAB 3: ĐÁNH GIÁ (CỘNG ĐỒNG) =================
class TabDanhGia extends StatelessWidget {
  final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _apiService.layDanhGiaMoi(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text("Chưa có đánh giá nào"));

        return ListView.builder(
          padding: EdgeInsets.all(10),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final item = snapshot.data![index];
            final int score = item['diem'] ?? 0;

            return Card(
              elevation: 3,
              margin: EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.book, size: 20, color: Colors.blue),
                        SizedBox(width: 5),
                        Expanded(child: Text(item['tenSach'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                      ],
                    ),
                    SizedBox(height: 5),
                    Row(
                      children: List.generate(5, (i) => Icon(
                        i < score ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 18,
                      )),
                    ),
                    SizedBox(height: 8),
                    Text("\"${item['nhanXet']}\"", style: TextStyle(fontStyle: FontStyle.italic)),
                    SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text("- ${item['tenSinhVien']} (${item['ngayDanhGia']})", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}