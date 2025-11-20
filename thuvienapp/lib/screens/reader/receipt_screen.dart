import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user.dart';
import '../../providers/borrow_cart_provider.dart';

class ReceiptScreen extends StatelessWidget {
  final User user;
  final Map<int, CartItem> orderItems;
  final int maPhieuMuon;
  final double totalPrice;
  final DateTime ngayHenTra;

  const ReceiptScreen({
    super.key,
    required this.user,
    required this.orderItems,
    required this.maPhieuMuon,
    required this.totalPrice,
    required this.ngayHenTra,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat("#,##0", "vi_VN");
    final dateFormat = DateFormat('dd/MM/yyyy');
    final dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text("Hoàn Tất"),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 5))
                ],
              ),
              child: Column(
                children: [
                  // --- 1. ĐỔI ICON VÀ THÔNG BÁO ---
                  const Icon(Icons.assignment_turned_in, color: Colors.orange, size: 60),
                  const SizedBox(height: 10),
                  const Text(
                      "GỬI YÊU CẦU THÀNH CÔNG!",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "(Vui lòng chờ thủ thư phê duyệt)",
                    style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                  ),

                  const SizedBox(height: 20),
                  const Divider(thickness: 2),

                  const Text("PHIẾU YÊU CẦU MƯỢN", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),

                  _buildRow("Mã phiếu:", "#$maPhieuMuon", isBold: true),
                  _buildRow("Ngày lập:", dateTimeFormat.format(DateTime.now())),
                  _buildRow("Hẹn trả:", dateFormat.format(ngayHenTra)),
                  // --- 2. THÊM TRẠNG THÁI ---
                  _buildRow("Trạng thái:", "Chờ duyệt", isColor: true, customColor: Colors.orange),
                  _buildRow("Người mượn:", user.hoVaTen),

                  const SizedBox(height: 15),
                  Row(
                    children: List.generate(
                      150 ~/ 3, // Số lượng dấu gạch ngang (tùy chỉnh độ dày đặc)
                          (index) => Expanded(
                        child: Container(
                          color: index % 2 == 0 ? Colors.transparent : Colors.grey, // Tạo khoảng trống xen kẽ
                          height: 1, // Độ dày của nét đứt
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Bảng sách
                  Row(
                    children: const [
                      Expanded(flex: 5, child: Text("Tên sách", style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 1, child: Text("SL", style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                      Expanded(flex: 3, child: Text("Đơn giá", style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                    ],
                  ),
                  const SizedBox(height: 8),

                  ...orderItems.values.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 5, child: Text(item.sach.tensach, style: const TextStyle(fontSize: 13))),
                          Expanded(flex: 1, child: Text("x${item.quantity}", textAlign: TextAlign.center, style: const TextStyle(fontSize: 13))),
                          Expanded(flex: 3, child: Text(currencyFormat.format(item.sach.giamuon), textAlign: TextAlign.right, style: const TextStyle(fontSize: 13))),
                        ],
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 15),
                  const Divider(thickness: 1),

                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Tổng số lượng:", style: TextStyle(fontSize: 15)),
                      Text("${orderItems.length} loại", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Tổng giá trị:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("${currencyFormat.format(totalPrice)} đ", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- 3. LỜI NHẮN ---
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: Colors.orange.withOpacity(0.3))
                    ),
                    child: const Text(
                      "Lưu ý: Bạn hãy đến thư viện và đọc mã phiếu này cho thủ thư để nhận sách.",
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text("QUAY VỀ TRANG CHỦ", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false, bool isColor = false, Color customColor = Colors.red}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          Text(value, style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
              color: isColor ? customColor : Colors.black
          )),
        ],
      ),
    );
  }
}