using Microsoft.EntityFrameworkCore;
using UniYouth.Api.Domain.Entities;

namespace UniYouth.Api.Infrastructure.Data;

public partial class UniYouthDbContext
{
    public virtual DbSet<RefreshToken> RefreshTokens { get; set; } = null!;

    public virtual DbSet<PasswordResetToken> PasswordResetTokens { get; set; } = null!;

    public virtual DbSet<PasswordResetOtp> PasswordResetOtps { get; set; } = null!;

    public virtual DbSet<PasswordResetSession> PasswordResetSessions { get; set; } = null!;

    public virtual DbSet<UserNotificationPreference> UserNotificationPreferences { get; set; } = null!;

    public virtual DbSet<UserDeviceToken> UserDeviceTokens { get; set; } = null!;

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder)
    {
        ConfigureRefreshTokens(modelBuilder);

        modelBuilder.Entity<PasswordResetToken>(entity =>
        {
            entity.HasKey(e => e.Id);

            entity.ToTable("PasswordResetTokens");

            entity.HasIndex(e => e.Token, "UQ__PasswordResetTokens__Token").IsUnique();

            entity.HasIndex(e => e.UserID, "IX_PasswordResetTokens_UserID");

            entity.Property(e => e.Token)
                .HasMaxLength(200)
                .IsUnicode(true);

            entity.Property(e => e.ExpiredAt).HasColumnType("datetime");

            entity.Property(e => e.CreatedDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");

            entity.Property(e => e.IsUsed).HasDefaultValue(false);

            entity.HasOne(d => d.User)
                .WithMany(p => p.PasswordResetTokens)
                .HasForeignKey(d => d.UserID)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<PasswordResetOtp>(entity =>
        {
            entity.HasKey(e => e.OtpID)
                .HasName("PK_PasswordResetOtps");

            entity.ToTable("PasswordResetOtps");

            entity.HasIndex(e => new { e.UserID, e.Purpose, e.CreatedDate }, "IX_PasswordResetOtps_UserID_Purpose_CreatedDate");

            entity.HasIndex(e => new { e.UserID, e.IsUsed, e.ExpiresAt }, "IX_PasswordResetOtps_UserID_IsUsed_ExpiresAt");

            entity.HasIndex(e => e.ExpiresAt, "IX_PasswordResetOtps_ExpiresAt");

            entity.Property(e => e.OtpHash)
                .HasMaxLength(200)
                .IsUnicode(true);

            entity.Property(e => e.Purpose)
                .HasMaxLength(50)
                .IsUnicode(true);

            entity.Property(e => e.ExpiresAt).HasColumnType("datetime");

            entity.Property(e => e.AttemptCount).HasDefaultValue(0);

            entity.Property(e => e.MaxAttempts).HasDefaultValue(5);

            entity.Property(e => e.ResendCount).HasDefaultValue(0);

            entity.Property(e => e.MaxResends).HasDefaultValue(3);

            entity.Property(e => e.IsUsed).HasDefaultValue(false);

            entity.Property(e => e.VerifiedAt).HasColumnType("datetime");

            entity.Property(e => e.UsedAt).HasColumnType("datetime");

            entity.Property(e => e.RevokedAt).HasColumnType("datetime");

            entity.Property(e => e.CreatedDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");

            entity.Property(e => e.LastSentAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");

            entity.Property(e => e.RequestIp).HasMaxLength(64);

            entity.Property(e => e.RequestUserAgent).HasMaxLength(512);

            entity.HasOne(d => d.User)
                .WithMany(p => p.PasswordResetOtps)
                .HasForeignKey(d => d.UserID)
                .OnDelete(DeleteBehavior.Cascade)
                .HasConstraintName("FK_PasswordResetOtps_Users_UserID");
        });

        modelBuilder.Entity<PasswordResetSession>(entity =>
        {
            entity.HasKey(e => e.ResetSessionID)
                .HasName("PK_PasswordResetSessions");

            entity.ToTable("PasswordResetSessions");

            entity.HasIndex(e => e.SessionTokenHash, "UQ_PasswordResetSessions_SessionTokenHash")
                .IsUnique();

            entity.HasIndex(e => new { e.UserID, e.ExpiresAt, e.IsUsed }, "IX_PasswordResetSessions_UserID_ExpiresAt_IsUsed");

            entity.HasIndex(e => new { e.OtpID, e.IsUsed }, "IX_PasswordResetSessions_OtpID_IsUsed");

            entity.Property(e => e.SessionTokenHash)
                .HasMaxLength(200)
                .IsUnicode(true);

            entity.Property(e => e.ExpiresAt).HasColumnType("datetime");

            entity.Property(e => e.IsUsed).HasDefaultValue(false);

            entity.Property(e => e.CreatedDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");

            entity.Property(e => e.UsedAt).HasColumnType("datetime");

            entity.HasOne(d => d.User)
                .WithMany(p => p.PasswordResetSessions)
                .HasForeignKey(d => d.UserID)
                .OnDelete(DeleteBehavior.Cascade)
                .HasConstraintName("FK_PasswordResetSessions_Users_UserID");

            entity.HasOne(d => d.Otp)
                .WithMany()
                .HasForeignKey(d => d.OtpID)
                .OnDelete(DeleteBehavior.Cascade)
                .HasConstraintName("FK_PasswordResetSessions_PasswordResetOtps_OtpID");
        });

        modelBuilder.Entity<UserDeviceToken>(entity =>
        {
            entity.HasKey(e => e.UserDeviceTokenID)
                .HasName("PK_UserDeviceTokens");

            entity.ToTable("UserDeviceTokens");

            entity.HasIndex(e => new { e.Platform, e.Token }, "UQ_UserDeviceTokens_Platform_Token")
                .IsUnique();

            entity.HasIndex(e => new { e.UserID, e.IsActive }, "IX_UserDeviceTokens_UserID_IsActive");

            entity.Property(e => e.Platform)
                .HasMaxLength(20);

            entity.Property(e => e.Token)
                .HasMaxLength(512);

            entity.Property(e => e.DeviceId)
                .HasMaxLength(100);

            entity.Property(e => e.IsActive)
                .HasDefaultValue(true);

            entity.Property(e => e.LastSeenAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");

            entity.Property(e => e.CreatedDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");

            entity.Property(e => e.UpdatedDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");

            entity.HasOne(d => d.User)
                .WithMany(p => p.UserDeviceTokens)
                .HasForeignKey(d => d.UserID)
                .OnDelete(DeleteBehavior.Cascade)
                .HasConstraintName("FK_UserDeviceTokens_Users_UserID");
        });

        modelBuilder.Entity<UserNotificationPreference>(entity =>
        {
            entity.HasKey(e => e.PreferenceID)
                .HasName("PK_UserNotificationPreferences");

            entity.ToTable("UserNotificationPreferences");

            entity.HasIndex(e => new { e.UserID, e.NotificationTypeID }, "UQ_UserNotificationPreferences_UserID_NotificationTypeID")
                .IsUnique();

            entity.HasIndex(e => e.UserID, "IX_UserNotificationPreferences_UserID");

            entity.HasIndex(e => e.NotificationTypeID, "IX_UserNotificationPreferences_NotificationTypeID");

            entity.Property(e => e.IsInAppEnabled).HasDefaultValue(true);
            entity.Property(e => e.IsRealtimeEnabled).HasDefaultValue(true);
            entity.Property(e => e.IsPushEnabled).HasDefaultValue(true);
            entity.Property(e => e.IsMuted).HasDefaultValue(false);

            entity.Property(e => e.CreatedDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");

            entity.Property(e => e.UpdatedDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");

            entity.HasOne(d => d.User)
                .WithMany()
                .HasForeignKey(d => d.UserID)
                .OnDelete(DeleteBehavior.Cascade)
                .HasConstraintName("FK_UserNotificationPreferences_Users_UserID");

            entity.HasOne(d => d.NotificationType)
                .WithMany()
                .HasForeignKey(d => d.NotificationTypeID)
                .OnDelete(DeleteBehavior.Cascade)
                .HasConstraintName("FK_UserNotificationPreferences_NotificationType");
        });

        modelBuilder.Entity<LocationPreset>(entity =>
        {
            entity.HasKey(e => e.LocationPresetID).HasName("PK_LocationPresets");

            entity.ToTable("LocationPresets");

            entity.HasIndex(e => e.IsActive, "IX_LocationPresets_IsActive");
            entity.HasIndex(e => e.InstituteID, "IX_LocationPresets_InstituteID");
            entity.HasIndex(e => e.Name, "IX_LocationPresets_Name");

            entity.Property(e => e.Name).HasMaxLength(200);
            entity.Property(e => e.Address).HasMaxLength(500);
            entity.Property(e => e.Latitude).HasColumnType("decimal(10, 6)");
            entity.Property(e => e.Longitude).HasColumnType("decimal(10, 6)");
            entity.Property(e => e.IsActive).HasDefaultValue(true);
            entity.Property(e => e.CreatedDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.UpdatedDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
        });

        ConfigureSupportChat(modelBuilder);
    }

    private static void ConfigureRefreshTokens(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<RefreshToken>(entity =>
        {
            entity.HasKey(e => e.RefreshTokenID)
                .HasName("PK_RefreshTokens");

            entity.ToTable("RefreshTokens");

            entity.HasIndex(e => e.TokenHash, "UQ_RefreshTokens_TokenHash")
                .IsUnique();

            entity.HasIndex(e => new { e.UserID, e.RevokedAt, e.ExpiresAt }, "IX_RefreshTokens_UserID_RevokedAt_ExpiresAt");

            entity.Property(e => e.TokenHash)
                .HasMaxLength(128)
                .IsUnicode(false);

            entity.Property(e => e.ExpiresAt).HasColumnType("datetime");
            entity.Property(e => e.LastUsedAt).HasColumnType("datetime");
            entity.Property(e => e.RevokedAt).HasColumnType("datetime");

            entity.Property(e => e.ReplacedByTokenHash)
                .HasMaxLength(128)
                .IsUnicode(false);

            entity.Property(e => e.CreatedByIp).HasMaxLength(64);
            entity.Property(e => e.CreatedByUserAgent).HasMaxLength(512);
            entity.Property(e => e.RevokedByIp).HasMaxLength(64);
            entity.Property(e => e.RevokedByUserAgent).HasMaxLength(512);
            entity.Property(e => e.RevokedReason).HasMaxLength(255);

            entity.Property(e => e.CreatedDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");

            entity.Property(e => e.UpdatedDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");

            entity.HasOne(d => d.User)
                .WithMany(p => p.RefreshTokens)
                .HasForeignKey(d => d.UserID)
                .OnDelete(DeleteBehavior.Cascade)
                .HasConstraintName("FK_RefreshTokens_Users_UserID");
        });
    }
}
