import 'package:flutter/material.dart';
import '../../providers/api_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final ApiService _apiService = ApiService();
  int _selectedYear = DateTime.now().year;
  late Future<List<dynamic>> _reportFuture;

  @override
  void initState() {
    super.initState();
    _reportFuture = _apiService.fetchBaoCaoTaiChinh(_selectedYear);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Báo cáo tài chính"), backgroundColor: Colors.teal, foregroundColor: Colors.white),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("Năm tài chính: $_selectedYear", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _reportFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text("Không có dữ liệu phát sinh trong năm nay"));

                final list = snapshot.data!;
                return ListView.builder(
                  padding: EdgeInsets.all(10),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    final double thu = double.parse(item['tongThu'].toString());
                    final double chi = double.parse(item['tongChi'].toString());
                    final double loiNhuan = double.parse(item['loiNhuan'].toString());

                    return Card(
                      margin: EdgeInsets.only(bottom: 15),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Tháng ${item['thang']}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                                Text(loiNhuan >= 0 ? "+${loiNhuan.toStringAsFixed(0)} đ" : "${loiNhuan.toStringAsFixed(0)} đ",
                                    style: TextStyle(fontWeight: FontWeight.bold, color: loiNhuan >= 0 ? Colors.green : Colors.red)),
                              ],
                            ),
                            Divider(),
                            _buildRow("Tổng Thu (Thanh lý):", thu, Colors.green),
                            SizedBox(height: 5),
                            _buildRow("Tổng Chi (Nhập hàng):", chi, Colors.redAccent),
                          ],
                        ),
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

  Widget _buildRow(String label, double value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text("${value.toStringAsFixed(0)} đ", style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }
}