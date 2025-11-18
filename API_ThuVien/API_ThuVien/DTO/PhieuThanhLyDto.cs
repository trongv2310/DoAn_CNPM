namespace API_ThuVien.DTO
{
    public class ChiTietThanhLyDto
    {
        public int MaSach { get; set; }
        public int SoLuong { get; set; }
        public decimal DonGia { get; set; }
    }

    public class PhieuThanhLyRequest
    {
        public int MaThuKho { get; set; }
        public List<ChiTietThanhLyDto> ChiTiet { get; set; }
    }
}