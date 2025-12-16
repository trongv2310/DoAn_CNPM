import 'package:flutter/material.dart';
import '../models/sach.dart';
import '../models/user.dart';
import '../providers/api_service.dart';
import '../widgets/book_section.dart'; // <-- Import Widget hiển thị danh sách ngang

class TabTruyen extends StatefulWidget {
  final User user; // Nhận User từ HomeScreen
  const TabTruyen({super.key, required this.user});

  @override
  _TabTruyenState createState() => _TabTruyenState();
}

class _TabTruyenState extends State<TabTruyen> {
  final ApiService apiService = ApiService();
  late Future<List<Sach>> futureSach;

  @override
  void initState() {
    super.initState();
    futureSach = apiService.fetchSaches();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Sach>>(
      future: futureSach,
      builder: (context, snapshot) {
        // 1. Đang tải
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        // 2. Lỗi
        else if (snapshot.hasError) {
          return Center(child: Text("Lỗi kết nối: ${snapshot.error}"));
        }
        // 3. Có dữ liệu -> Hiển thị giao diện giống ảnh
        else {
          List<Sach> allBooks = snapshot.data ?? [];

          // Chia sách thành 2 phần
          List<Sach> recommendedBooks = allBooks.take(5).toList();
          List<Sach> latestUpdates = allBooks.skip(5).toList();

          return SingleChildScrollView(
            child: Column(
              children: [
                // --- BANNER ---
                Container(
                  height: 200,
                  margin: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                    image: const DecorationImage(
                      image: NetworkImage('https://i.ibb.co/C031mGf/main-banner.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // --- CÁC NÚT DANH MỤC TRÒN ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildCategoryButton(Icons.list, 'Thể loại'),
                      _buildCategoryButton(Icons.tune, 'Bộ lọc'),
                      _buildCategoryButton(Icons.lightbulb_outlined, 'Tác giả'),
                      _buildCategoryButton(Icons.contact_support_outlined, 'Tương tác'),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // --- SECTION 1: KHUYẾN KHÍCH ĐỌC ---
                BookSection(
                  title: 'KHUYẾN KHÍCH ĐỌC',
                  books: recommendedBooks,
                  user: widget.user, // Truyền user để mượn sách
                ),

                const SizedBox(height: 24),

                // --- SECTION 2: TRUYỆN MỚI CẬP NHẬT ---
                BookSection(
                  title: 'TRUYỆN MỚI CẬP NHẬT',
                  books: latestUpdates,
                  user: widget.user, // Truyền user để mượn sách
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        }
      },
    );
  }

  // Widget nút tròn nhỏ
  Widget _buildCategoryButton(IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: Colors.blueAccent.withOpacity(0.1),
          child: Icon(icon, color: Colors.blueAccent, size: 30),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}