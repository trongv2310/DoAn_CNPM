import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../providers/api_service.dart';

class AdminReportsScreen extends StatelessWidget {
  final ApiService _api = ApiService();

  AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Báo cáo tổng hợp"),
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("HOẠT ĐỘNG THƯ VIỆN (THÁNG NÀY)"),
            FutureBuilder<Map<String, dynamic>>(
              future: _api.getLibrarianReport(),
              builder: (ctx, snapshot) {
                if (!snapshot.hasData) return const LinearProgressIndicator();
                final data = snapshot.data!;
                return Row(
                  children: [
                    _buildStatCard("Lượt mượn", "${data['luotMuon'] ?? 0}", Colors.blue),
                    _buildStatCard("Lượt trả", "${data['luotTra'] ?? 0}", Colors.green),
                    _buildStatCard("Đang quá hạn", "${data['dangQuaHan'] ?? 0}", Colors.red),
                  ],
                );
              },
            ),
            const SizedBox(height: 30),
            _buildSectionTitle("TÀI CHÍNH KHO (NĂM NAY)"),
            FutureBuilder<Map<String, dynamic>>(
              future: _api.getStorekeeperReport(),
              builder: (ctx, snapshot) {
                if (!snapshot.hasData) return const LinearProgressIndicator();
                final data = snapshot.data!;
                final chi = data['tongChiNhapSach'] ?? 0;
                final thu = data['tongThuThanhLy'] ?? 0;
                final loiNhuan = data['loiNhuan'] ?? 0;
                final currency = NumberFormat("#,##0", "vi_VN");

                return Column(
                  children: [
                    Card(
                      elevation: 4,
                      child: ListTile(
                        leading: const CircleAvatar(
                            backgroundColor: Colors.orange,
                            child: Icon(Icons.shopping_cart, color: Colors.white)),
                        title: const Text("Tổng chi nhập sách"),
                        trailing: Text("${currency.format(chi)} đ",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    Card(
                      elevation: 4,
                      child: ListTile(
                        leading: const CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Icon(Icons.monetization_on, color: Colors.white)),
                        title: const Text("Tổng thu thanh lý"),
                        trailing: Text("${currency.format(thu)} đ",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                          color: loiNhuan >= 0 ? Colors.green[50] : Colors.red[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: loiNhuan >= 0 ? Colors.green : Colors.red)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Cân đối thu chi:",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text("${currency.format(loiNhuan)} đ",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: loiNhuan >= 0 ? Colors.green : Colors.red)),
                        ],
                      ),
                    )
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title,
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700])),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        color: color,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 5),
              Text(label, style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}