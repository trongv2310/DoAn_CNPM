import 'package:flutter/material.dart';
import '../../providers/api_service.dart';
import '../../models/user.dart';

class ApproveExtensionScreen extends StatefulWidget {
  final User user;
  const ApproveExtensionScreen({super.key, required this.user});

  @override
  _ApproveExtensionScreenState createState() => _ApproveExtensionScreenState();
}

class _ApproveExtensionScreenState extends State<ApproveExtensionScreen> {
  final ApiService _api = ApiService();
  late Future<List<dynamic>> _listFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _listFuture = _api.getExtensionRequests();
    });
  }

  void _process(int maPhieu, int maSach, bool dongY) async {
    // Hiển thị loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    bool success = await _api.processExtension(maPhieu, maSach, dongY);

    if (!mounted) return;
    Navigator.pop(context); // Tắt loading

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(dongY ? "Đã DUYỆT gia hạn!" : "Đã TỪ CHỐI gia hạn!"),
          backgroundColor: dongY ? Colors.green : Colors.red,
        ),
      );
      _refresh(); // Tải lại danh sách
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lỗi xử lý, vui lòng thử lại."), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Duyệt Gia Hạn Sách"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _listFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          }

          final list = snapshot.data ?? [];

          if (list.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 60, color: Colors.green),
                  SizedBox(height: 10),
                  Text("Không có yêu cầu gia hạn nào.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              return _buildRequestCard(item);
            },
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(dynamic item) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item['tenSinhVien'] ?? "Sinh viên",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(4)),
                  child: Text("Lần thứ ${(item['soLanDaGiaHan'] ?? 0) + 1}", style: const TextStyle(color: Colors.orange, fontSize: 12)),
                )
              ],
            ),
            const Divider(),
            _buildInfoRow("Sách:", item['tenSach']),
            _buildInfoRow("Hạn cũ:", _formatDate(item['hanTraCu'])),
            _buildInfoRow("Muốn gia hạn đến:", _formatDate(item['hanTraMoi']), isHighlight: true),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _process(item['maPhieu'], item['maSach'], false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text("Từ Chối"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _process(item['maPhieu'], item['maSach'], true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Đồng Ý"),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                  fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                  color: isHighlight ? Colors.blue[800] : Colors.black
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return "";
    try {
      // Giả sử server trả về yyyy-MM-dd
      final parts = isoDate.split('T')[0].split('-');
      if (parts.length == 3) return "${parts[2]}/${parts[1]}/${parts[0]}";
      return isoDate;
    } catch (e) {
      return isoDate;
    }
  }
}