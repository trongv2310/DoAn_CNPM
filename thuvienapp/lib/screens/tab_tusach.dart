import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  // --- HÀM TÍNH TIỀN PHẠT (CẢ THỰC TẾ VÀ TẠM TÍNH) ---
  double _calculateFine(BorrowedBookHistory item) {
    if (item.tienPhat > 0) return item.tienPhat;

    String status = item.trangThai.toLowerCase();
    if (status.contains("đã trả") || status.contains("chờ duyệt") || status.contains("từ chối")) return 0.0;

    try {
      DateTime hanTra = DateTime.parse(item.hanTra);
      DateTime now = DateTime.now();

      if (now.isAfter(hanTra)) {
        int daysLate = now.difference(hanTra).inDays;
        if (daysLate > 0) {
          return daysLate * 1000.0; // Phạt 1.000đ / ngày
        }
      }
    } catch (e) {
      return 0.0;
    }

    return 0.0;
  }

  // --- HÀM XỬ LÝ TRẢ SÁCH ---
  void _handleTraSach(int maPhieu, int maSach) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Gửi yêu cầu trả sách?"),
        content: const Text("Hệ thống sẽ ghi nhận yêu cầu.\nVui lòng mang sách đến quầy để thủ thư xác nhận."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Gửi Yêu Cầu")),
        ],
      ),
    ) ?? false;

    if (confirm) {
      final result = await _apiService.requestReturnBook(maPhieu, maSach);
      if (!mounted) return;
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']), backgroundColor: Colors.blue));
        _handleRefresh();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? "Lỗi"), backgroundColor: Colors.red));
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']), backgroundColor: Colors.green));
        _handleRefresh();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? "Lỗi gia hạn"), backgroundColor: Colors.red));
      }
    }
  }

  // --- [MỚI] HÀM XỬ LÝ HỦY YÊU CẦU MƯỢN ---
  void _handleHuyYeuCau(int maPhieu) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận hủy"),
        content: const Text("Bạn có chắc chắn muốn hủy yêu cầu mượn sách này không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Không")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Đồng ý")),
        ],
      ),
    ) ?? false;

    if (confirm) {
      // Gọi API hủy (lưu ý: Hàm này phải được định nghĩa trong ApiService rồi)
      bool success = await _apiService.huyYeuCauMuon(maPhieu);
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Đã hủy yêu cầu thành công!"), backgroundColor: Colors.green)
        );
        _handleRefresh(); // Tải lại danh sách để ẩn sách vừa hủy
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Lỗi: Không thể hủy yêu cầu này."), backgroundColor: Colors.red)
        );
      }
    }
  }

  // --- POPUP CHI TIẾT ---
  void _showTicketDetail(BuildContext context, BorrowedBookHistory item) {
    double fine = _calculateFine(item);

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

            if (fine > 0)
              _buildRowDetail("Tiền phạt:", "${NumberFormat("#,##0").format(fine)} đ", isRed: true),

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

  Color _getStatusColor(String status) {
    String s = status.toLowerCase();
    if (s.contains("quá hạn")) return Colors.red;
    if (s.contains("đã trả")) return Colors.green;
    if (s.contains("đang mượn")) return Colors.blue;
    if (s.contains("chờ duyệt")) return Colors.orange;
    if (s.contains("chờ trả")) return Colors.purple;
    if (s.contains("từ chối")) return Colors.redAccent;
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

              // 1. Hiện tại: Chưa trả xong hoặc đang quá hạn
              final hienTai = allBooks.where((b) {
                String s = b.trangThai.toLowerCase();
                // Không hiển thị "Đã trả" và "Từ chối" ở tab hiện tại
                return !s.contains("đã trả") && !s.contains("từ chối");
              }).toList();

              // 2. Lịch sử: Đã trả hoặc bị từ chối
              final lichSu = allBooks.where((b) {
                String s = b.trangThai.toLowerCase();
                return s.contains("đã trả") || s.contains("từ chối");
              }).toList();

              // 3. Vi Phạm: Có tiền phạt
              final viPham = allBooks.where((b) => _calculateFine(b) > 0).toList();

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

        bool isLate = item.trangThai.toLowerCase().contains("quá hạn");
        Color statusColor = _getStatusColor(item.trangThai);
        Color statusBgColor = statusColor.withOpacity(0.1);

        IconData statusIcon = Icons.info;
        if (item.trangThai == "Chờ duyệt") statusIcon = Icons.hourglass_empty;
        else if (item.trangThai == "Đang mượn") statusIcon = Icons.book;
        else if (item.trangThai == "Đã trả") statusIcon = Icons.check_circle;
        else if (item.trangThai == "Chờ trả") statusIcon = Icons.assignment_return;
        else if (item.trangThai == "Từ chối") statusIcon = Icons.cancel;
        else if (isLate) statusIcon = Icons.warning;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
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
                            if (isCurrent)
                              Row(
                                children: [
                                  // --- [MỚI] NÚT HỦY YÊU CẦU (Chỉ hiện khi Chờ duyệt) ---
                                  if (item.trangThai == "Chờ duyệt")
                                    SizedBox(
                                      height: 30,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.redAccent,
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                            minimumSize: const Size(60, 30)
                                        ),
                                        onPressed: () => _handleHuyYeuCau(item.maPhieu),
                                        child: const Text("Hủy yêu cầu", style: TextStyle(fontSize: 11, color: Colors.white)),
                                      ),
                                    ),

                                  // --- Nút Gia hạn (Không hiện khi quá hạn, chờ duyệt, chờ trả) ---
                                  if (!isLate && item.trangThai != "Chờ duyệt" && item.trangThai != "Chờ trả")
                                    SizedBox(
                                      height: 30,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: const Size(60, 30)),
                                        onPressed: () => _handleGiaHan(item),
                                        child: const Text("Gia hạn", style: TextStyle(fontSize: 11, color: Colors.white)),
                                      ),
                                    ),

                                  if (!isLate && item.trangThai != "Chờ duyệt" && item.trangThai != "Chờ trả") const SizedBox(width: 8),

                                  // --- Nút Trả sách (Không hiện khi chờ duyệt, chờ trả) ---
                                  if (item.trangThai != "Chờ duyệt" && item.trangThai != "Chờ trả")
                                    SizedBox(
                                      height: 30,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
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

  // --- DANH SÁCH VI PHẠM ---
  Widget _buildFineList(List<BorrowedBookHistory> books) {
    if (books.isEmpty) {
      return Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.thumb_up_alt_outlined, size: 60, color: Colors.green[300]),
                const SizedBox(height: 10),
                const Text("Tuyệt vời! Bạn không có khoản phạt nào.", style: TextStyle(color: Colors.grey))
              ]));
    }

    final currencyFormat = NumberFormat("#,##0", "vi_VN");
    double totalFine = books.fold(0, (sum, item) => sum + _calculateFine(item));

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.red[50],
          child: Column(
            children: [
              const Text("TỔNG TIỀN PHẠT (TẠM TÍNH)", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
              double fine = _calculateFine(item);

              bool isReturned = item.trangThai.toLowerCase().contains("đã trả");
              String statusText = isReturned ? "Đã trả (Chưa thanh toán)" : "Đang mượn (Quá hạn)";

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.redAccent, child: Icon(Icons.gavel, color: Colors.white)),
                  title: Text(item.tenSach, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Phiếu #${item.maPhieu} - $statusText"),
                  trailing: Text("${currencyFormat.format(fine)} đ", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}