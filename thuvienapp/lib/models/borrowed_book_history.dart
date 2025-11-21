class BorrowedBookHistory {
  final int maPhieu;      // Khớp với item.maPhieu trong TabTuSach
  final int maSach;       // Khớp với item.maSach
  final String tenSach;
  final String? hinhAnh;
  final double giaMuon;
  final String ngayMuon;  // TabTuSach đang xử lý chuỗi ngày, nên để String
  final String hanTra;    // TabTuSach đang xử lý chuỗi ngày, nên để String
  final String trangThai;
  final double tienPhat;  // Khớp với item.tienPhat

  BorrowedBookHistory({
    required this.maPhieu,
    required this.maSach,
    required this.tenSach,
    this.hinhAnh,
    required this.giaMuon,
    required this.ngayMuon,
    required this.hanTra,
    required this.trangThai,
    required this.tienPhat,
  });

  factory BorrowedBookHistory.fromJson(Map<String, dynamic> json) {
    return BorrowedBookHistory(
      // Bắt tất cả các trường hợp tên biến có thể có từ API
      maPhieu: json['maPhieu'] ?? json['MaPhieu'] ?? json['maPhieuMuon'] ?? json['MaPhieuMuon'] ?? 0,
      maSach: json['maSach'] ?? json['MaSach'] ?? 0,
      tenSach: json['tenSach'] ?? json['TenSach'] ?? "Không tên",
      hinhAnh: json['hinhAnh'] ?? json['HinhAnh'],

      // Chuyển đổi số sang double an toàn
      giaMuon: (json['giamuon'] ?? json['GiaMuon'] ?? json['giaMuon'] ?? 0).toDouble(),

      // Ép kiểu về String để tránh lỗi type mismatch
      ngayMuon: json['ngayMuon']?.toString() ?? json['NgayMuon']?.toString() ?? "",
      hanTra: json['hanTra']?.toString() ?? json['HanTra']?.toString() ?? json['NgayHenTra']?.toString() ?? "",

      trangThai: json['trangThai'] ?? json['TrangThai'] ?? "Đang mượn",

      // Lấy tiền phạt
      tienPhat: (json['tienPhat'] ?? json['TienPhat'] ?? 0).toDouble(),
    );
  }
}