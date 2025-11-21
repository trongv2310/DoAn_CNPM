using System;
using System.Collections.Generic;

namespace API_ThuVien.Models
{
    public partial class Danhgiasach
    {
        public int Madanhgia { get; set; }
        public int Masach { get; set; }
        public int Masv { get; set; }
        public int? Diem { get; set; }
        public string? Nhanxet { get; set; }
        public DateTime? Thoigian { get; set; }

        public virtual Sach MasachNavigation { get; set; } = null!;
        public virtual Sinhvien MasvNavigation { get; set; } = null!;
    }
}