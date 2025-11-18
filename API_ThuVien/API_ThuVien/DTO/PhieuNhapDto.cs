namespace API_ThuVien.DTO
{
    public class ChiTietNhapDto
    {
        public int MaSach { get; set; }
        public int SoLuong { get; set; }
        public decimal GiaNhap { get; set; }
    }

    public class PhieuNhapRequest
    {
        public int MaThuKho { get; set; } // Người lập phiếu
        public List<ChiTietNhapDto> ChiTiet { get; set; }
    }
}