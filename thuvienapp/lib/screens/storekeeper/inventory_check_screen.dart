import 'package:flutter/material.dart';
import '../../models/sach.dart';
import '../../providers/api_service.dart';

class InventoryCheckScreen extends StatefulWidget {
  const InventoryCheckScreen({Key? key}) : super(key: key);

  @override
  _InventoryCheckScreenState createState() => _InventoryCheckScreenState();
}

class _InventoryCheckScreenState extends State<InventoryCheckScreen> {
  final ApiService _apiService = ApiService();
  List<Sach> _allBooks = []; // Danh sách gốc
  List<Sach> _filteredBooks = []; // Danh sách hiển thị (sau khi search)
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  // Hàm tải dữ liệu sách từ Server
  Future<void> _loadBooks() async {
    setState(() => _isLoading = true);
    try {
      var books = await _apiService.fetchSaches();
      setState(() {
        _allBooks = books;
        _filteredBooks = books; // Ban đầu hiển thị tất cả
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print("Lỗi tải sách: $e");
    }
  }

  // Hàm lọc sách theo tên
  void _filterBooks(String query) {
    final filtered = _allBooks.where((book) {
      final nameLower = book.tensach.toLowerCase();
      final queryLower = query.toLowerCase();
      return nameLower.contains(queryLower);
    }).toList();

    setState(() {
      _filteredBooks = filtered;
    });
  }

  // Hàm xác định màu sắc dựa trên số lượng tồn
  Color _getStockColor(int stock) {
    if (stock == 0) return Colors.red; // Hết hàng
    if (stock < 5) return Colors.orange; // Sắp hết
    return Colors.green; // An toàn
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kiểm Kê Kho Sách"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 1. Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterBooks,
              decoration: InputDecoration(
                hintText: "Tìm tên sách...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),

          // 2. Danh sách sách
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
              onRefresh: _loadBooks, // Kéo xuống để load lại
              child: _filteredBooks.isEmpty
                  ? const Center(child: Text("Không tìm thấy sách nào"))
                  : ListView.builder(
                itemCount: _filteredBooks.length,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemBuilder: (context, index) {
                  final book = _filteredBooks[index];
                  final stockColor = _getStockColor(book.soluongton);

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          // Ảnh bìa sách
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 60,
                              height: 80,
                              color: Colors.grey[200],
                              child: book.hinhanh != null && book.hinhanh!.isNotEmpty
                                  ? Image.network(
                                book.hinhanh!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: Colors.grey),
                              )
                                  : const Icon(Icons.book, color: Colors.grey),
                            ),
                          ),
                          const SizedBox(width: 15),

                          // Thông tin tên và giá
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  book.tensach,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 5),
                                Text("Mã sách: ${book.masach}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                Text("${book.giamuon.toStringAsFixed(0)} đ", style: const TextStyle(color: Colors.blueGrey)),
                              ],
                            ),
                          ),

                          // Số lượng tồn kho (Nổi bật)
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: stockColor.withOpacity(0.1),
                                  border: Border.all(color: stockColor, width: 2),
                                ),
                                child: Text(
                                  "${book.soluongton}",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: stockColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                book.soluongton == 0 ? "Hết hàng" : "Tồn kho",
                                style: TextStyle(fontSize: 10, color: stockColor, fontWeight: FontWeight.bold),
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
          ),
        ],
      ),
    );
  }
}