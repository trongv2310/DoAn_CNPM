import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sach.dart';
import '../providers/borrow_cart_provider.dart';
import '../providers/api_service.dart';

class BookDetailScreen extends StatefulWidget {
  final Sach sach;

  const BookDetailScreen({Key? key, required this.sach}) : super(key: key);

  @override
  _BookDetailScreenState createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cart = Provider.of<BorrowCartProvider>(context, listen: false);
      int currentQty = cart.getQuantity(widget.sach);
      if (currentQty > 0) {
        setState(() {
          _quantity = currentQty;
        });
      }
    });
  }

  void _incrementQuantity() {
    if (_quantity < widget.sach.soluongton) {
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
    cart.add(widget.sach, _quantity);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Đã thêm $_quantity cuốn vào phiếu mượn!"), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    String imageUrl = ApiService.getImageUrl(widget.sach.hinhanh);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chi Tiết Sách"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ẢNH BÌA
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

            // TÊN SÁCH & GIÁ
            Text(
              widget.sach.tensach,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, height: 1.2),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  "${widget.sach.giamuon.toStringAsFixed(0)} đ",
                  style: const TextStyle(fontSize: 20, color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.sach.soluongton > 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.sach.soluongton > 0 ? "Còn ${widget.sach.soluongton} cuốn" : "Hết hàng",
                    style: TextStyle(color: widget.sach.soluongton > 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(thickness: 1),
            const SizedBox(height: 10),

            // THÔNG TIN CHI TIẾT
            Text("Thông tin chi tiết", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
            const SizedBox(height: 10),

            // --- SỬA LỖI Ở ĐÂY: theloai -> theLoai, tennxb (đúng), mota -> moTa ---
            _buildInfoRow(Icons.category_outlined, "Thể loại", widget.sach.theLoai ?? "Đang cập nhật"),
            _buildInfoRow(Icons.apartment_outlined, "Nhà xuất bản", widget.sach.tennxb ?? "Đang cập nhật"),
            _buildInfoRow(Icons.person_outline, "Tác giả", widget.sach.tenTacGia ?? "Đang cập nhật"),

            const SizedBox(height: 20),

            // MÔ TẢ
            Text("Mô tả sách", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
              child: Text(
                widget.sach.moTa ?? "Nội dung đang được cập nhật...", // Sửa mota -> moTa
                style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
                textAlign: TextAlign.justify,
              ),
            ),

            const SizedBox(height: 30),

            // NÚT THÊM VÀO GIỎ
            if (widget.sach.soluongton > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildQtyBtn(Icons.remove, _decrementQuantity),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text("$_quantity", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                  _buildQtyBtn(Icons.add, _incrementQuantity),
                ],
              ),
              const SizedBox(height: 20),
            ],

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.sach.soluongton > 0 ? Colors.blueAccent : Colors.grey,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                onPressed: widget.sach.soluongton > 0 ? _addToCart : null,
                child: Text(
                  widget.sach.soluongton > 0 ? "THÊM VÀO PHIẾU MƯỢN" : "TẠM THỜI HẾT SÁCH",
                  style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
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
      ),
    );
  }
}