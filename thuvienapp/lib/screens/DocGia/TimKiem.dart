import 'package:flutter/material.dart';
import 'dart:async'; // Để dùng Timer (Debounce)
import '../../models/sach.dart';
import '../../providers/api_service.dart';
import '../ChiTietSach.dart'; // Hoặc ChiTietSach.dart tùy tên file bạn

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();

  List<Sach> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounce; // Để tránh gọi API liên tục khi gõ

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Hàm xử lý khi người dùng gõ phím
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Đợi 500ms sau khi ngừng gõ mới gọi API
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        _performSearch(query);
      } else {
        setState(() {
          _searchResults = [];
        });
      }
    });
  }

  Future<void> _performSearch(String keyword) async {
    setState(() { _isLoading = true; });

    List<Sach> results = await _apiService.searchSaches(keyword);

    setState(() {
      _searchResults = results;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true, // Tự động bật bàn phím khi vào màn hình
          onChanged: _onSearchChanged,
          decoration: const InputDecoration(
            hintText: "Nhập tên sách...",
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey),
          ),
          style: const TextStyle(color: Colors.black, fontSize: 16),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.grey),
              onPressed: () {
                _searchController.clear();
                _onSearchChanged('');
              },
            )
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchController.text.isNotEmpty && _searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 10),
            const Text("Không tìm thấy kết quả nào.", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return const Center(child: Text("Nhập từ khóa để tìm kiếm sách", style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final sach = _searchResults[index];
        String imageUrl = ApiService.getImageUrl(sach.hinhanh);

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 40, height: 60,
                child: imageUrl.isNotEmpty
                    ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(color: Colors.grey))
                    : Container(color: Colors.blue[100], child: const Icon(Icons.book)),
              ),
            ),
            title: Text(sach.tensach, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text("${sach.giamuon.toInt()} đ"),
            onTap: () {
              // Chuyển sang màn hình chi tiết khi bấm vào kết quả
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BookDetailScreen(sach: sach)), // Sửa tên class nếu cần
              );
            },
          ),
        );
      },
    );
  }
}