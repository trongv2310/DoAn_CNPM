import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../providers/api_service.dart';

class NhatKyHeThong extends StatelessWidget {
  const NhatKyHeThong({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Nhật ký hệ thống"),
          backgroundColor: Colors.blueGrey,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.login), text: "Đăng nhập"),
              Tab(icon: Icon(Icons.sync_alt), text: "Giao dịch"),
              Tab(icon: Icon(Icons.warning), text: "Vi phạm"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            LogList(type: 'system'),
            LogList(type: 'transaction'),
            LogList(type: 'violation'),
          ],
        ),
      ),
    );
  }
}

class LogList extends StatefulWidget {
  final String type;
  const LogList({super.key, required this.type});

  @override
  _LogListState createState() => _LogListState();
}

// Thêm Mixin này để giữ trạng thái Tab không bị load lại khi chuyển tab
class _LogListState extends State<LogList> with AutomaticKeepAliveClientMixin {
  final ApiService _api = ApiService();
  late Future<List<dynamic>> _dataFuture;

  @override
  bool get wantKeepAlive => true; // Giữ tab sống

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      if (widget.type == 'system') {
        _dataFuture = _api.getSystemLogs();
      } else if (widget.type == 'transaction') {
        _dataFuture = _api.getTransactionLogs();
      } else {
        _dataFuture = _api.getViolationLogs();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Cần thiết cho Mixin
    return FutureBuilder<List<dynamic>>(
      future: _dataFuture,
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Lỗi kết nối: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Không có dữ liệu log.", style: TextStyle(color: Colors.grey)));
        }

        final logs = snapshot.data!;

        // Bọc trong RefreshIndicator để kéo xuống làm mới dữ liệu
        return RefreshIndicator(
          onRefresh: () async {
            _loadData();
            await _dataFuture;
          },
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(), // Để kéo refresh được ngay cả khi list ngắn
            itemCount: logs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final item = logs[i];

              if (widget.type == 'system') {
                // SỬA LỖI: Kiểm tra key cẩn thận. Backend trả về 'hanhdong' (thường) hoặc 'Hanhdong' (hoa)
                // Dùng ?? để fallback nếu key null
                final hanhDong = item['hanhdong'] ?? item['hanhDong'] ?? item['Hanhdong'] ?? 'Không rõ hành động';
                final tenTaiKhoan = item['tenTaiKhoan'] ?? item['TenTaiKhoan'] ?? 'Unknown';

                return ListTile(
                  leading: const Icon(Icons.person, color: Colors.blue),
                  title: Text(tenTaiKhoan, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(hanhDong),
                  // Parse giờ từ chuỗi "dd/MM/yyyy HH:mm:ss"
                  trailing: Text(
                      _parseTime(item['thoiGian']),
                      style: const TextStyle(fontSize: 12, color: Colors.grey)
                  ),
                );
              } else if (widget.type == 'transaction') {
                String dateStr = _formatDate(item['ngay']);
                return ListTile(
                  leading: _getIcon(item['loai'] ?? ""),
                  title: Text("${item['loai']} #${item['maPhieu']}", style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(item['chiTiet'] ?? ''),
                  trailing: Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                );
              } else {
                // Violation
                final money = NumberFormat("#,##0", "vi_VN").format(item['tienPhat'] ?? 0);
                return ListTile(
                  leading: const Icon(Icons.money_off, color: Colors.red),
                  title: Text(item['tenSinhVien'] ?? "Sinh viên", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Quá hạn: ${item['soNgayQuaHan']} ngày"),
                  trailing: Text("$money đ",
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                );
              }
            },
          ),
        );
      },
    );
  }

  // Hàm helper xử lý ngày tháng an toàn hơn
  String _formatDate(String? isoDate) {
    if (isoDate == null) return "";
    try {
      DateTime dt = DateTime.parse(isoDate);
      return DateFormat('dd/MM').format(dt);
    } catch (e) {
      return "";
    }
  }

  // Hàm helper lấy giờ từ chuỗi backend gửi về (dd/MM/yyyy HH:mm:ss)
  String _parseTime(String? dateTimeStr) {
    if (dateTimeStr == null) return "";
    try {
      // Backend trả về: "23/11/2025 10:30:00" -> Lấy phần giờ "10:30:00"
      var parts = dateTimeStr.split(' ');
      if (parts.length > 1) return parts[1];
      return dateTimeStr;
    } catch (e) {
      return "";
    }
  }

  Icon _getIcon(String type) {
    if (type.contains("Mượn")) return const Icon(Icons.book, color: Colors.blue);
    if (type.contains("Trả")) return const Icon(Icons.assignment_turned_in, color: Colors.green);
    if (type.contains("Nhập")) return const Icon(Icons.input, color: Colors.orange);
    return const Icon(Icons.info, color: Colors.grey);
  }
}