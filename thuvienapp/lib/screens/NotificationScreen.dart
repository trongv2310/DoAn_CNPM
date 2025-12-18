import 'package:flutter/material.dart';
import '../providers/api_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // Giả sử ApiService đã được cập nhật hàm fetchNewBooksNews gọi API /news-new-books
  // Tạm thời gọi trực tiếp hoặc giả lập nếu chưa update provider
  late Future<List<dynamic>> _futureNews;

  @override
  void initState() {
    super.initState();
    _futureNews = ApiService().fetchNewBooksNews(); // Cần thêm hàm này vào ApiService
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thông báo & Tin tức"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _futureNews,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          }
          final newsList = snapshot.data ?? [];
          if (newsList.isEmpty) {
            return const Center(child: Text("Chưa có tin tức nào mới."));
          }

          return ListView.builder(
            itemCount: newsList.length,
            padding: const EdgeInsets.all(10),
            itemBuilder: (context, index) {
              final item = newsList[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Giả lập Header bài viết
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.blueAccent,
                        child: Icon(Icons.inventory_2, color: Colors.white, size: 20),
                      ),
                      title: const Text("Thủ Kho", style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(item['ngayNhap'] ?? DateTime.now().toString()),
                      trailing: const Icon(Icons.more_horiz),
                    ),
                    // Ảnh sách
                    if (item['hinhAnh'] != null)
                      Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(ApiService.getImageUrl(item['hinhAnh'])),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "SÁCH MỚI: ${item['tenSach']}",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item['noiDung'] ?? "Hãy ghé thư viện mượn ngay nhé!",
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
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