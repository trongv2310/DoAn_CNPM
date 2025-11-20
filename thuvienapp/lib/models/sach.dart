class Sach {
  final int masach;
  final String tensach;
  final String? hinhanh;
  final double giamuon;
  final int soluongton;

  // --- THÊM CÁC TRƯỜNG MỚI ---
  final String? theloai;
  final String? mota;
  final String? tennxb; // Tên NXB (Nếu API trả về ID thì sửa thành int manxb)

  Sach({
    required this.masach,
    required this.tensach,
    this.hinhanh,
    required this.giamuon,
    required this.soluongton,
    // --- THÊM VÀO CONSTRUCTOR ---
    this.theloai,
    this.mota,
    this.tennxb,
  });

  factory Sach.fromJson(Map<String, dynamic> json) {
    return Sach(
      masach: json['masach'] ?? 0,
      tensach: json['tensach'] ?? "Tên sách lỗi",
      hinhanh: json['hinhanh'],
      giamuon: (json['giamuon'] ?? 0).toDouble(),
      soluongton: json['soluongton'] ?? 0,

      // --- MAP DỮ LIỆU MỚI (Lưu ý key phải khớp với JSON API trả về) ---
      theloai: json['theloai'] ?? "Đang cập nhật",
      mota: json['mota'] ?? "Chưa có mô tả cho sách này.",

      // Nếu Backend trả về object NXB thì lấy tên, nếu trả về ID thì hiển thị ID
      // Ở đây mình giả sử bạn đã Join bảng ở Backend để lấy tên, hoặc tạm thời để trống
      tennxb: json['tennxb'] ?? "NXB Tổng Hợp",
    );
  }
}