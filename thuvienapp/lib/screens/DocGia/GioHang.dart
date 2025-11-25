import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Cần import intl để format ngày

// --- IMPORT CÁC FILE CẦN THIẾT (Đường dẫn ../.. vì file này nằm trong folder con DocGia) ---
import '../../models/user.dart';
import '../../providers/borrow_cart_provider.dart'; // Chứa CartItem, items
import '../../providers/api_service.dart'; // Chứa SachMuonRequest, getImageUrl
import 'receipt_screen.dart'; // Màn hình hóa đơn (cùng thư mục DocGia)

class CartScreen extends StatefulWidget {
  final User user; // Nhận User từ HomeScreen
  const CartScreen({super.key, required this.user});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isLoading = false;

  // 1. Khởi tạo ngày hẹn trả (Mặc định là 7 ngày sau)
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));

  // Hàm chọn ngày
  void _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().add(const Duration(days: 1)), // Ít nhất là ngày mai
      lastDate: DateTime.now().add(const Duration(days: 60)), // Tối đa 60 ngày
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Hàm xử lý gửi phiếu mượn
  void _handleSubmitRequest(BorrowCartProvider cart) async {
    // Kiểm tra giỏ hàng rỗng
    if (cart.items.isEmpty) return;

    setState(() => _isLoading = true);

    // 2. Lưu tạm dữ liệu để truyền sang màn hình Hóa Đơn (vì sau đó sẽ xóa giỏ)
    final itemsSnapshot = Map<int, CartItem>.from(cart.items);
    final double totalSnapshot = cart.totalAmount;

    // 3. Chuẩn bị dữ liệu gửi đi (List<SachMuonRequest>)
    List<SachMuonRequest> requestList = cart.items.values.map((item) {
      return SachMuonRequest(
        maSach: item.sach.masach,
        soLuong: item.quantity,
      );
    }).toList();

    // 4. Gọi API
    // Lưu ý: Dùng user.entityId (MaSV) hoặc user.maTaiKhoan tùy theo Backend yêu cầu
    // Ở đây mình dùng maTaiKhoan cho đồng bộ với các bước trước
    final result = await ApiService().muonNhieuSachFull(
        widget.user.maTaiKhoan,
        requestList,
        _selectedDate // Truyền ngày hẹn trả
    );

    setState(() => _isLoading = false);

    // 5. Xử lý kết quả
    if (result['success'] == true) {
      // Thành công -> Xóa giỏ hàng
      cart.clear();

      if (mounted) {
        // --- CHUYỂN SANG MÀN HÌNH HÓA ĐƠN ---
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ReceiptScreen(
              user: widget.user,
              orderItems: itemsSnapshot,           // Danh sách sách
              maPhieuMuon: result['maPhieuMuon'],  // Mã phiếu từ API
              totalPrice: totalSnapshot,           // Tổng tiền
              ngayHenTra: _selectedDate,           // Ngày trả
            ),
          ),
        );
      }
    } else {
      // Thất bại
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? "Gửi yêu cầu thất bại!"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<BorrowCartProvider>(context);
    final cartItems = cart.items.values.toList();
    String dateText = DateFormat('dd/MM/yyyy').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Phiếu Mượn (Giỏ Sách)"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: cartItems.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.remove_shopping_cart, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text("Chưa có sách nào trong phiếu", style: TextStyle(color: Colors.grey)),
          ],
        ),
      )
          : Column(
        children: [
          // --- DANH SÁCH SÁCH ---
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];

                // Lấy ảnh chuẩn từ API Service
                String imageUrl = ApiService.getImageUrl(item.sach.hinhanh);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        // Ảnh sách
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            width: 50,
                            height: 75,
                            child: imageUrl.isNotEmpty
                                ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_,__,___) => const Icon(Icons.broken_image, color: Colors.grey)
                            )
                                : Container(color: Colors.blue[100], child: const Icon(Icons.book)),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Thông tin
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  item.sach.tensach,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis
                              ),
                              const SizedBox(height: 4),
                              Text("Giá: ${item.sach.giamuon.toInt()} đ", style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                            ],
                          ),
                        ),

                        // Số lượng & Nút xóa
                        Row(
                          children: [
                            Text("x${item.quantity}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                cart.remove(item.sach.masach);
                              },
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // --- PHẦN CHỌN NGÀY & GỬI ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Widget Chọn Ngày Trả
                  InkWell(
                    onTap: _pickDate,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.calendar_month, color: Colors.blue),
                            SizedBox(width: 8),
                            Text("Ngày trả sách:", style: TextStyle(fontSize: 16)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.blue),
                              borderRadius: BorderRadius.circular(5)
                          ),
                          child: Text(
                            dateText, // Ngày đã format
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tổng số lượng
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Tổng số lượng:", style: TextStyle(fontSize: 16)),
                      Text("${cart.itemCount} cuốn", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Nút Gửi
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                      onPressed: _isLoading ? null : () => _handleSubmitRequest(cart),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("GỬI YÊU CẦU MƯỢN", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}