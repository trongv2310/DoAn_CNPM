using System;
using System.Collections.Generic;

namespace API_ThuVien.Models;

public partial class Sinhvien
{
    public int Masv { get; set; }

    public int Mataikhoan { get; set; }

    public string? Hovaten { get; set; }

    public string? Gioitinh { get; set; }

    public DateOnly? Ngaysinh { get; set; }

    public string? Sdt { get; set; }

    public string? Email { get; set; }

    public virtual Taikhoan MataikhoanNavigation { get; set; } = null!;

    public virtual ICollection<Phieumuon> Phieumuons { get; set; } = new List<Phieumuon>();
}
