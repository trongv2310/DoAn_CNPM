class BorrowedBookHistory {
  final int maPhieu;
  final int maSach;
  final String tenSach;
  final String? hinhAnh;
  final double giaMuon;
  final String ngayMuon;
  final String hanTra;
  final String trangThai;
  final double tienPhat;

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
      // Dùng ?? để kiểm tra cả key viết thường và viết hoa (Do C# thường trả về viết hoa)
      maPhieu: json['maPhieu'] ?? json['MaPhieu'] ?? 0,
      maSach: json['maSach'] ?? json['MaSach'] ?? 0,

      tenSach: json['tenSach'] ?? json['TenSach'] ?? "Không tên",
      hinhAnh: json['hinhAnh'] ?? json['HinhAnh'],

      // Chuyển đổi an toàn sang double
      giaMuon: (json['giamuon'] ?? json['GiaMuon'] ?? json['giaMuon'] ?? 0).toDouble(),

      ngayMuon: json['ngayMuon'] ?? json['NgayMuon'] ?? "",
      hanTra: json['hanTra'] ?? json['HanTra'] ?? "",
      trangThai: json['trangThai'] ?? json['TrangThai'] ?? "Đang mượn",

      // Quan trọng: Lấy tiền phạt
      tienPhat: (json['tienPhat'] ?? json['TienPhat'] ?? 0).toDouble(),
    );
  }
}