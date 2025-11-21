import 'package:flutter/material.dart';
import '../models/sach.dart';

class BookListScreen extends StatelessWidget {
  final String title;
  final List<Sach> books;

  const BookListScreen({Key? key, required this.title, required this.books}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: books.isEmpty
          ? Center(child: Text("Không có sách nào"))
          : GridView.builder(
        padding: EdgeInsets.all(10),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: books.length,
        itemBuilder: (context, index) {
          final s = books[index];
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                    child: s.hinhanh != null
                        ? Image.network(s.hinhanh!, fit: BoxFit.cover, width: double.infinity,
                        errorBuilder: (_, __, ___) => Container(color: Colors.grey[300], child: Icon(Icons.broken_image)))
                        : Container(color: Colors.blue[100], child: Icon(Icons.book, size: 40)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.tensach, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(s.tenTacGia ?? "TG", style: TextStyle(fontSize: 11, color: Colors.grey)),
                      SizedBox(height: 4),
                      Text("${s.giamuon.toStringAsFixed(0)} đ", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}