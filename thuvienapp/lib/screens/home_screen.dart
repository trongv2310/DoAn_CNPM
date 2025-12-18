import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'NotificationScreen.dart';
import '../models/user.dart';
import '../providers/api_service.dart';
import '../providers/borrow_cart_provider.dart';
import 'tab_truyen.dart';
import 'tab_tusach.dart';
import 'tab_toi.dart';
import 'DocGia/GioHang.dart';
import 'DocGia/TimKiem.dart';

class HomeScreen extends StatefulWidget {
  final User user;
  const HomeScreen({super.key, required this.user});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 1;
  int _newBooksCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchNotificationCount();
  }

  void _fetchNotificationCount() async {
    try {
      var newsList = await ApiService().fetchNewBooksNews();
      if (mounted) {
        setState(() {
          _newBooksCount = newsList.length;
        });
      }
    } catch (e) {
      print("Lỗi tải thông báo: $e");
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _getAvatarLetter(String fullName) {
    if (fullName.isEmpty) return "U";
    List<String> parts = fullName.trim().split(' ');
    if (parts.isNotEmpty && parts.last.isNotEmpty) {
      return parts.last[0].toUpperCase();
    }
    return fullName[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    // Sử dụng TabTruyen thay vì buildHomeTab
    final List<Widget> widgetOptions = <Widget>[
      TabTuSach(user: widget.user),
      TabTruyen(user: widget.user), 
      TabToi(user: widget.user),
    ];

    String avatarLabel = _getAvatarLetter(widget.user.hoVaTen);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.blueAccent.withOpacity(0.5), width: 2),
              ),
              child: CircleAvatar(
                backgroundColor: Colors.blueAccent,
                child: Text(
                  avatarLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
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
                      Text('Tìm kiếm truyện...',
                          style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 5),
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_outlined,
                      color: Colors.grey, size: 28),
                  onPressed: () {
                    setState(() {
                      _newBooksCount = 0;
                    });
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const NotificationScreen()));
                  },
                ),
                if (_newBooksCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$_newBooksCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
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
              icon: Icon(Icons.bookmarks_outlined), label: 'Tủ sách'),
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
}