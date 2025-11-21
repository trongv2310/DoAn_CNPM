using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;

namespace API_ThuVien.Models;

public partial class ThuVienDbContext : DbContext
{
    public ThuVienDbContext()
    {
    }

    public ThuVienDbContext(DbContextOptions<ThuVienDbContext> options)
        : base(options)
    {
    }

    public virtual DbSet<Chitietphieumuon> Chitietphieumuons { get; set; }
    public virtual DbSet<Chitietphieunhap> Chitietphieunhaps { get; set; }
    public virtual DbSet<Chitietphieutra> Chitietphieutras { get; set; }
    public virtual DbSet<Chitietthanhly> Chitietthanhlies { get; set; }
    public virtual DbSet<Nhaxuatban> Nhaxuatbans { get; set; }
    public virtual DbSet<Phanquyen> Phanquyens { get; set; }
    public virtual DbSet<Phieumuon> Phieumuons { get; set; }
    public virtual DbSet<Phieunhap> Phieunhaps { get; set; }
    public virtual DbSet<Phieutra> Phieutras { get; set; }
    public virtual DbSet<Sach> Saches { get; set; }
    public virtual DbSet<Sinhvien> Sinhviens { get; set; }
    public virtual DbSet<Tacgium> Tacgia { get; set; }
    public virtual DbSet<Taikhoan> Taikhoans { get; set; }
    public virtual DbSet<Thanhly> Thanhlies { get; set; }
    public virtual DbSet<Thukho> Thukhos { get; set; }
    public virtual DbSet<Thuthu> Thuthus { get; set; }
    public virtual DbSet<Hoidap> Hoidaps { get; set; }
    public virtual DbSet<Gopy> Gopies { get; set; }
    public virtual DbSet<Danhgiasach> Danhgiasaches { get; set; }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
#warning To protect potentially sensitive information in your connection string, you should move it out of source code. You can avoid scaffolding the connection string by using the Name= syntax to read it from configuration - see https://go.microsoft.com/fwlink/?linkid=2131148. For more guidance on storing connection strings, see https://go.microsoft.com/fwlink/?LinkId=723263.
        => optionsBuilder.UseSqlServer("Server=DESKTOP-HHFANUM;Database=ThuVienDB;Trusted_Connection=True;TrustServerCertificate=True;");

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Chitietphieumuon>(entity =>
        {
            entity.HasKey(e => new { e.Mapm, e.Masach }).HasName("PK_CTPM");

            entity.ToTable("CHITIETPHIEUMUON");

            entity.Property(e => e.Mapm).HasColumnName("MAPM");
            entity.Property(e => e.Masach).HasColumnName("MASACH");
            entity.Property(e => e.Soluong)
                .HasDefaultValue(0)
                .HasColumnName("SOLUONG");

            // --- THÊM MAPPING CHO 2 CỘT MỚI ---
            entity.Property(e => e.Hantra).HasColumnName("HANTRA");
            entity.Property(e => e.Solangiahan)
                .HasDefaultValue(0)
                .HasColumnName("SOLANGIAHAN");
            // ----------------------------------

            entity.HasOne(d => d.MapmNavigation).WithMany(p => p.Chitietphieumuons)
                .HasForeignKey(d => d.Mapm)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_CTPM_PM");

            entity.HasOne(d => d.MasachNavigation).WithMany(p => p.Chitietphieumuons)
                .HasForeignKey(d => d.Masach)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_CTPM_SACH");
        });

        modelBuilder.Entity<Chitietphieunhap>(entity =>
        {
            entity.HasKey(e => new { e.Mapn, e.Masach }).HasName("PK_CTPN");

            entity.ToTable("CHITIETPHIEUNHAP", tb => tb.HasTrigger("TG_CAPNHATSLTONCUASACH_CTPN"));

            entity.Property(e => e.Mapn).HasColumnName("MAPN");
            entity.Property(e => e.Masach).HasColumnName("MASACH");
            entity.Property(e => e.Gianhap)
                .HasColumnType("decimal(10, 2)")
                .HasColumnName("GIANHAP");
            entity.Property(e => e.Soluong).HasColumnName("SOLUONG");
            entity.Property(e => e.Thanhtien)
                .HasComputedColumnSql("([SOLUONG]*[GIANHAP])", true)
                .HasColumnType("decimal(21, 2)")
                .HasColumnName("THANHTIEN");

            entity.HasOne(d => d.MapnNavigation).WithMany(p => p.Chitietphieunhaps)
                .HasForeignKey(d => d.Mapn)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_CTPN_PN");

            entity.HasOne(d => d.MasachNavigation).WithMany(p => p.Chitietphieunhaps)
                .HasForeignKey(d => d.Masach)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_CTPN_SACH");
        });

        modelBuilder.Entity<Chitietphieutra>(entity =>
        {
            entity.HasKey(e => new { e.Mapt, e.Masach }).HasName("PK_CTPT");
            entity.ToTable("CHITIETPHIEUTRA", tb =>
            {
                tb.HasTrigger("TG_CAPNHATTIENPHAT_PT");      
                tb.HasTrigger("TG_CAPNHATSLTONCUASACH_CTPT"); 
            });

             entity.Property(e => e.Mapt).HasColumnName("MAPT");
            entity.Property(e => e.Masach).HasColumnName("MASACH");
            entity.Property(e => e.Ngaytra).HasColumnName("NGAYTRA");
            entity.Property(e => e.Soluongtra).HasColumnName("SOLUONGTRA");

            entity.HasOne(d => d.MaptNavigation).WithMany(p => p.Chitietphieutras).HasForeignKey(d => d.Mapt).OnDelete(DeleteBehavior.ClientSetNull).HasConstraintName("FK_CTPT_PT");
            entity.HasOne(d => d.MasachNavigation).WithMany(p => p.Chitietphieutras).HasForeignKey(d => d.Masach).OnDelete(DeleteBehavior.ClientSetNull).HasConstraintName("FK_CTPT_SACH");
        });

        modelBuilder.Entity<Chitietthanhly>(entity =>
        {
            entity.HasKey(e => new { e.Matl, e.Masach }).HasName("PK_CTTL");

            entity.ToTable("CHITIETTHANHLY", tb => tb.HasTrigger("TG_CAPNHATSLTON_THANHLY"));

            entity.Property(e => e.Matl).HasColumnName("MATL");
            entity.Property(e => e.Masach).HasColumnName("MASACH");
            entity.Property(e => e.Dongia)
                .HasColumnType("decimal(10, 2)")
                .HasColumnName("DONGIA");
            entity.Property(e => e.Soluong).HasColumnName("SOLUONG");
            entity.Property(e => e.Thanhtien)
                .HasComputedColumnSql("([SOLUONG]*[DONGIA])", true)
                .HasColumnType("decimal(21, 2)")
                .HasColumnName("THANHTIEN");

            entity.HasOne(d => d.MasachNavigation).WithMany(p => p.Chitietthanhlies)
                .HasForeignKey(d => d.Masach)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_CTTL_SACH");

            entity.HasOne(d => d.MatlNavigation).WithMany(p => p.Chitietthanhlies)
                .HasForeignKey(d => d.Matl)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_CTTL_TL");
        });

        modelBuilder.Entity<Nhaxuatban>(entity =>
        {
            entity.HasKey(e => e.Manxb).HasName("PK__NHAXUATB__7ABD9EF20B49F20F");

            entity.ToTable("NHAXUATBAN");

            entity.Property(e => e.Manxb).HasColumnName("MANXB");
            entity.Property(e => e.Diachi)
                .HasMaxLength(100)
                .HasColumnName("DIACHI");
            entity.Property(e => e.Sdt)
                .HasMaxLength(15)
                .IsUnicode(false)
                .HasColumnName("SDT");
            entity.Property(e => e.Tennxb)
                .HasMaxLength(100)
                .HasColumnName("TENNXB");
        });

        modelBuilder.Entity<Phanquyen>(entity =>
        {
            entity.HasKey(e => e.Maquyen).HasName("PK__PHANQUYE__F2A840CF7C44404B");

            entity.ToTable("PHANQUYEN");

            entity.HasIndex(e => e.Tenquyen, "UQ__PHANQUYE__3B380E4F0884E15C").IsUnique();

            entity.Property(e => e.Maquyen).HasColumnName("MAQUYEN");
            entity.Property(e => e.Tenquyen)
                .HasMaxLength(50)
                .HasColumnName("TENQUYEN");
        });

        modelBuilder.Entity<Phieumuon>(entity =>
        {
            entity.HasKey(e => e.Mapm).HasName("PK__PHIEUMUO__603F61CD2957288E");

            entity.ToTable("PHIEUMUON");

            entity.Property(e => e.Mapm).HasColumnName("MAPM").ValueGeneratedOnAdd();
            entity.Property(e => e.Hantra).HasColumnName("HANTRA");
            entity.Property(e => e.Masv).HasColumnName("MASV");
            entity.Property(e => e.Matt).HasColumnName("MATT");
            entity.Property(e => e.Ngaylapphieumuon).HasColumnName("NGAYLAPPHIEUMUON");
            entity.Property(e => e.Trangthai)
                .HasMaxLength(30)
                .HasDefaultValue("Đang mượn")
                .HasColumnName("TRANGTHAI");

            entity.HasOne(d => d.MasvNavigation).WithMany(p => p.Phieumuons)
                .HasForeignKey(d => d.Masv)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_PM_SV");

            entity.HasOne(d => d.MattNavigation).WithMany(p => p.Phieumuons)
                .HasForeignKey(d => d.Matt)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_PM_TT");
        });

        modelBuilder.Entity<Phieunhap>(entity =>
        {
            entity.HasKey(e => e.Mapn).HasName("PK__PHIEUNHA__603F61CEE562FF45");

            entity.ToTable("PHIEUNHAP");

            entity.Property(e => e.Mapn).HasColumnName("MAPN");
            entity.Property(e => e.Matk).HasColumnName("MATK");
            entity.Property(e => e.Ngaynhap).HasColumnName("NGAYNHAP");
            entity.Property(e => e.Tongtien)
                .HasColumnType("decimal(12, 2)")
                .HasColumnName("TONGTIEN");

            entity.HasOne(d => d.MatkNavigation).WithMany(p => p.Phieunhaps)
                .HasForeignKey(d => d.Matk)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_PN_TK");
        });

        modelBuilder.Entity<Phieutra>(entity =>
        {
            entity.HasKey(e => e.Mapt).HasName("PK__PHIEUTRA__603F61D4A5F39CB6");

            entity.ToTable("PHIEUTRA");

            entity.Property(e => e.Mapt).HasColumnName("MAPT");
            entity.Property(e => e.Mapm).HasColumnName("MAPM");
            entity.Property(e => e.Matt).HasColumnName("MATT");
            entity.Property(e => e.Ngaylapphieutra).HasColumnName("NGAYLAPPHIEUTRA");
            entity.Property(e => e.Songayquahan)
                .HasDefaultValue(0)
                .HasColumnName("SONGAYQUAHAN");
            entity.Property(e => e.Tongtienphat)
                .HasDefaultValue(0.0)
                .HasColumnName("TONGTIENPHAT");

            entity.HasOne(d => d.MapmNavigation).WithMany(p => p.Phieutras)
                .HasForeignKey(d => d.Mapm)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_PT_PM");

            entity.HasOne(d => d.MattNavigation).WithMany(p => p.Phieutras)
                .HasForeignKey(d => d.Matt)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_PT_TT");
        });

        modelBuilder.Entity<Sach>(entity =>
        {
            entity.HasKey(e => e.Masach).HasName("PK__SACH__3FC48E4CC7BFDFD1");

            entity.ToTable("SACH");

            entity.Property(e => e.Masach).HasColumnName("MASACH");
            entity.Property(e => e.Giamuon)
                .HasColumnType("decimal(10, 2)")
                .HasColumnName("GIAMUON");
            entity.Property(e => e.Hinhanh)
                .HasMaxLength(255)
                .IsUnicode(false)
                .HasColumnName("HINHANH");
            entity.Property(e => e.Manxb).HasColumnName("MANXB");
            entity.Property(e => e.Matg).HasColumnName("MATG");
            entity.Property(e => e.Mota)
                .HasMaxLength(255)
                .HasColumnName("MOTA");
            entity.Property(e => e.Soluongton).HasColumnName("SOLUONGTON");
            entity.Property(e => e.Tensach)
                .HasMaxLength(100)
                .HasColumnName("TENSACH");
            entity.Property(e => e.Theloai)
                .HasMaxLength(50)
                .HasColumnName("THELOAI");
            entity.Property(e => e.Trangthai)
                .HasMaxLength(30)
                .HasDefaultValue("Có sẵn")
                .HasColumnName("TRANGTHAI");

            entity.HasOne(d => d.ManxbNavigation).WithMany(p => p.Saches)
                .HasForeignKey(d => d.Manxb)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_SACH_NXB");

            entity.HasOne(d => d.MatgNavigation).WithMany(p => p.Saches)
                .HasForeignKey(d => d.Matg)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_SACH_TACGIA");
        });

        modelBuilder.Entity<Sinhvien>(entity =>
        {
            entity.HasKey(e => e.Masv).HasName("PK__SINHVIEN__60228A28D276667F");

            entity.ToTable("SINHVIEN");

            entity.HasIndex(e => e.Email, "UQ__SINHVIEN__161CF724B5A6C8E1").IsUnique();

            entity.HasIndex(e => e.Mataikhoan, "UQ__SINHVIEN__2ED8B516A6B46FC4").IsUnique();

            entity.Property(e => e.Masv).HasColumnName("MASV");
            entity.Property(e => e.Email)
                .HasMaxLength(50)
                .IsUnicode(false)
                .HasColumnName("EMAIL");
            entity.Property(e => e.Gioitinh)
                .HasMaxLength(5)
                .HasColumnName("GIOITINH");
            entity.Property(e => e.Hovaten)
                .HasMaxLength(100)
                .HasColumnName("HOVATEN");
            entity.Property(e => e.Mataikhoan).HasColumnName("MATAIKHOAN");
            entity.Property(e => e.Ngaysinh).HasColumnName("NGAYSINH");
            entity.Property(e => e.Sdt)
                .HasMaxLength(15)
                .IsUnicode(false)
                .HasColumnName("SDT");

            entity.HasOne(d => d.MataikhoanNavigation).WithOne(p => p.Sinhvien)
                .HasForeignKey<Sinhvien>(d => d.Mataikhoan)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_SINHVIEN_TAIKHOAN");
        });

        modelBuilder.Entity<Tacgium>(entity =>
        {
            entity.HasKey(e => e.Matg).HasName("PK__TACGIA__6023721A91EA31AC");

            entity.ToTable("TACGIA");

            entity.Property(e => e.Matg).HasColumnName("MATG");
            entity.Property(e => e.Mota)
                .HasMaxLength(200)
                .HasColumnName("MOTA");
            entity.Property(e => e.Quoctich)
                .HasMaxLength(30)
                .HasColumnName("QUOCTICH");
            entity.Property(e => e.Tentg)
                .HasMaxLength(50)
                .HasColumnName("TENTG");
        });

        modelBuilder.Entity<Taikhoan>(entity =>
        {
            entity.HasKey(e => e.Mataikhoan).HasName("PK__TAIKHOAN__2ED8B5177AA65ABE");

            entity.ToTable("TAIKHOAN");

            entity.HasIndex(e => e.Tendangnhap, "UQ__TAIKHOAN__6C836FE52FA0F86F").IsUnique();

            entity.Property(e => e.Mataikhoan).HasColumnName("MATAIKHOAN");
            entity.Property(e => e.Maquyen).HasColumnName("MAQUYEN");
            entity.Property(e => e.Matkhau)
                .HasMaxLength(255)
                .HasColumnName("MATKHAU");
            entity.Property(e => e.Tendangnhap)
                .HasMaxLength(50)
                .HasColumnName("TENDANGNHAP");
            entity.Property(e => e.Trangthai)
                .HasMaxLength(20)
                .HasDefaultValue("Hoạt động")
                .HasColumnName("TRANGTHAI");

            entity.HasOne(d => d.MaquyenNavigation).WithMany(p => p.Taikhoans)
                .HasForeignKey(d => d.Maquyen)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_TAIKHOAN_PHANQUYEN");
        });

        modelBuilder.Entity<Thanhly>(entity =>
        {
            entity.HasKey(e => e.Matl).HasName("PK__THANHLY__60237217F52A330B");

            entity.ToTable("THANHLY");

            entity.Property(e => e.Matl).HasColumnName("MATL");
            entity.Property(e => e.Matk).HasColumnName("MATK");
            entity.Property(e => e.Ngaylap).HasColumnName("NGAYLAP");
            entity.Property(e => e.Tongtien)
                .HasDefaultValue(0m)
                .HasColumnType("decimal(12, 2)")
                .HasColumnName("TONGTIEN");

            entity.HasOne(d => d.MatkNavigation).WithMany(p => p.Thanhlies)
                .HasForeignKey(d => d.Matk)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_TL_TK");
        });

        modelBuilder.Entity<Thukho>(entity =>
        {
            entity.HasKey(e => e.Matk).HasName("PK__THUKHO__6023721633569E20");

            entity.ToTable("THUKHO");

            entity.HasIndex(e => e.Email, "UQ__THUKHO__161CF724C127C362").IsUnique();

            entity.HasIndex(e => e.Mataikhoan, "UQ__THUKHO__2ED8B5168A30E8B7").IsUnique();

            entity.Property(e => e.Matk).HasColumnName("MATK");
            entity.Property(e => e.Email)
                .HasMaxLength(50)
                .IsUnicode(false)
                .HasColumnName("EMAIL");
            entity.Property(e => e.Gioitinh)
                .HasMaxLength(5)
                .HasColumnName("GIOITINH");
            entity.Property(e => e.Hovaten)
                .HasMaxLength(100)
                .HasColumnName("HOVATEN");
            entity.Property(e => e.Mataikhoan).HasColumnName("MATAIKHOAN");
            entity.Property(e => e.Ngaysinh).HasColumnName("NGAYSINH");
            entity.Property(e => e.Sdt)
                .HasMaxLength(15)
                .IsUnicode(false)
                .HasColumnName("SDT");

            entity.HasOne(d => d.MataikhoanNavigation).WithOne(p => p.Thukho)
                .HasForeignKey<Thukho>(d => d.Mataikhoan)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_THUKHO_TAIKHOAN");
        });

        modelBuilder.Entity<Thuthu>(entity =>
        {
            entity.HasKey(e => e.Matt).HasName("PK__THUTHU__6023720F77DFBEC2");

            entity.ToTable("THUTHU");

            entity.HasIndex(e => e.Email, "UQ__THUTHU__161CF724B0EA5DA8").IsUnique();

            entity.HasIndex(e => e.Mataikhoan, "UQ__THUTHU__2ED8B5160353E086").IsUnique();

            entity.Property(e => e.Matt).HasColumnName("MATT");
            entity.Property(e => e.Email)
                .HasMaxLength(50)
                .IsUnicode(false)
                .HasColumnName("EMAIL");
            entity.Property(e => e.Gioitinh)
                .HasMaxLength(5)
                .HasColumnName("GIOITINH");
            entity.Property(e => e.Hovaten)
                .HasMaxLength(100)
                .HasColumnName("HOVATEN");
            entity.Property(e => e.Mataikhoan).HasColumnName("MATAIKHOAN");
            entity.Property(e => e.Ngaysinh).HasColumnName("NGAYSINH");
            entity.Property(e => e.Sdt)
                .HasMaxLength(15)
                .IsUnicode(false)
                .HasColumnName("SDT");

            entity.HasOne(d => d.MataikhoanNavigation).WithOne(p => p.Thuthu)
                .HasForeignKey<Thuthu>(d => d.Mataikhoan)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_THUTHU_TAIKHOAN");
        });

        modelBuilder.Entity<Hoidap>(entity =>
        {
            entity.ToTable("HOIDAP");
            entity.HasKey(e => e.Mahoidap);
            entity.Property(e => e.Mahoidap).HasColumnName("MAHOIDAP");
            entity.Property(e => e.Masv).HasColumnName("MASV");
            entity.Property(e => e.Cauhoi).HasColumnName("CAUHOI");
            entity.Property(e => e.Traloi).HasColumnName("TRALOI");
            entity.Property(e => e.Matt).HasColumnName("MATT");
            entity.Property(e => e.Thoigianhoi).HasColumnName("THOIGIANHOI").HasColumnType("datetime");
            entity.Property(e => e.Thoigiantraloi).HasColumnName("THOIGIANTRALOI").HasColumnType("datetime");
            entity.Property(e => e.Trangthai).HasColumnName("TRANGTHAI").HasMaxLength(50);

            entity.HasOne(d => d.MasvNavigation).WithMany()
                .HasForeignKey(d => d.Masv).HasConstraintName("FK_HOIDAP_SV");

            entity.HasOne(d => d.MattNavigation).WithMany()
                .HasForeignKey(d => d.Matt).HasConstraintName("FK_HOIDAP_TT");
        });

        modelBuilder.Entity<Gopy>(entity =>
        {
            entity.ToTable("GOPY");
            entity.HasKey(e => e.Magopy);
            entity.Property(e => e.Magopy).HasColumnName("MAGOPY");
            entity.Property(e => e.Masv).HasColumnName("MASV");
            entity.Property(e => e.Noidung).HasColumnName("NOIDUNG");
            entity.Property(e => e.Loaigopy).HasColumnName("LOAIGOPY").HasMaxLength(50);
            entity.Property(e => e.Thoigiangui).HasColumnName("THOIGIANGUI").HasColumnType("datetime");
            entity.Property(e => e.Trangthai).HasColumnName("TRANGTHAI").HasMaxLength(50);

            entity.HasOne(d => d.MasvNavigation).WithMany()
                .HasForeignKey(d => d.Masv).HasConstraintName("FK_GOPY_SV");
        });

        modelBuilder.Entity<Danhgiasach>(entity =>
        {
            entity.ToTable("DANHGIASACH");
            entity.HasKey(e => e.Madanhgia);
            entity.Property(e => e.Madanhgia).HasColumnName("MADANHGIA");
            entity.Property(e => e.Masach).HasColumnName("MASACH");
            entity.Property(e => e.Masv).HasColumnName("MASV");
            entity.Property(e => e.Diem).HasColumnName("DIEM");
            entity.Property(e => e.Nhanxet).HasColumnName("NHANXET");
            entity.Property(e => e.Thoigian).HasColumnName("THOIGIAN").HasColumnType("datetime");

            entity.HasOne(d => d.MasachNavigation).WithMany()
                .HasForeignKey(d => d.Masach).HasConstraintName("FK_DGS_SACH");

            entity.HasOne(d => d.MasvNavigation).WithMany()
                .HasForeignKey(d => d.Masv).HasConstraintName("FK_DGS_SV");
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
