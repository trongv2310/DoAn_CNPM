using System;
using System.Collections.Generic;

namespace API_ThuVien.Models;

public partial class Taikhoan
{
    public int Mataikhoan { get; set; }

    public string Tendangnhap { get; set; } = null!;

    public string Matkhau { get; set; } = null!;

    public string? Trangthai { get; set; }

    public int Maquyen { get; set; }

    public virtual Phanquyen MaquyenNavigation { get; set; } = null!;

    public virtual Sinhvien? Sinhvien { get; set; }

    public virtual Thukho? Thukho { get; set; }

    public virtual Thuthu? Thuthu { get; set; }
}
