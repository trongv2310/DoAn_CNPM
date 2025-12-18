import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../providers/api_service.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final ApiService _api = ApiService();
  late Future<List<dynamic>> _futureCategory;
  late Future<List<dynamic>> _futureMonthly;
  late Future<List<dynamic>> _futureTopBooks;
  late Future<List<dynamic>> _futureTopReaders;

  @override
  void initState() {
    super.initState();
    // Bạn cần bổ sung các hàm gọi API này vào ApiService.dart tương ứng với backend
    _futureCategory = _api.fetchList("/Admin/stats-category");
    _futureMonthly = _api.fetchList("/Admin/stats-monthly-borrows");
    _futureTopBooks = _api.fetchList("/Admin/stats-top-books");
    _futureTopReaders = _api.fetchList("/Admin/stats-top-readers");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Thống kê chi tiết"), backgroundColor: Colors.purple, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("Phân bổ thể loại sách (%)"),
            SizedBox(height: 250, child: _buildPieChart()),
            const SizedBox(height: 30),

            _buildSectionTitle("Lượt mượn theo tháng (Năm nay)"),
            SizedBox(height: 300, child: _buildBarChart()),
            const SizedBox(height: 30),

            _buildSectionTitle("Top 5 Sách mượn nhiều nhất"),
            _buildTopBooksList(),
            const SizedBox(height: 30),

            _buildSectionTitle("Top 5 Độc giả tích cực"),
            _buildTopReadersList(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
    );
  }

  // --- Biểu đồ tròn ---
  Widget _buildPieChart() {
    return FutureBuilder<List<dynamic>>(
      future: _futureCategory,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final data = snapshot.data!;

        return PieChart(
          PieChartData(
            sectionsSpace: 2, // Khoảng cách giữa các miếng
            centerSpaceRadius: 40, // Bán kính vòng tròn rỗng ở giữa
            pieTouchData: PieTouchData(enabled: true),
            // Tăng kích thước bao quanh để chữ không bị cắt khi đẩy ra ngoài
            sections: data.map((item) {
              final double val = (item['phanTram'] as num).toDouble();
              final String title = item['theLoai'];

              return PieChartSectionData(
                color: Colors.primaries[data.indexOf(item) % Colors.primaries.length],
                value: val,
                // Hiển thị Tên thể loại + %
                title: '$title\n${val.toStringAsFixed(1)}%',
                radius: 60, // Bán kính của miếng biểu đồ

                // --- QUAN TRỌNG: Đẩy chữ ra ngoài ---
                titlePositionPercentageOffset: 1.4, // 1.4 nghĩa là nằm ngoài bán kính 140%

                // Style chữ khi nằm ngoài (nên để màu đen cho dễ đọc trên nền trắng)
                titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87
                ),
              );
            }).toList(),
          ),
          swapAnimationDuration: const Duration(milliseconds: 150), // Animation mượt
        );
      },
    );
  }

  // --- Biểu đồ cột ---
  Widget _buildBarChart() {
    return FutureBuilder<List<dynamic>>(
      future: _futureMonthly,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final data = snapshot.data!;

        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: (data.map((e) => e['luotMuon'] as int).reduce((a, b) => a > b ? a : b) + 5).toDouble(),
            barTouchData: BarTouchData(enabled: true),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    return Text("T${value.toInt()}", style: const TextStyle(fontSize: 10));
                  },
                ),
              ),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            barGroups: data.map((item) {
              return BarChartGroupData(
                x: item['thang'],
                barRods: [
                  BarChartRodData(toY: (item['luotMuon'] as int).toDouble(), color: Colors.blue, width: 16)
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // --- List Top Sách ---
  Widget _buildTopBooksList() {
    return FutureBuilder<List<dynamic>>(
      future: _futureTopBooks,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        return Column(
          children: snapshot.data!.map((book) => Card(
            child: ListTile(
              leading: Image.network(ApiService.getImageUrl(book['hinhAnh']), width: 40, fit: BoxFit.cover, errorBuilder: (_,__,___)=>const Icon(Icons.book)),
              title: Text(book['tenSach'], maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Chip(label: Text("${book['luotMuon']} lượt"), backgroundColor: Colors.amberAccent),
            ),
          )).toList(),
        );
      },
    );
  }

  // --- List Top Độc Giả ---
  Widget _buildTopReadersList() {
    return FutureBuilder<List<dynamic>>(
      future: _futureTopReaders,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        return Column(
          children: snapshot.data!.map((user) => Card(
            child: ListTile(
              leading: CircleAvatar(child: Text(user['hoTen'][0])),
              title: Text(user['hoTen']),
              subtitle: Text("MSSV: ${user['maSV']}"),
              trailing: Text("${user['soLanMuon']} lần mượn", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            ),
          )).toList(),
        );
      },
    );
  }
}