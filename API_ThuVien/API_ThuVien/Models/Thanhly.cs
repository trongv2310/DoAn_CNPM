using System;
using System.Collections.Generic;

namespace API_ThuVien.Models;

public partial class Thanhly
{
    public int Matl { get; set; }

    public int Matk { get; set; }

    public DateOnly Ngaylap { get; set; }

    public decimal? Tongtien { get; set; }

    public virtual ICollection<Chitietthanhly> Chitietthanhlies { get; set; } = new List<Chitietthanhly>();

    public virtual Thukho MatkNavigation { get; set; } = null!;
}
