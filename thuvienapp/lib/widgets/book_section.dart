import 'package:flutter/material.dart';
import '../models/sach.dart';
import '../models/user.dart';
import '../providers/api_service.dart'; // <--- 1. Import để lấy ảnh
import '../screens/ChiTietSach.dart';   // <--- 2. Import màn hình chi tiết

class BookSection extends StatelessWidget {
  final String title;
  final List<Sach> books;
  final User user;
  final VoidCallback? onSeeMore;

  const BookSection({
    Key? key,
    required this.title,
    required this.books,
    required this.user,
    this.onSeeMore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tiêu đề section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: onSeeMore, // <--- 3. Gán hàm xem thêm
                child: const Text('Xem thêm'),
              ),
            ],
          ),
        ),
        // Danh sách sách cuộn ngang
        SizedBox(
          height: 240,
          child: books.isEmpty
              ? const Center(child: Text("Đang cập nhật sách..."))
              : ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final sach = books[index];

              // 4. Lấy link ảnh chuẩn từ server
              String imageUrl = ApiService.getImageUrl(sach.hinhanh);

              return GestureDetector( // <--- 5. Bọc để bấm được
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookDetailScreen(sach: sach),
                    ),
                  );
                },
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ảnh bìa sách
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            color: Colors.grey[200], // Màu nền khi đang tải
                            child: imageUrl.isNotEmpty
                                ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) =>
                              const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                            )
                                : Container(
                              color: Colors.blue[100],
                              child: const Center(child: Icon(Icons.book, size: 40, color: Colors.blue)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Tên sách
                      Text(
                        sach.tensach,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      // Giá tiền
                      Text(
                        "${sach.giamuon.toStringAsFixed(0)} đ",
                        style: const TextStyle(color: Colors.blueGrey, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}