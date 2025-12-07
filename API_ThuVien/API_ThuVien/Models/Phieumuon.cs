using System;
using System.Collections.Generic;

namespace API_ThuVien.Models;

public partial class Phieumuon
{
    public int Mapm { get; set; }

    public int Masv { get; set; }

    public int Matt { get; set; }

    public DateOnly Ngaylapphieumuon { get; set; }

    public DateOnly Hantra { get; set; }

    public string Trangthai { get; set; } = null!;
    public int Solangiahan { get; set; }

    public virtual ICollection<Chitietphieumuon> Chitietphieumuons { get; set; } = new List<Chitietphieumuon>();

    public virtual Sinhvien MasvNavigation { get; set; } = null!;

    public virtual Thuthu MattNavigation { get; set; } = null!;

    public virtual ICollection<Phieutra> Phieutras { get; set; } = new List<Phieutra>();
}
