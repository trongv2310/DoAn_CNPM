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


  Sach({
    required this.masach,
    required this.tensach,
    this.hinhanh,
    required this.giamuon,
    required this.soluongton,
    this.theLoai,
    this.tenTacGia,
    this.moTa,
    this.tennxb
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
    );
  }
}