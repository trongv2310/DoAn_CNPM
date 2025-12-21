import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import các màn hình và model
import '../models/user.dart';
import '../providers/api_service.dart';
import '../providers/borrow_cart_provider.dart';
import 'NotificationScreen.dart';
import 'login_screen.dart';
import 'tab_truyen.dart';
import 'tab_tusach.dart';
import 'tab_toi.dart';
import 'DocGia/GioHang.dart';
import 'DocGia/TimKiem.dart';

class HomeScreen extends StatefulWidget {
  final User? user; // Cho phép user null (Khách)
  const HomeScreen({super.key, required this.user});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Mặc định chọn tab 1 (Truyện) để khách vào thấy nội dung ngay,
  // thay vì vào tab 0 (Tủ sách) bị khóa.
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

  // Lấy chữ cái đầu của tên (Nếu là khách trả về icon mặc định sau)
  String _getAvatarLetter(String fullName) {
    if (fullName.isEmpty) return "G"; // G = Guest
    List<String> parts = fullName.trim().split(' ');
    if (parts.isNotEmpty && parts.last.isNotEmpty) {
      return parts.last[0].toUpperCase();
    }
    return fullName[0].toUpperCase();
  }

  // Hàm chuyển hướng sang trang đăng nhập
  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isGuest = widget.user == null;
    final String avatarLabel = isGuest ? "?" : _getAvatarLetter(widget.user!.hoVaTen);

    // Cấu hình danh sách các Tab
    final List<Widget> widgetOptions = [
      // TAB 0: Tủ Sách (Yêu cầu đăng nhập)
      isGuest
          ? const _LoginRequiredView(title: "Tủ sách cá nhân")
          : TabTuSach(user: widget.user!),

      // TAB 1: Trang Chủ / Truyện (Công khai)
      // Giả sử TabTruyen có constructor nhận User? hoặc không
      // Nếu TabTruyen chưa hỗ trợ user null, bạn cần cập nhật file tab_truyen.dart
      TabTruyen(user: widget.user),

      // TAB 2: Cá Nhân (Đã xử lý guest bên trong TabToi)
      TabToi(user: widget.user),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // Tắt nút back mặc định
        title: Row(
          children: [
            // --- AVATAR ---
            // Bọc Container trong GestureDetector để bắt sự kiện nhấn
            GestureDetector(
              onTap: () {
                _onItemTapped(2); // Gọi hàm chuyển tab sang Index 2 (Tab Tôi)
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.blueAccent.withOpacity(0.5), width: 2),
                ),
                child: CircleAvatar(
                  backgroundColor: isGuest ? Colors.grey : Colors.blueAccent,
                  child: isGuest
                      ? const Icon(Icons.person, color: Colors.white, size: 20)
                      : Text(
                    avatarLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // --- THANH TÌM KIẾM ---
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

            // --- NÚT THÔNG BÁO ---
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_outlined,
                      color: Colors.grey, size: 28),
                  onPressed: () {
                    // Reset số lượng thông báo khi bấm xem
                    setState(() {
                      _newBooksCount = 0;
                    });
                    // Cho phép khách xem thông báo (hoặc chặn nếu muốn)
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

            // --- NÚT GIỎ HÀNG ---
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined,
                      color: Colors.grey, size: 28),
                  onPressed: () {
                    if (isGuest) {
                      // Nếu là khách -> Yêu cầu đăng nhập
                      _navigateToLogin();
                    } else {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => CartScreen(user: widget.user!)));
                    }
                  },
                ),
                // Chỉ hiện số lượng badge nếu KHÔNG phải là khách
                if (!isGuest)
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

      // Hiển thị nội dung Tab được chọn
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

// --- WIDGET PHỤ: HIỂN THỊ KHI YÊU CẦU ĐĂNG NHẬP (CHO TAB TỦ SÁCH) ---
class _LoginRequiredView extends StatelessWidget {
  final String title;
  const _LoginRequiredView({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              "Bạn cần đăng nhập",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800]),
            ),
            const SizedBox(height: 10),
            const Text(
              "Vui lòng đăng nhập để xem tủ sách và quản lý phiếu mượn.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                backgroundColor: Colors.blue,
              ),
              child: const Text("Đăng nhập ngay", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}