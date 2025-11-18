import 'package:flutter/material.dart';
import '../models/sach.dart';       // Dùng model Sach thật
import '../providers/api_service.dart'; // Dùng ApiService thật
import '../widgets/book_section.dart';
import 'borrowed_books_screen.dart';
import 'tab_toi.dart';
import 'tab_tusach.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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

            // Chia danh sách thành 2 phần giả lập (vì API trả về 1 list chung)
            // Ví dụ: 5 cuốn đầu cho phần "Khuyến Khích", phần còn lại cho "Mới"
            List<Sach> recommendedBooks = allBooks.take(5).toList();
            List<Sach> latestUpdates = allBooks.skip(5).toList();

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
                        // Ảnh banner mẫu
                        image: NetworkImage('https://i.ibb.co/C031mGf/main-banner.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    alignment: Alignment.center,
                  ),

                  const SizedBox(height: 16),

                  // --- Các nút danh mục (Category) ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildCategoryButton(Icons.list, 'Thể Loại'),
                        _buildCategoryButton(Icons.tune, 'Bộ Lọc'),
                        _buildCategoryButton(Icons.lightbulb_outlined, 'Tác Giả'),
                        _buildCategoryButton(Icons.contact_support_outlined, 'Tương Tác'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- Section 1: Khuyến Khích Đọc (Dữ liệu thật) ---
                  BookSection(title: 'KHUYẾN KHÍCH ĐỌC', books: recommendedBooks),

                  const SizedBox(height: 24),

                  // --- Section 2: Truyện Mới Cập Nhật (Dữ liệu thật) ---
                  BookSection(title: 'TRUYỆN MỚI CẬP NHẬT', books: latestUpdates),

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
      TabTuSach(), // Index 0: Tủ Sách
      buildHomeTab(),              // Index 1: Truyện (Giao diện chính có API)
      TabToi(), // Index 2: Tôi
    ];

    return Scaffold(
      // --- AppBar Giữ Nguyên Thiết Kế Của Bạn ---
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

      // --- Body thay đổi theo tab ---
      body: widgetOptions.elementAt(_selectedIndex),

      // --- BottomNavigationBar ---
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