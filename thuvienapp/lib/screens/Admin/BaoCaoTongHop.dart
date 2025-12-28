import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../providers/api_service.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Báo cáo tổng hợp"),
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.amberAccent,
            indicatorWeight: 3,
            tabs: [
              Tab(icon: Icon(Icons.bar_chart), text: "Hoạt động (Thủ thư)"),
              Tab(icon: Icon(Icons.attach_money), text: "Thu/Chi (Thủ kho)"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // Tab 1: Thống kê hoạt động (Code cũ của Admin/Thủ thư)
            LibrarianStatsTab(),
            // Tab 2: Báo cáo thu chi (Code của Thủ kho)
            StorekeeperStatsTab(),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// TAB 1: THỐNG KÊ HOẠT ĐỘNG (Của Thủ Thư)
// ==========================================
class LibrarianStatsTab extends StatefulWidget {
  const LibrarianStatsTab({super.key});

  @override
  State<LibrarianStatsTab> createState() => _LibrarianStatsTabState();
}

class _LibrarianStatsTabState extends State<LibrarianStatsTab> with AutomaticKeepAliveClientMixin {
  final ApiService _api = ApiService();
  late Future<List<dynamic>> _futureCategory;
  late Future<List<dynamic>> _futureMonthly;
  late Future<List<dynamic>> _futureTopBooks;
  late Future<List<dynamic>> _futureTopReaders;

  @override
  bool get wantKeepAlive => true; // Giữ trạng thái khi chuyển tab

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    _futureCategory = _api.fetchList("/Admin/stats-category");
    _futureMonthly = _api.fetchList("/Admin/stats-monthly-borrows");
    _futureTopBooks = _api.fetchList("/Admin/stats-top-books");
    _futureTopReaders = _api.fetchList("/Admin/stats-top-readers");
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _fetchData();
        });
      },
      child: SingleChildScrollView(
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

  Widget _buildPieChart() {
    return FutureBuilder<List<dynamic>>(
      future: _futureCategory,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final data = snapshot.data!;
        if (data.isEmpty) return const Center(child: Text("Chưa có dữ liệu"));

        return PieChart(
          PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 40,
            pieTouchData: PieTouchData(enabled: true),
            sections: data.map((item) {
              final double val = (item['phanTram'] as num).toDouble();
              final String title = item['theLoai'];

              return PieChartSectionData(
                color: Colors.primaries[data.indexOf(item) % Colors.primaries.length],
                value: val,
                title: '$title\n${val.toStringAsFixed(1)}%',
                radius: 60,
                titlePositionPercentageOffset: 1.4,
                titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
              );
            }).toList(),
          ),
          swapAnimationDuration: const Duration(milliseconds: 150),
        );
      },
    );
  }

  Widget _buildBarChart() {
    return FutureBuilder<List<dynamic>>(
      future: _futureMonthly,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final data = snapshot.data!;
        if (data.isEmpty) return const Center(child: Text("Chưa có dữ liệu"));

        double maxY = 0;
        if (data.isNotEmpty) {
          maxY = (data.map((e) => e['luotMuon'] as int).reduce((a, b) => a > b ? a : b) + 5).toDouble();
        }

        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY,
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

  Widget _buildTopBooksList() {
    return FutureBuilder<List<dynamic>>(
      future: _futureTopBooks,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.isEmpty) return const Text("Chưa có dữ liệu");
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

  Widget _buildTopReadersList() {
    return FutureBuilder<List<dynamic>>(
      future: _futureTopReaders,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.isEmpty) return const Text("Chưa có dữ liệu");
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

// ==========================================
// TAB 2: BÁO CÁO THU CHI (Của Thủ Kho)
// ==========================================
// ==========================================
// TAB 2: BÁO CÁO THU CHI (Của Thủ Kho) - ĐÃ SỬA LỖI HIỂN THỊ
// ==========================================
class StorekeeperStatsTab extends StatefulWidget {
  const StorekeeperStatsTab({super.key});

  @override
  State<StorekeeperStatsTab> createState() => _StorekeeperStatsTabState();
}

class _StorekeeperStatsTabState extends State<StorekeeperStatsTab> with AutomaticKeepAliveClientMixin {
  final ApiService _api = ApiService();
  int _selectedYear = DateTime.now().year;

  // Chỉ cần gọi 1 API lấy dữ liệu tháng, các số liệu tổng sẽ được tính từ đây để đảm bảo chính xác
  late Future<List<dynamic>> _futureMonthlyData;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    // Lấy dữ liệu chi tiết các tháng trong năm đã chọn
    _futureMonthlyData = _api.fetchBaoCaoTaiChinh(_selectedYear);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _loadData();
        });
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header: Tổng quan năm (Đã sửa logic tính toán) ---
            _buildSummaryCard(),
            const SizedBox(height: 24),

            // --- Biểu đồ cột Thu/Chi theo tháng ---
            _buildSectionTitle("Biểu đồ Thu/Chi theo tháng ($_selectedYear)"),
            SizedBox(height: 300, child: _buildBarChart()),
            const SizedBox(height: 24),

            // --- Biểu đồ tròn: Tỷ lệ Thu/Chi ---
            _buildSectionTitle("Tỷ lệ Thu/Chi năm $_selectedYear"),
            SizedBox(height: 250, child: _buildPieChart()),
            const SizedBox(height: 24),

            // --- Chi tiết từng tháng ---
            _buildSectionTitle("Chi tiết từng tháng"),
            _buildMonthlyDetails(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
      ),
    );
  }

  // --- SỬA LỖI: Tính tổng trực tiếp từ list tháng ---
  Widget _buildSummaryCard() {
    return FutureBuilder<List<dynamic>>(
      future: _futureMonthlyData, // Sử dụng dữ liệu tháng thay vì _futureTotalReport
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final list = snapshot.data ?? [];

        // Tính toán thủ công để đảm bảo số liệu khớp với bảng chi tiết
        double tongThu = 0;
        double tongChi = 0;

        for (var item in list) {
          tongThu += (item['tongThu'] ?? 0).toDouble();
          tongChi += (item['tongChi'] ?? 0).toDouble();
        }

        final double loiNhuan = tongThu - tongChi;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade700, Colors.teal.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.teal.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Tổng quan năm $_selectedYear",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn("Tổng Thu", tongThu, Colors.greenAccent),
                  _buildStatColumn("Tổng Chi", tongChi, Colors.redAccent),
                  _buildStatColumn(
                    "Lợi nhuận",
                    loiNhuan,
                    loiNhuan >= 0 ? Colors.lightGreenAccent : Colors.white,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatColumn(String label, double value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          _formatCurrency(value),
          style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // --- Biểu đồ cột (Giữ nguyên logic hiển thị) ---
  Widget _buildBarChart() {
    return FutureBuilder<List<dynamic>>(
      future: _futureMonthlyData,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Không có dữ liệu"));
        }
        final data = snapshot.data!;

        double maxVal = 0;
        for (var item in data) {
          double thu = (item['tongThu'] ?? 0).toDouble();
          double chi = (item['tongChi'] ?? 0).toDouble();
          if (thu > maxVal) maxVal = thu;
          if (chi > maxVal) maxVal = chi;
        }
        maxVal = maxVal > 0 ? maxVal * 1.2 : 1000000;

        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxVal,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  String label = rodIndex == 0 ? "Thu" : "Chi";
                  return BarTooltipItem(
                    "$label: ${_formatCurrency(rod.toY)}",
                    const TextStyle(color: Colors.white, fontSize: 12),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text("T${value.toInt()}", style: const TextStyle(fontSize: 10)),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    return Text(_formatShortCurrency(value), style: const TextStyle(fontSize: 9));
                  },
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            barGroups: data.map((item) {
              int thang = item['thang'];
              double thu = (item['tongThu'] ?? 0).toDouble();
              double chi = (item['tongChi'] ?? 0).toDouble();

              return BarChartGroupData(
                x: thang,
                barRods: [
                  BarChartRodData(toY: thu, color: Colors.green, width: 12),
                  BarChartRodData(toY: chi, color: Colors.red, width: 12),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // --- Biểu đồ tròn (Cũng sửa để dùng dữ liệu cộng dồn) ---
  Widget _buildPieChart() {
    return FutureBuilder<List<dynamic>>(
      future: _futureMonthlyData,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        // Tính toán lại tổng từ dữ liệu tháng
        final list = snapshot.data ?? [];
        double tongThu = 0;
        double tongChi = 0;
        for (var item in list) {
          tongThu += (item['tongThu'] ?? 0).toDouble();
          tongChi += (item['tongChi'] ?? 0).toDouble();
        }

        final double total = tongChi + tongThu;

        if (total == 0) {
          return const Center(child: Text("Chưa có dữ liệu tài chính"));
        }

        double phanTramThu = (tongThu / total) * 100;
        double phanTramChi = (tongChi / total) * 100;

        return Row(
          children: [
            Expanded(
              flex: 2,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  pieTouchData: PieTouchData(enabled: true),
                  sections: [
                    PieChartSectionData(
                      color: Colors.green,
                      value: tongThu,
                      title: 'Thu\n${phanTramThu.toStringAsFixed(1)}%',
                      radius: 60,
                      titlePositionPercentageOffset: 1.4,
                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    PieChartSectionData(
                      color: Colors.red,
                      value: tongChi,
                      title: 'Chi\n${phanTramChi.toStringAsFixed(1)}%',
                      radius: 60,
                      titlePositionPercentageOffset: 1.4,
                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLegendItem(Colors.green, "Thu (Thanh lý)"),
                  const SizedBox(height: 10),
                  _buildLegendItem(Colors.red, "Chi (Nhập hàng)"),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 16, height: 16, color: color),
        const SizedBox(width: 8),
        Flexible(child: Text(label, style: const TextStyle(fontSize: 12))),
      ],
    );
  }

  Widget _buildMonthlyDetails() {
    return FutureBuilder<List<dynamic>>(
      future: _futureMonthlyData,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Không có dữ liệu chi tiết"));
        }

        final list = snapshot.data!;
        // Sắp xếp tháng giảm dần (tháng mới nhất lên đầu)
        list.sort((a, b) => (b['thang'] as int).compareTo(a['thang'] as int));

        return Column(
          children: list.map((item) {
            final double thu = (item['tongThu'] ?? 0).toDouble();
            final double chi = (item['tongChi'] ?? 0).toDouble();
            // Tự tính lợi nhuận tháng để đồng bộ
            final double loiNhuan = thu - chi;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Tháng ${item['thang']}",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: loiNhuan >= 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            loiNhuan >= 0 ? "+${_formatCurrency(loiNhuan)}" : _formatCurrency(loiNhuan),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: loiNhuan >= 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    _buildDetailRow("Thu (Thanh lý):", thu, Colors.green),
                    const SizedBox(height: 6),
                    _buildDetailRow("Chi (Nhập hàng):", chi, Colors.red),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, double value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Text(_formatCurrency(value), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }

  String _formatCurrency(double value) {
    if (value.abs() >= 1000000000) {
      return "${(value / 1000000000).toStringAsFixed(1)} tỷ";
    } else if (value.abs() >= 1000000) {
      return "${(value / 1000000).toStringAsFixed(1)} tr";
    } else if (value.abs() >= 1000) {
      return "${(value / 1000).toStringAsFixed(0)} k";
    }
    return "${value.toStringAsFixed(0)} đ";
  }

  String _formatShortCurrency(double value) {
    if (value.abs() >= 1000000) {
      return "${(value / 1000000).toStringAsFixed(0)}M";
    } else if (value.abs() >= 1000) {
      return "${(value / 1000).toStringAsFixed(0)}K";
    }
    return value.toStringAsFixed(0);
  }
}