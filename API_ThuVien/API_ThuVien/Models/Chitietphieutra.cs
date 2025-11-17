using System;
using System.Collections.Generic;

namespace API_ThuVien.Models;

public partial class Chitietphieutra
{
    public int Mapt { get; set; }

    public int Masach { get; set; }

    public int? Soluongtra { get; set; }

    public DateOnly? Ngaytra { get; set; }

    public virtual Phieutra MaptNavigation { get; set; } = null!;

    public virtual Sach MasachNavigation { get; set; } = null!;
}
