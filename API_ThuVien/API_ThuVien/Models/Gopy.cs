using System;
using System.Collections.Generic;

namespace API_ThuVien.Models
{
    public partial class Gopy
    {
        public int Magopy { get; set; }
        public int Masv { get; set; }
        public string Noidung { get; set; } = null!;
        public string? Loaigopy { get; set; }
        public DateTime? Thoigiangui { get; set; }
        public string? Trangthai { get; set; }

        public virtual Sinhvien MasvNavigation { get; set; } = null!;
    }
}