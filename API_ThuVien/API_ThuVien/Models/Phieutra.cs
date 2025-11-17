using System;
using System.Collections.Generic;

namespace API_ThuVien.Models;

public partial class Phieutra
{
    public int Mapt { get; set; }

    public int Mapm { get; set; }

    public int Matt { get; set; }

    public DateOnly Ngaylapphieutra { get; set; }

    public int? Songayquahan { get; set; }

    public double? Tongtienphat { get; set; }

    public virtual ICollection<Chitietphieutra> Chitietphieutras { get; set; } = new List<Chitietphieutra>();

    public virtual Phieumuon MapmNavigation { get; set; } = null!;

    public virtual Thuthu MattNavigation { get; set; } = null!;
}
