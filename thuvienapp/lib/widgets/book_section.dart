import 'package:flutter/material.dart';
import '../models/sach.dart';
import '../models/user.dart';
import '../screens/book_detail_screen.dart';
import '../providers/api_service.dart'; // <--- 1. QUAN TRỌNG: Import ApiService để lấy hàm xử lý ảnh

class BookSection extends StatelessWidget {
  final String title;
  final List<Sach> books;
  final User user;

  const BookSection({
    super.key,
    required this.title,
    required this.books,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tiêu đề Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Text('Xem thêm', style: TextStyle(color: Colors.blueAccent)),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Danh sách sách cuộn ngang
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: books.length,
            itemBuilder: (context, index) {
              final sach = books[index];

              // 2. GỌI HÀM LẤY ẢNH CHUẨN TỪ API SERVICE
              String imageUrl = ApiService.getImageUrl(sach.hinhanh);

              return GestureDetector(
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
                  margin: EdgeInsets.only(left: index == 0 ? 16.0 : 0, right: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 3. KHUNG CHỨA ẢNH (ĐÃ SỬA)
                      Container(
                        height: 180,
                        width: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[200], // Màu nền khi chưa tải ảnh
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        // Dùng ClipRRect để bo góc cho ảnh
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            // Xử lý khi ảnh lỗi (ví dụ server chưa bật)
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(Icons.broken_image, color: Colors.grey),
                              );
                            },
                          )
                              : const Center(
                            child: Icon(Icons.book, size: 50, color: Colors.grey),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Tên sách
                      Text(
                        sach.tensach,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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