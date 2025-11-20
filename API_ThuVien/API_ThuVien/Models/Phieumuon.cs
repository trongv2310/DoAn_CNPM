using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace API_ThuVien.Models;

public partial class Phieumuon
{
    [Key] // Khóa chính
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int Mapm { get; set; }

    public int Masv { get; set; }

    public int Matt { get; set; }

    public DateOnly Ngaylapphieumuon { get; set; }

    public DateOnly Hantra { get; set; }

    public string Trangthai { get; set; } = null!;

    public virtual ICollection<Chitietphieumuon> Chitietphieumuons { get; set; } = new List<Chitietphieumuon>();

    public virtual Sinhvien MasvNavigation { get; set; } = null!;

    public virtual Thuthu MattNavigation { get; set; } = null!;

    public virtual ICollection<Phieutra> Phieutras { get; set; } = new List<Phieutra>();
    public int? Solangiahan { get; set; }
}
