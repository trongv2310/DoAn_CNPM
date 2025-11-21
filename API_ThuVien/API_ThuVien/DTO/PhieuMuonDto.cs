using System;
using System.Collections.Generic;

namespace API_ThuVien.DTO
{
    // DTO gửi lên khi mượn sách
    public class SachMuonDto
    {
        public int MaSach { get; set; }
        public int SoLuong { get; set; }
    }

    public class BorrowRequestDto
    {
        public int MaTaiKhoan { get; set; } // Đây là Mã Tài Khoản (Server sẽ tự tìm ra MaSV)
        public List<SachMuonDto> SachMuon { get; set; }
        public DateTime NgayHenTra { get; set; }
    }

    // DTO trả về lịch sử mượn
    public class LichSuMuonDto
    {
        public int MaPhieu { get; set; }
        public int MaSach { get; set; }
        public string TenSach { get; set; }
        public string HinhAnh { get; set; }
        public decimal GiaMuon { get; set; }
        public DateTime NgayMuon { get; set; }
        public DateTime HanTra { get; set; }
        public string TrangThai { get; set; }
        public double TienPhat { get; set; }
    }

    // DTO gia hạn sách
    public class ExtendRequestDto
    {
        public int MaSach { get; set; }
        public DateTime NgayHenTraMoi { get; set; }
    }

    // DTO trả sách
    public class TraSachDto
    {
        public int MaPhieuMuon { get; set; }
        public int MaSach { get; set; }
    }
}