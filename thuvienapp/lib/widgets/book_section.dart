import 'package:flutter/material.dart';
import '../models/sach.dart';
import '../models/user.dart';
import '../providers/api_service.dart';
import '../screens/ChiTietSach.dart';

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
                onPressed: onSeeMore,
                child: const Text('Xem thêm'),
              ),
            ],
          ),
        ),
        // Danh sách sách cuộn ngang
        SizedBox(
          height: 250, // Tăng chiều cao để chứa thẻ sách đẹp hơn
          child: books.isEmpty
              ? const Center(child: Text("Đang cập nhật sách..."))
              : ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final sach = books[index];
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
                  width: 130, // Giảm chiều rộng để có thể chứa nhiều sách hơn
                  margin: const EdgeInsets.only(right: 15, bottom: 8), // Thêm margin dưới
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(color: Colors.grey.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 4)),
                      ]
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ảnh bìa sách
                      Expanded(
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                              child: Container(
                                color: Colors.grey[200],
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
                            // Thẻ Thể loại (Category tag)
                            if (sach.theLoai != null)
                              Positioned(
                                top: 5,
                                left: 5,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    sach.theLoai!,
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tên sách
                            Text(
                              sach.tensach,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            // Tác giả
                            Text(
                              sach.tenTacGia ?? "Không rõ",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                            // Giá tiền
                            Text(
                              "${sach.giamuon.toStringAsFixed(0)} đ",
                              style: const TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold),
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
        ),
      ],
    );
  }
}