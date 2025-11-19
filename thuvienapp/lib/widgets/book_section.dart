import 'package:flutter/material.dart';
import '../models/sach.dart'; // Import model Sach của chúng ta

class BookSection extends StatelessWidget {
  final String title;
  final List<Sach> books;
  final VoidCallback? onSeeMore;

  const BookSection({
    Key? key,
    required this.title,
    required this.books,
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
                onPressed: () {},
                child: const Text('Xem thêm'),
              ),
            ],
          ),
        ),
        // Danh sách sách cuộn ngang
        SizedBox(
          height: 240, // Chiều cao cố định cho vùng sách
          child: books.isEmpty
              ? const Center(child: Text("Đang cập nhật sách..."))
              : ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final sach = books[index];
              return Container(
                width: 140, // Chiều rộng mỗi cuốn sách
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ảnh bìa sách
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: sach.hinhanh != null && sach.hinhanh!.isNotEmpty
                            ? Image.network(
                          sach.hinhanh!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(color: Colors.grey[300], child: const Icon(Icons.broken_image)),
                        )
                            : Container(
                          color: Colors.blue[100],
                          child: const Center(child: Icon(Icons.book, size: 40, color: Colors.blue)),
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
                    // Giá tiền (Thay cho tên tác giả vì API chưa trả về tên tác giả)
                    Text(
                      "${sach.giamuon.toStringAsFixed(0)} đ",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}