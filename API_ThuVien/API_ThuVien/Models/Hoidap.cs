using System;
using System.Collections.Generic;

namespace API_ThuVien.Models
{
    public partial class Hoidap
    {
        public int Mahoidap { get; set; }
        public int Masv { get; set; }
        public string Cauhoi { get; set; } = null!;
        public string? Traloi { get; set; }
        public int? Matt { get; set; }
        public DateTime? Thoigianhoi { get; set; }
        public DateTime? Thoigiantraloi { get; set; }
        public string? Trangthai { get; set; }

        public virtual Sinhvien MasvNavigation { get; set; } = null!;
        public virtual Thuthu? MattNavigation { get; set; }
    }
}