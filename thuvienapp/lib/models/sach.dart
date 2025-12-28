class Sach {
  final int masach;
  final String tensach;
  final String? hinhanh;
  final double giamuon;
  final int soluongton;
  final String? theLoai;
  final String? tenTacGia;
  final String? moTa;
  final String? tennxb;
  final int matg;
  final int manxb;
  final String trangThai;

  Sach({
    required this.masach,
    required this.tensach,
    this.hinhanh,
    required this.giamuon,
    required this.soluongton,
    this.theLoai,
    this.tenTacGia,
    this.moTa,
    this.tennxb,
    required this.matg,
    required this.manxb,
    required this.trangThai,
  });

  factory Sach.fromJson(Map<String, dynamic> json) {
    return Sach(
      masach: json['masach'] ?? 0,
      tensach: json['tensach'] ?? "Sách chưa cập nhật tên",
      hinhanh: json['hinhanh'],
      giamuon: (json['giamuon'] ?? 0).toDouble(),
      soluongton: json['soluongton'] ?? 0,
      // Map đúng key từ Backend trả về ở Bước 1
      theLoai: json['theloai'] ?? "Khác",
      tenTacGia: json['tenTacGia'] ?? "Chưa rõ",
      moTa: json['mota'] ?? "",
      matg: json['matg'] ?? json['Matg'] ?? 0,
      manxb: json['manxb'] ?? json['Manxb'] ?? 0,
      trangThai: json['trangthai'] ?? json['Trangthai'] ?? "Có sẵn",
      tennxb: json['tenNxb'] ?? json['TenNxb'] ?? "Đang cập nhật",
    );
  }
}