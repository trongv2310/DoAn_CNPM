using System;
using System.Collections.Generic;

namespace API_ThuVien.Models;

public partial class Sach
{
    public int Masach { get; set; }

    public string Tensach { get; set; } = null!;

    public int Matg { get; set; }

    public int Manxb { get; set; }

    public string? Hinhanh { get; set; }

    public string? Theloai { get; set; }

    public string? Mota { get; set; }

    public decimal Giamuon { get; set; }

    public int Soluongton { get; set; }

    public string Trangthai { get; set; } = null!;

    public virtual ICollection<Chitietphieumuon> Chitietphieumuons { get; set; } = new List<Chitietphieumuon>();

    public virtual ICollection<Chitietphieunhap> Chitietphieunhaps { get; set; } = new List<Chitietphieunhap>();

    public virtual ICollection<Chitietphieutra> Chitietphieutras { get; set; } = new List<Chitietphieutra>();

    public virtual ICollection<Chitietthanhly> Chitietthanhlies { get; set; } = new List<Chitietthanhly>();

    [System.Text.Json.Serialization.JsonIgnore] // Thêm dòng này để tránh lỗi vòng lặp JSON khi trả về
    public virtual Nhaxuatban? ManxbNavigation { get; set; }

    [System.Text.Json.Serialization.JsonIgnore]
    public virtual Tacgium? MatgNavigation { get; set; }
}
