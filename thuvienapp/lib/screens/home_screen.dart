import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sach.dart';
import '../models/user.dart';
import '../providers/api_service.dart';
import '../providers/borrow_cart_provider.dart';
import 'tab_truyen.dart';
import 'tab_tusach.dart';
import 'tab_toi.dart';
import 'DocGia/GioHang.dart';
import 'DocGia/TimKiem.dart';
import 'ListSach.dart';
import 'TuongTac.dart';
import '../widgets/book_section.dart';

class HomeScreen extends StatefulWidget {
  final User user;
  const HomeScreen({super.key, required this.user});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 1;
  late Future<List<Sach>> _futureSach;

  @override
  void initState() {
    super.initState();
    _futureSach = ApiService().fetchSaches();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // --- HÀM MỚI: Lấy chữ cái đầu của tên ---
  String _getAvatarLetter(String fullName) {
    if (fullName.isEmpty) return "U";
    // Tách chuỗi tên theo dấu cách
    List<String> parts = fullName.trim().split(' ');
    // Lấy từ cuối cùng (Tên) và lấy chữ cái đầu tiên, in hoa
    if (parts.isNotEmpty && parts.last.isNotEmpty) {
      return parts.last[0].toUpperCase();
    }
    return fullName[0].toUpperCase();
  }

  Widget buildHomeTab() {
    return FutureBuilder<List<Sach>>(
      future: _futureSach,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Lỗi: ${snapshot.error}"));
        } else {
          List<Sach> allBooks = snapshot.data ?? [];
          List<Sach> recommendedBooks = allBooks.take(5).toList();
          List<Sach> latestUpdates = allBooks.skip(5).toList();

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

          return SingleChildScrollView(
            child: Column(
              children: [
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

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildCategoryButton(
                          Icons.list, 'Thể Loại', showCategories),
                      _buildCategoryButton(Icons.tune, 'Bộ Lọc', showFilters),
                      _buildCategoryButton(
                          Icons.lightbulb_outlined, 'Tác Giả', showAuthors),
                      _buildCategoryButton(Icons.contact_support_outlined,
                          'Tương Tác', showInteraction),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                BookSection(
                  title: 'KHUYẾN KHÍCH ĐỌC',
                  books: recommendedBooks,
                  user: widget.user,
                  onSeeMore: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => BookListScreen(
                                title: "Sách Khuyến Khích",
                                books: recommendedBooks)));
                  },
                ),
                const SizedBox(height: 24),

                BookSection(
                  title: 'TRUYỆN MỚI CẬP NHẬT',
                  books: latestUpdates,
                  user: widget.user,
                  onSeeMore: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => BookListScreen(
                                title: "Mới Cập Nhật", books: latestUpdates)));
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

  @override
  Widget build(BuildContext context) {
    final List<Widget> widgetOptions = <Widget>[
      TabTuSach(user: widget.user),
      buildHomeTab(),
      TabToi(user: widget.user),
    ];

    // Lấy chữ cái để hiển thị
    String avatarLabel = _getAvatarLetter(widget.user.hoVaTen);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            // --- SỬA ĐỔI: Thay Icon bằng Text hiển thị chữ cái ---
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Viền màu xanh nhạt
                border: Border.all(
                    color: Colors.blueAccent.withOpacity(0.5), width: 2),
              ),
              child: CircleAvatar(
                backgroundColor: Colors.blueAccent, // Nền xanh nổi bật
                child: Text(
                  avatarLabel,
                  style: const TextStyle(
                    color: Colors.white, // Chữ màu trắng
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            // ----------------------------------------------------
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SearchScreen()));
                },
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20)),
                  child: const Row(
                    children: [
                      SizedBox(width: 12),
                      Icon(Icons.search, color: Colors.grey),
                      SizedBox(width: 8),
                      Text('Tìm Kiếm Truyện...',
                          style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined,
                      color: Colors.grey, size: 28),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => CartScreen(user: widget.user)));
                  },
                ),
                Positioned(
                  right: 5,
                  top: 5,
                  child: Consumer<BorrowCartProvider>(
                    builder: (context, cart, child) {
                      if (cart.itemCount == 0) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10)),
                        constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text('${cart.itemCount}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10),
                            textAlign: TextAlign.center),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Icon(Icons.bookmarks_outlined), label: 'Tủ Sách'),
          BottomNavigationBarItem(
              icon: Icon(Icons.menu_book), label: 'Truyện'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Tôi'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

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