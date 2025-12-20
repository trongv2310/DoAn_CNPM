namespace API_ThuVien.DTO
{
    // DTO cho Hỏi Đáp
    public class HoiDapRequest
    {
        public int MaSinhVien { get; set; }
        public string CauHoi { get; set; }
    }

    // DTO cho Góp Ý
    public class GopYRequest
    {
        public int MaSinhVien { get; set; }
        public string NoiDung { get; set; }
        public string LoaiGopY { get; set; } // "Cơ sở vật chất", "Thái độ", "Khác"
    }

    // DTO hiển thị Đánh Giá (để xem)
    public class DanhGiaHienThiDto
    {
        public int MaDanhGia { get; set; }
        public string TenSach { get; set; }
        public string TenSinhVien { get; set; }
        public int? Diem { get; set; }
        public string NhanXet { get; set; }
        public string NgayDanhGia { get; set; }
    }
    public class DanhGiaRequest
    {
        public int MaSach { get; set; }
        public int MaSinhVien { get; set; }
        public int Diem { get; set; } // 1 đến 5 sao
        public string NhanXet { get; set; }
    }
}