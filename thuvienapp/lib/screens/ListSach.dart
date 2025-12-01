import 'package:flutter/material.dart';
import '../models/sach.dart';
import '../providers/api_service.dart'; // Import để lấy link ảnh
import 'ChiTietSach.dart'; // <--- 1. Import màn hình chi tiết

class BookListScreen extends StatelessWidget {
  final String title;
  final List<Sach> books;

  const BookListScreen({Key? key, required this.title, required this.books}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: books.isEmpty
          ? const Center(child: Text("Không có sách nào"))
          : GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: books.length,
        itemBuilder: (context, index) {
          final s = books[index];

          // Lấy đường dẫn ảnh chuẩn
          String imageUrl = ApiService.getImageUrl(s.hinhanh);

          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            // <--- 2. Bọc bằng InkWell để bắt sự kiện click
            child: InkWell(
              borderRadius: BorderRadius.circular(10), // Bo tròn hiệu ứng click theo Card
              onTap: () {
                // Chuyển sang màn hình chi tiết
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookDetailScreen(sach: s),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                      child: Container(
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        )
                            : Container(
                          color: Colors.blue[100],
                          child: const Icon(Icons.book, size: 40, color: Colors.blue),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.tensach,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          s.tenTacGia ?? "TG",
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${s.giamuon.toStringAsFixed(0)} đ",
                          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}