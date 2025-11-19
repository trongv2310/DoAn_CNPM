import 'package:flutter/material.dart';
import '../models/sach.dart';
import '../models/user.dart';
import '../providers/api_service.dart';
import '../widgets/book_section.dart';
import 'borrowed_books_screen.dart';
import 'tab_toi.dart';
import 'book_list_screen.dart';

class HomeScreen extends StatefulWidget {
  final User user;

  const HomeScreen({super.key, required this.user});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 1; // Mặc định là tab 'Truyện'
  late Future<List<Sach>> _futureSach; // Biến để chứa dữ liệu từ API

  @override
  void initState() {
    super.initState();
    // Gọi API lấy sách một lần khi mở màn hình
    _futureSach = ApiService().fetchSaches();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Xây dựng nội dung cho Tab "Truyện" (Index 1)
    Widget buildHomeTab() {
      return FutureBuilder<List<Sach>>(
        future: _futureSach,
        builder: (context, snapshot) {
          // 1. Đang tải dữ liệu
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // 2. Có lỗi xảy ra
          else if (snapshot.hasError) {
            return Center(child: Text("Lỗi kết nối: ${snapshot.error}"));
          }
          // 3. Tải thành công -> Hiển thị giao diện
          else {
            // Lấy danh sách sách
            List<Sach> allBooks = snapshot.data ?? [];

            // Chia danh sách thành 2 phần giả lập
            List<Sach> recommendedBooks = allBooks.take(5).toList();
            List<Sach> latestUpdates = allBooks.skip(5).toList();

            // --- ĐỊNH NGHĨA CÁC HÀM CHỨC NĂNG Ở ĐÂY (BÊN TRONG KHỐI ELSE) ---
            // Lý do: Để các hàm này có thể truy cập biến `allBooks` và `context`

            // 1. Hàm xử lý Thể Loại
            void showCategories() {
              final categories = allBooks.map((e) => e.theLoai ?? "Khác").toSet().toList();
              showModalBottomSheet(
                context: context,
                builder: (_) => ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (_, index) => ListTile(
                    title: Text(categories[index]),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      Navigator.pop(context); // Đóng menu
                      // Lọc sách và chuyển màn hình
                      final booksByCat = allBooks.where((b) => b.theLoai == categories[index]).toList();
                      Navigator.push(context, MaterialPageRoute(builder: (_) => BookListScreen(title: categories[index], books: booksByCat)));
                    },
                  ),
                ),
              );
            }

            // 2. Hàm xử lý Tác Giả
            void showAuthors() {
              final authors = allBooks.map((e) => e.tenTacGia ?? "Chưa rõ").toSet().toList();
              showModalBottomSheet(
                context: context,
                builder: (_) => ListView.builder(
                  itemCount: authors.length,
                  itemBuilder: (_, index) => ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(authors[index]),
                    onTap: () {
                      Navigator.pop(context);
                      final booksByAuthor = allBooks.where((b) => b.tenTacGia == authors[index]).toList();
                      Navigator.push(context, MaterialPageRoute(builder: (_) => BookListScreen(title: authors[index], books: booksByAuthor)));
                    },
                  ),
                ),
              );
            }

            // 3. Hàm xử lý Bộ Lọc (Giá)
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
                        List<Sach> sorted = List.from(allBooks)..sort((a, b) => a.giamuon.compareTo(b.giamuon));
                        Navigator.push(context, MaterialPageRoute(builder: (_) => BookListScreen(title: "Giá tăng dần", books: sorted)));
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.arrow_downward),
                      title: const Text("Giá: Cao đến Thấp"),
                      onTap: () {
                        Navigator.pop(context);
                        List<Sach> sorted = List.from(allBooks)..sort((a, b) => b.giamuon.compareTo(a.giamuon));
                        Navigator.push(context, MaterialPageRoute(builder: (_) => BookListScreen(title: "Giá giảm dần", books: sorted)));
                      },
                    ),
                  ],
                ),
              );
            }

            // 4. Hàm xử lý Tương Tác
            void showInteraction() {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tính năng đang phát triển")));
            }
            // ----------------------------------------------------------------

            return SingleChildScrollView(
              child: Column(
                children: [
                  // --- Banner Chính ---
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
                    alignment: Alignment.center,
                  ),

                  const SizedBox(height: 16),

                  // --- Các nút danh mục (Đã có hàm để gọi) ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildCategoryButton(Icons.list, 'Thể Loại', showCategories),
                        _buildCategoryButton(Icons.tune, 'Bộ Lọc', showFilters),
                        _buildCategoryButton(Icons.lightbulb_outlined, 'Tác Giả', showAuthors),
                        _buildCategoryButton(Icons.contact_support_outlined, 'Tương Tác', showInteraction),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- Section 1: Khuyến Khích Đọc ---
                  BookSection(
                    title: 'KHUYẾN KHÍCH ĐỌC',
                    books: recommendedBooks,
                    onSeeMore: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => BookListScreen(title: "Sách Khuyến Khích", books: recommendedBooks)));
                    },
                  ),

                  const SizedBox(height: 24),

                  // --- Section 2: Truyện Mới ---
                  BookSection(
                    title: 'TRUYỆN MỚI CẬP NHẬT',
                    books: latestUpdates,
                    onSeeMore: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => BookListScreen(title: "Mới Cập Nhật", books: latestUpdates)));
                    },
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            );
          }
        },
      );
    }

    // Danh sách các màn hình tương ứng với BottomNavigationBar
    final List<Widget> widgetOptions = <Widget>[
      const BorrowedBooksScreen(), // Index 0
      buildHomeTab(),              // Index 1
      TabToi(user: widget.user),   // Index 2
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.withOpacity(0.8), width: 2.5),
              ),
              child: const CircleAvatar(
                backgroundColor: Colors.white54,
                child: Icon(Icons.person, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    hintText: 'Tìm Kiếm Truyện...',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.notifications_none, color: Colors.grey, size: 28),
          ],
        ),
      ),
      body: widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.bookmarks_outlined), label: 'Tủ Sách'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Truyện'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Tôi'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  // Widget nút danh mục nhỏ
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