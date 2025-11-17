using System;
using System.Collections.Generic;

namespace API_ThuVien.Models;

public partial class Chitietthanhly
{
    public int Matl { get; set; }

    public int Masach { get; set; }

    public int Soluong { get; set; }

    public decimal Dongia { get; set; }

    public decimal? Thanhtien { get; set; }

    public virtual Sach MasachNavigation { get; set; } = null!;

    public virtual Thanhly MatlNavigation { get; set; } = null!;
}
