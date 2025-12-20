import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sach.dart';
import '../providers/borrow_cart_provider.dart';
import '../providers/api_service.dart';
import '../providers/user_provider.dart';

class BookDetailScreen extends StatefulWidget {
  final Sach sach;

  const BookDetailScreen({Key? key, required this.sach}) : super(key: key);

  @override
  _BookDetailScreenState createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  int _quantity = 1;
  late Sach _currentSach;
  bool _isLoading = true;

  // Biến cho phần đánh giá
  List<dynamic> _reviews = [];
  double _averageRating = 0.0;
  bool _isLoadingReviews = true;

  @override
  void initState() {
    super.initState();
    _currentSach = widget.sach;
    _refreshBookData();
    _fetchReviews(); // Lấy danh sách đánh giá ngay khi vào trang
  }

  // Lấy thông tin sách mới nhất (Tồn kho, giá...)
  Future<void> _refreshBookData() async {
    try {
      final books = await ApiService().fetchSaches();
      final updatedBook = books.firstWhere(
              (b) => b.masach == widget.sach.masach,
          orElse: () => widget.sach);

      if (mounted) {
        setState(() {
          _currentSach = updatedBook;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Lỗi làm mới sách: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Lấy danh sách đánh giá và tính điểm trung bình
  Future<void> _fetchReviews() async {
    final data = await ApiService().getReviewsByBookId(widget.sach.masach);
    if (mounted) {
      setState(() {
        _reviews = data;
        _isLoadingReviews = false;

        // Tính trung bình cộng
        if (_reviews.isNotEmpty) {
          double total = 0;
          for (var r in _reviews) {
            total += (r['diem'] ?? 0);
          }
          _averageRating = total / _reviews.length;
        } else {
          _averageRating = 0.0;
        }
      });
    }
  }

  // --- LOGIC ĐÁNH GIÁ SÁCH ---
  void _showRatingDialog() {
    int _stars = 5;
    TextEditingController _commentController = TextEditingController();

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng đăng nhập để đánh giá!")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Đánh giá sách"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Bạn thấy cuốn sách này thế nào?"),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < _stars ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setStateDialog(() {
                            _stars = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      labelText: "Viết nhận xét (tùy chọn)",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Hủy"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    bool success = await ApiService().guiDanhGiaSach(
                      widget.sach.masach,
                      user.entityId,
                      _stars,
                      _commentController.text,
                    );

                    Navigator.pop(context);

                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Cảm ơn bạn đã đánh giá!"), backgroundColor: Colors.green),
                      );
                      _fetchReviews(); // Tải lại danh sách sau khi đánh giá
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Lỗi khi gửi đánh giá"), backgroundColor: Colors.red),
                      );
                    }
                  },
                  child: const Text("Gửi"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- LOGIC MƯỢN SÁCH ---
  void _incrementQuantity() {
    if (_quantity < _currentSach.soluongton) {
      setState(() {
        _quantity++;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Không thể mượn quá số lượng tồn kho!")),
      );
    }
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  void _addToCart() {
    final cart = Provider.of<BorrowCartProvider>(context, listen: false);
    cart.add(_currentSach, _quantity);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Đã thêm $_quantity cuốn vào phiếu mượn!"), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    String imageUrl = ApiService.getImageUrl(_currentSach.hinhanh);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chi Tiết Sách"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _refreshBookData();
              _fetchReviews();
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Ảnh bìa
            Center(
              child: Container(
                height: 280,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], width: 180, child: const Icon(Icons.broken_image)),
                  )
                      : Container(color: Colors.blue[100], width: 180, child: const Icon(Icons.book, size: 60, color: Colors.blue)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 2. Tên & Giá
            Text(
              _currentSach.tensach,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, height: 1.2),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  "${_currentSach.giamuon.toStringAsFixed(0)} đ",
                  style: const TextStyle(fontSize: 20, color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _currentSach.soluongton > 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _currentSach.soluongton > 0 ? "Còn ${_currentSach.soluongton} cuốn" : "Hết hàng",
                    style: TextStyle(color: _currentSach.soluongton > 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(thickness: 1),
            const SizedBox(height: 10),

            // 3. Thông tin chi tiết
            Text("Thông tin chi tiết", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
            const SizedBox(height: 10),
            _buildInfoRow(Icons.category_outlined, "Thể loại", _currentSach.theLoai ?? "Đang cập nhật"),
            _buildInfoRow(Icons.apartment_outlined, "Nhà xuất bản", _currentSach.tennxb ?? "Đang cập nhật"),
            _buildInfoRow(Icons.person_outline, "Tác giả", _currentSach.tenTacGia ?? "Đang cập nhật"),

            const SizedBox(height: 20),

            // 4. Mô tả
            Text("Mô tả sách", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
              child: Text(
                _currentSach.moTa ?? "Nội dung đang được cập nhật...",
                style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
                textAlign: TextAlign.justify,
              ),
            ),

            const SizedBox(height: 30),
            const Divider(thickness: 1),
            const SizedBox(height: 10),

            // 5. PHẦN ĐÁNH GIÁ & NHẬN XÉT
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Đánh giá & Nhận xét", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        "${_averageRating.toStringAsFixed(1)}/5 (${_reviews.length})",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
                      ),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 10),

            // Nút viết đánh giá
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showRatingDialog,
                icon: const Icon(Icons.rate_review, color: Colors.blue),
                label: const Text("Viết đánh giá của bạn", style: TextStyle(color: Colors.blue)),
              ),
            ),

            const SizedBox(height: 10),

            // Danh sách comment
            _isLoadingReviews
                ? const Center(child: CircularProgressIndicator())
                : _reviews.isEmpty
                ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text("Chưa có đánh giá nào. Hãy là người đầu tiên!", style: TextStyle(color: Colors.grey))),
            )
                : ListView.builder(
              shrinkWrap: true, // Quan trọng để nằm trong SingleChildScrollView
              physics: const NeverScrollableScrollPhysics(), // Không cuộn riêng
              itemCount: _reviews.length,
              itemBuilder: (context, index) {
                final item = _reviews[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blue[100],
                            radius: 16,
                            child: Text(item['tenSinhVien'] != null ? item['tenSinhVien'][0] : 'U', style: const TextStyle(fontSize: 14)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['tenSinhVien'] ?? "Ẩn danh", style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(item['ngayDanhGia'] ?? "", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                              ],
                            ),
                          ),
                          Row(
                            children: List.generate(5, (starIndex) {
                              return Icon(
                                starIndex < (item['diem'] ?? 0) ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 16,
                              );
                            }),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (item['nhanXet'] != null && item['nhanXet'].toString().isNotEmpty)
                        Text(item['nhanXet'], style: const TextStyle(color: Colors.black87)),
                    ],
                  ),
                );
              },
            ),

            // Khoảng trống dưới cùng
            const SizedBox(height: 80),
          ],
        ),
      ),

      // BOTTOM BAR: Cố định phần Mua hàng/Mượn sách ở đáy
      bottomNavigationBar: _isLoading
          ? null
          : Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, -5))
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Hàng chọn số lượng
              if (_currentSach.soluongton > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Số lượng:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 15),
                    _buildQtyBtn(Icons.remove, _decrementQuantity),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text("$_quantity", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    _buildQtyBtn(Icons.add, _incrementQuantity),
                  ],
                ),
                const SizedBox(height: 15),
              ],

              // Nút Thêm vào phiếu mượn
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentSach.soluongton > 0 ? Colors.blueAccent : Colors.grey,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  onPressed: _currentSach.soluongton > 0 ? _addToCart : null,
                  child: Text(
                    _currentSach.soluongton > 0 ? "THÊM VÀO PHIẾU MƯỢN" : "TẠM THỜI HẾT SÁCH",
                    style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, size: 20),
        onPressed: onPressed,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        padding: EdgeInsets.zero,
      ),
    );
  }
}