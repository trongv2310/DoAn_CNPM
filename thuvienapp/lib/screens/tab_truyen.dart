import 'package:flutter/material.dart';
import '../models/sach.dart';
import '../providers/api_service.dart';

class TabTruyen extends StatefulWidget {
  @override
  _TabTruyenState createState() => _TabTruyenState();
}

class _TabTruyenState extends State<TabTruyen> {
  final ApiService apiService = ApiService();
  late Future<List<Sach>> futureSach;

  @override
  void initState() {
    super.initState();
    futureSach = apiService.fetchSaches();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phần Header giả lập (Banner, tìm kiếm...)
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Container(
                  height: 40,
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Tìm kiếm truyện...",
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      contentPadding: EdgeInsets.only(bottom: 10),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Container(
                  height: 120,
                  decoration: BoxDecoration(color: Colors.blue[100], borderRadius: BorderRadius.circular(10)),
                  child: Center(child: Text("BANNER QUẢNG CÁO", style: TextStyle(color: Colors.blue))),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text("TRUYỆN MỚI CẬP NHẬT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Expanded(
            child: FutureBuilder<List<Sach>>(
              future: futureSach,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text("Chưa có sách nào"));

                return GridView.builder(
                  padding: EdgeInsets.all(10),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, childAspectRatio: 0.7, crossAxisSpacing: 10, mainAxisSpacing: 10),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final s = snapshot.data![index];
                    return Card(
                      elevation: 2,
                      child: Column(
                        children: [
                          Expanded(child: Container(color: Colors.grey[300], child: Icon(Icons.book, size: 40))),
                          Padding(padding: EdgeInsets.all(5), child: Text(s.tensach, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                          Text("${s.giamuon.toInt()} đ", style: TextStyle(color: Colors.red, fontSize: 10)),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}