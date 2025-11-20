import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --- IMPORT CÁC MODELS VÀ PROVIDERS ---
import '../models/user.dart';
import '../providers/borrow_cart_provider.dart';

// --- IMPORT CÁC MÀN HÌNH CON ---
import 'tab_tusach.dart';
import 'tab_truyen.dart';
import 'tab_toi.dart';
import 'reader/cart_screen.dart';
import 'reader/search_screen.dart'; // <--- 1. QUAN TRỌNG: Import màn hình tìm kiếm

class HomeScreen extends StatefulWidget {
  final User user;

  const HomeScreen({super.key, required this.user});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 1;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> widgetOptions = <Widget>[
      TabTuSach(user: widget.user),
      TabTruyen(user: widget.user),
      TabToi(user: widget.user),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            // Avatar
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

            // --- 2. SỬA PHẦN THANH TÌM KIẾM ---
            Expanded(
              child: GestureDetector( // Bọc bằng GestureDetector để bắt sự kiện bấm
                onTap: () {
                  // Chuyển sang màn hình SearchScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SearchScreen()),
                  );
                },
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  // Thay TextField bằng Row tĩnh (để trông giống ô nhập liệu nhưng là nút bấm)
                  child: const Row(
                    children: [
                      SizedBox(width: 12),
                      Icon(Icons.search, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(
                        'Tìm Kiếm Truyện...',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // ----------------------------------

            const SizedBox(width: 10),

            // Icon Giỏ Hàng
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined, color: Colors.grey, size: 28),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => CartScreen(user: widget.user)));
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
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '${cart.itemCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(width: 5),

            // Icon Chuông
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
}