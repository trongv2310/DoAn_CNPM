import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Cần import intl để format tiền
import '../models/user.dart';
import '../models/borrowed_book_history.dart';
import '../providers/api_service.dart';

class TabTuSach extends StatefulWidget {
  final User user;
  const TabTuSach({super.key, required this.user});

  @override
  _TabTuSachState createState() => _TabTuSachState();
}

class _TabTuSachState extends State<TabTuSach> {
  late Future<List<BorrowedBookHistory>> _futureHistory;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _futureHistory = _apiService.fetchLichSuMuon(widget.user.maTaiKhoan);
    });
  }

  Future<void> _handleRefresh() async {
    _loadData();
    await _futureHistory;
  }

  // --- HÀM XỬ LÝ TRẢ SÁCH ---
  void _handleTraSach(int maPhieu, int maSach) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận trả sách"),
        content: const Text("Bạn có chắc muốn trả cuốn sách này không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Đồng ý")),
        ],
      ),
    ) ?? false;

    if (confirm) {
      // Gọi API trả sách
      final result = await _apiService.traSach(maPhieu, maSach);

      // Kiểm tra kết quả trả về (Map)
      if (!mounted) return;
      if (result['success'] == true) {
        String msg = "Trả sách thành công!";
        // Nếu có tiền phạt trả về từ API thì hiển thị
        if (result['tienPhat'] != null && (result['tienPhat'] as num) > 0) {
          final tienPhat = NumberFormat("#,##0", "vi_VN").format(result['tienPhat']);
          msg += " Phạt: $tienPhat đ";
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
        _handleRefresh(); // Tải lại danh sách
      } else {
        String msg = result['message'] ?? "Lỗi khi trả sách";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
      }
    }
  }

  // --- HÀM XỬ LÝ GIA HẠN SÁCH ---
  void _handleGiaHan(BorrowedBookHistory item) async {
    DateTime currentDueDate;
    try {
      currentDueDate = DateTime.parse(item.hanTra);
    } catch (e) {
      currentDueDate = DateTime.now();
    }

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: currentDueDate.add(const Duration(days: 7)),
      firstDate: currentDueDate.add(const Duration(days: 1)),
      lastDate: currentDueDate.add(const Duration(days: 30)),
      helpText: "CHỌN NGÀY HẸN TRẢ MỚI",
      confirmText: "GIA HẠN",
      cancelText: "HỦY",
    );

    if (pickedDate != null) {
      final result = await _apiService.giaHanSach(item.maPhieu, item.maSach, pickedDate);

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message']), backgroundColor: Colors.green),
        );
        _handleRefresh();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? "Lỗi gia hạn"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- POPUP CHI TIẾT ---
  void _showTicketDetail(BuildContext context, BorrowedBookHistory item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long, size: 50, color: Colors.blue),
            const SizedBox(height: 10),
            const Text("CHI TIẾT PHIẾU MƯỢN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Divider(),
            const SizedBox(height: 10),
            _buildRowDetail("Mã phiếu:", "#${item.maPhieu}"),
            _buildRowDetail("Sách:", item.tenSach),
            _buildRowDetail("Ngày mượn:", _formatDate(item.ngayMuon)),
            _buildRowDetail("Hạn trả:", _formatDate(item.hanTra)),
            _buildRowDetail("Trạng thái:", item.trangThai, isStatus: true),

            if (item.tienPhat > 0)
              _buildRowDetail("Tiền phạt:", "${NumberFormat("#,##0").format(item.tienPhat)} đ", isRed: true),

            _buildRowDetail("Giá mượn:", "${item.giaMuon.toInt()} đ"),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Đóng"),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRowDetail(String label, String value, {bool isStatus = false, bool isRed = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isRed ? Colors.red : (isStatus ? _getStatusColor(value) : Colors.black)
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      DateTime date = DateTime.parse(isoDate);
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return isoDate;
    }
  }

  // Hàm helper để xác định màu dựa trên chuỗi trạng thái (xử lý cả chữ thường/hoa)
  Color _getStatusColor(String status) {
    String s = status.toLowerCase();
    if (s.contains("quá hạn")) return Colors.red;
    if (s.contains("đã trả")) return Colors.green;
    if (s.contains("đang mượn")) return Colors.blue;
    if (s.contains("chờ duyệt")) return Colors.orange;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text("Quản Lý Mượn Trả"),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          bottom: const TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            isScrollable: false,
            tabs: [
              Tab(text: "Hiện Tại"),
              Tab(text: "Lịch Sử"),
              Tab(text: "Vi Phạm"),
            ],
          ),
        ),
        body: FutureBuilder<List<BorrowedBookHistory>>(
          future: _futureHistory,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Center(child: Text("Lỗi kết nối!"));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("Bạn chưa có giao dịch nào."));
            } else {
              final allBooks = snapshot.data!;

              // --- LOGIC LỌC MỚI (Mạnh mẽ hơn) ---

              // 1. Hiện tại: Bắt tất cả trạng thái CHƯA KẾT THÚC hoặc QUÁ HẠN
              final hienTai = allBooks.where((b) {
                String s = b.trangThai.toLowerCase();
                return s.contains("đang mượn") ||
                    s.contains("chờ duyệt") ||
                    s.contains("thiếu") ||
                    s.contains("chưa trả") ||
                    s.contains("quá hạn"); // Bắt dính mọi chuỗi có chữ "quá hạn"
              }).toList();

              // 2. Lịch sử: Chỉ những sách ĐÃ TRẢ hoặc TỪ CHỐI
              final lichSu = allBooks.where((b) {
                String s = b.trangThai.toLowerCase();
                return s.contains("đã trả") || s.contains("từ chối");
              }).toList();

              // 3. Vi Phạm: Đã trả nhưng có tiền phạt
              final viPham = allBooks.where((b) => b.tienPhat > 0).toList();

              return TabBarView(
                children: [
                  RefreshIndicator(onRefresh: _handleRefresh, child: _buildListBooks(hienTai, isCurrent: true)),
                  RefreshIndicator(onRefresh: _handleRefresh, child: _buildListBooks(lichSu, isCurrent: false)),
                  RefreshIndicator(onRefresh: _handleRefresh, child: _buildFineList(viPham)),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  // --- WIDGET DANH SÁCH SÁCH ---
  Widget _buildListBooks(List<BorrowedBookHistory> books, {required bool isCurrent}) {
    if (books.isEmpty) {
      return ListView(children: const [SizedBox(height: 200), Center(child: Text("Danh sách trống", style: TextStyle(color: Colors.grey)))]);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final item = books[index];
        String imageUrl = ApiService.getImageUrl(item.hinhAnh);

        // Xử lý logic hiển thị màu sắc và icon
        bool isLate = item.trangThai.toLowerCase().contains("quá hạn");
        Color statusColor = _getStatusColor(item.trangThai);
        Color statusBgColor = statusColor.withOpacity(0.1);

        IconData statusIcon = Icons.info;
        if (item.trangThai == "Chờ duyệt") statusIcon = Icons.hourglass_empty;
        else if (item.trangThai == "Đang mượn") statusIcon = Icons.book;
        else if (item.trangThai == "Đã trả") statusIcon = Icons.check_circle;
        else if (isLate) statusIcon = Icons.warning; // Icon cảnh báo nếu quá hạn

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              // Viền đỏ nếu quá hạn để gây chú ý
              side: isLate ? const BorderSide(color: Colors.red, width: 1.5) : BorderSide.none
          ),
          child: InkWell(
            onTap: () => _showTicketDetail(context, item),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      width: 60, height: 90,
                      child: imageUrl.isNotEmpty
                          ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image)))
                          : Container(color: Colors.blue[100], child: const Icon(Icons.book, color: Colors.blue)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.tenSach, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 2),
                        const SizedBox(height: 4),
                        Text("Mã phiếu: #${item.maPhieu}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 4),
                        // Hiển thị Hạn trả hoặc Cảnh báo quá hạn
                        Text(
                          isLate
                              ? "ĐÃ QUÁ HẠN: ${_formatDate(item.hanTra)}"
                              : (item.trangThai == "Chờ duyệt" ? "Ngày gửi: ${_formatDate(item.ngayMuon)}" : "Hạn trả: ${_formatDate(item.hanTra)}"),
                          style: TextStyle(
                              fontSize: 13,
                              color: isLate ? Colors.red : Colors.grey[600],
                              fontWeight: isLate ? FontWeight.bold : FontWeight.normal
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: statusBgColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: statusColor.withOpacity(0.5))),
                              child: Row(
                                children: [
                                  Icon(statusIcon, size: 14, color: statusColor),
                                  const SizedBox(width: 6),
                                  Text(item.trangThai, style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),

                            // --- NÚT THAO TÁC ---
                            // Chỉ hiện ở tab Hiện Tại
                            if (isCurrent)
                              Row(
                                children: [
                                  // Nút Gia hạn (Chỉ hiện khi chưa quá hạn và chưa trả)
                                  if (!isLate && item.trangThai != "Chờ duyệt")
                                    SizedBox(
                                      height: 30,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: const Size(60, 30)),
                                        onPressed: () => _handleGiaHan(item),
                                        child: const Text("Gia hạn", style: TextStyle(fontSize: 11, color: Colors.white)),
                                      ),
                                    ),

                                  if (!isLate && item.trangThai != "Chờ duyệt") const SizedBox(width: 8),

                                  // Nút Trả (Luôn hiện nếu chưa trả xong, kể cả quá hạn)
                                  if (item.trangThai != "Chờ duyệt")
                                    SizedBox(
                                      height: 30,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          // Đổi màu đỏ nếu quá hạn để cảnh báo phạt
                                            backgroundColor: isLate ? Colors.red : Colors.green,
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                            minimumSize: const Size(60, 30)
                                        ),
                                        onPressed: () => _handleTraSach(item.maPhieu, item.maSach),
                                        child: Text(isLate ? "Trả & Phạt" : "Trả", style: const TextStyle(fontSize: 11, color: Colors.white)),
                                      ),
                                    ),
                                ],
                              )
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFineList(List<BorrowedBookHistory> books) {
    if (books.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.thumb_up_alt_outlined, size: 60, color: Colors.green[300]), SizedBox(height: 10), const Text("Tuyệt vời! Bạn không có phiếu phạt nào.", style: TextStyle(color: Colors.grey))]));

    final currencyFormat = NumberFormat("#,##0", "vi_VN");

    // Tính tổng tiền phạt
    // Lưu ý: Dùng Map để tránh cộng trùng tiền phạt nếu API trả về tiền phạt của cả phiếu cho từng dòng sách
    final uniqueFines = <int, double>{};
    for (var book in books) {
      uniqueFines[book.maPhieu] = book.tienPhat;
    }
    double totalFine = uniqueFines.values.fold(0, (sum, val) => sum + val);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.red[50],
          child: Column(
            children: [
              const Text("TỔNG TIỀN PHẠT ĐÃ GHI NHẬN", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text("${currencyFormat.format(totalFine)} đ", style: const TextStyle(fontSize: 24, color: Colors.red, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final item = books[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.redAccent, child: Icon(Icons.gavel, color: Colors.white)),
                  title: Text(item.tenSach, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Phiếu #${item.maPhieu} - Đã trả"),
                  trailing: Text("${currencyFormat.format(item.tienPhat)} đ", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}