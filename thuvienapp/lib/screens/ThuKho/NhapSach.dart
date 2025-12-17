import 'package:flutter/material.dart';
import '../../models/sach.dart';
import '../../models/user.dart';
import '../../providers/api_service.dart';

class ImportGoodsScreen extends StatefulWidget {
  final User user;
  const ImportGoodsScreen({Key? key, required this.user}) : super(key: key);

  @override
  _ImportGoodsScreenState createState() => _ImportGoodsScreenState();
}

class _ImportGoodsScreenState extends State<ImportGoodsScreen> {
  final ApiService _apiService = ApiService();
  List<Sach> _allBooks = [];
  Sach? _selectedBook;
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  // Danh sách các sách đã thêm vào phiếu tạm
  List<Map<String, dynamic>> _cart = [];

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  void _loadBooks() async {
    var books = await _apiService.fetchSaches();
    setState(() {
      _allBooks = books;
    });
  }

  void _addToCart() {
    if (_selectedBook == null || _qtyController.text.isEmpty || _priceController.text.isEmpty) return;

    setState(() {
      _cart.add({
        "MaSach": _selectedBook!.masach,
        "TenSach": _selectedBook!.tensach,
        "SoLuong": int.parse(_qtyController.text),
        "GiaNhap": double.parse(_priceController.text),
      });
    });

    // Reset form
    _qtyController.clear();
    _priceController.clear();
    Navigator.pop(context); // Đóng dialog
  }

  void _submitImport() async {
    if (_cart.isEmpty) return;

    bool success = await _apiService.nhapHang(widget.user.entityId, _cart);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Nhập hàng thành công!")));
      setState(() {
        _cart.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Nhập hàng thất bại!")));
    }
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Thêm sách vào phiếu"),
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
                  child: Text(book.tensach, overflow: TextOverflow.ellipsis),
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
              decoration: InputDecoration(labelText: "Giá nhập"),
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
      appBar: AppBar(title: Text("Tạo phiếu nhập"), backgroundColor: Colors.orange),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _cart.length,
              itemBuilder: (context, index) {
                final item = _cart[index];
                return ListTile(
                  title: Text(item['TenSach']),
                  subtitle: Text("SL: ${item['SoLuong']} - Giá: ${item['GiaNhap']}"),
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: _cart.isEmpty ? null : _submitImport,
                child: Text("LƯU PHIẾU NHẬP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: _showAddDialog,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}