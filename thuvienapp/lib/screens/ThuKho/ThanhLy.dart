import 'package:flutter/material.dart';
import '../../models/sach.dart';
import '../../models/user.dart';
import '../../providers/api_service.dart';

class LiquidationScreen extends StatefulWidget {
  final User user;
  const LiquidationScreen({Key? key, required this.user}) : super(key: key);

  @override
  _LiquidationScreenState createState() => _LiquidationScreenState();
}

class _LiquidationScreenState extends State<LiquidationScreen> {
  final ApiService _apiService = ApiService();
  List<Sach> _allBooks = [];
  Sach? _selectedBook;
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  List<Map<String, dynamic>> _cart = [];

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  void _loadBooks() async {
    var books = await _apiService.fetchSaches();
    setState(() { _allBooks = books; });
  }

  void _addToCart() {
    if (_selectedBook == null || _qtyController.text.isEmpty || _priceController.text.isEmpty) return;
    // Logic thêm vào giỏ (giống nhập hàng)
    setState(() {
      _cart.add({
        "MaSach": _selectedBook!.masach,
        "TenSach": _selectedBook!.tensach,
        "SoLuong": int.parse(_qtyController.text),
        "DonGia": double.parse(_priceController.text), // Đổi key thành DonGia cho khớp DTO
      });
    });
    _qtyController.clear();
    _priceController.clear();
    Navigator.pop(context);
  }

  void _submitLiquidation() async {
    if (_cart.isEmpty) return;
    // GỌI HÀM THANH LÝ
    bool success = await _apiService.thanhLySach(widget.user.entityId, _cart);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Thanh lý thành công!")));
      setState(() { _cart.clear(); });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Thanh lý thất bại (Có thể do thiếu tồn kho)!")));
    }
  }

  void _showAddDialog() {
    // ... (Code UI Dialog giữ nguyên như ImportGoodsScreen)
    // Chỉ sửa Text title thành "Chọn sách thanh lý"
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Chọn sách thanh lý"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<Sach>(
              isExpanded: true,
              hint: Text("Chọn sách"),
              value: _selectedBook,
              items: _allBooks.map((Sach book) {
                return DropdownMenuItem<Sach>(
                  value: book,
                  // Hiển thị cả số lượng tồn để dễ chọn
                  child: Text("${book.tensach} (Tồn: ${book.soluongton})", overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedBook = val),
            ),
            TextField(
              controller: _qtyController,
              decoration: InputDecoration(labelText: "Số lượng"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _priceController,
              decoration: InputDecoration(labelText: "Giá thanh lý"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Hủy")),
          ElevatedButton(onPressed: _addToCart, child: Text("Thêm")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Thanh lý sách"), backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _cart.length,
              itemBuilder: (context, index) {
                final item = _cart[index];
                return ListTile(
                  title: Text(item['TenSach']),
                  subtitle: Text("SL: ${item['SoLuong']} - Giá: ${item['DonGia']}"),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => setState(() => _cart.removeAt(index)),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: _cart.isEmpty ? null : _submitLiquidation,
                child: Text("XÁC NHẬN THANH LÝ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.redAccent,
        onPressed: _showAddDialog,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}