import 'package:flutter/material.dart';
import '../models/sach.dart';
import '../models/user.dart';
import '../providers/api_service.dart';
import '../widgets/book_section.dart'; // Widget hiển thị danh sách ngang
import 'ChatbotScreen.dart'; // Import màn hình Chatbot
import 'ListSach.dart'; // Import màn hình danh sách sách
import 'TuongTac.dart'; // Import màn hình tương tác

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
    // Bọc FutureBuilder trong Scaffold để dùng được FloatingActionButton
    return Scaffold(
      // Phần nội dung chính
      body: FutureBuilder<List<Sach>>(
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
          // 3. Có dữ liệu -> Hiển thị giao diện
          else {
            List<Sach> allBooks = snapshot.data ?? [];

            // Chia sách thành 2 phần
            List<Sach> recommendedBooks = allBooks.take(5).toList();
            List<Sach> latestUpdates = allBooks.skip(5).toList();

            // --- CÁC HÀM XỬ LÝ SỰ KIỆN ---
            void showCategories() {
              final categories =
              allBooks.map((e) => e.theLoai ?? "Khác").toSet().toList();
              showModalBottomSheet(
                context: context,
                builder: (_) => ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (_, index) => ListTile(
                    title: Text(categories[index]),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      Navigator.pop(context);
                      final booksByCat = allBooks
                          .where((b) => b.theLoai == categories[index])
                          .toList();
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => BookListScreen(
                                  title: categories[index], books: booksByCat)));
                    },
                  ),
                ),
              );
            }

            void showAuthors() {
              final authors =
              allBooks.map((e) => e.tenTacGia ?? "Chưa rõ").toSet().toList();
              showModalBottomSheet(
                context: context,
                builder: (_) => ListView.builder(
                  itemCount: authors.length,
                  itemBuilder: (_, index) => ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(authors[index]),
                    onTap: () {
                      Navigator.pop(context);
                      final booksByAuthor = allBooks
                          .where((b) => b.tenTacGia == authors[index])
                          .toList();
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => BookListScreen(
                                  title: authors[index], books: booksByAuthor)));
                    },
                  ),
                ),
              );
            }

            void showFilters() {
              showModalBottomSheet(
                context: context,
                builder: (_) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.arrow_upward),
                      title: const Text("Giá: Thấp đến Cao"),
                      onTap: () {
                        Navigator.pop(context);
                        List<Sach> sorted = List.from(allBooks)
                          ..sort((a, b) => a.giamuon.compareTo(b.giamuon));
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => BookListScreen(
                                    title: "Giá tăng dần", books: sorted)));
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.arrow_downward),
                      title: const Text("Giá: Cao đến Thấp"),
                      onTap: () {
                        Navigator.pop(context);
                        List<Sach> sorted = List.from(allBooks)
                          ..sort((a, b) => b.giamuon.compareTo(a.giamuon));
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => BookListScreen(
                                    title: "Giá giảm dần", books: sorted)));
                      },
                    ),
                  ],
                ),
              );
            }

            void showInteraction() {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => InteractionScreen(user: widget.user)));
            }
            // -----------------------------

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
                      image: DecorationImage(
                        image: NetworkImage(ApiService.getImageUrl('banner.jpg')),
                        fit: BoxFit.cover,
                        onError: (exception, stackTrace) {
                           print("Lỗi tải banner: $exception");
                        },
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
                        _buildCategoryButton(Icons.list, 'Thể loại', showCategories),
                        _buildCategoryButton(Icons.tune, 'Bộ lọc', showFilters),
                        _buildCategoryButton(Icons.lightbulb_outlined, 'Tác giả', showAuthors),
                        _buildCategoryButton(Icons.contact_support_outlined, 'Tương tác', showInteraction),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- SECTION 1: KHUYẾN KHÍCH ĐỌC ---
                  BookSection(
                    title: 'KHUYẾN KHÍCH ĐỌC',
                    books: recommendedBooks,
                    user: widget.user, // Truyền user để mượn sách
                    onSeeMore: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => BookListScreen(
                                    title: "Sách khuyến khích",
                                    books: recommendedBooks)));
                      },
                  ),

                  const SizedBox(height: 24),

                  // --- SECTION 2: TRUYỆN MỚI CẬP NHẬT ---
                  BookSection(
                    title: 'TRUYỆN MỚI CẬP NHẬT',
                    books: latestUpdates,
                    user: widget.user, // Truyền user để mượn sách
                    onSeeMore: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => BookListScreen(
                                    title: "Mới cập nhật", books: latestUpdates)));
                      },
                  ),

                  const SizedBox(height: 80), // Padding dưới để không bị nút Chat che mất nội dung cuối
                ],
              ),
            );
          }
        },
      ),

      // 3. Nút Chatbot Trợ lý ảo (Floating Action Button)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Chuyển sang màn hình Chatbot
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatbotScreen()),
          );
        },
        backgroundColor: Colors.blueAccent, // Màu nền xanh
        elevation: 10, // Đổ bóng
        tooltip: 'Trợ lý ảo AI', // Hiện chữ khi nhấn giữ
        child: const Icon(
          Icons.support_agent, // Icon hình người đeo tai nghe
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }

  // Widget nút tròn nhỏ (Helper widget)
  Widget _buildCategoryButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.blueAccent.withOpacity(0.1),
            child: Icon(icon, color: Colors.blueAccent, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}