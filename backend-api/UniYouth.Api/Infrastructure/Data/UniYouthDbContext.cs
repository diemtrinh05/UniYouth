using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;
using UniYouth.Api.Domain.Entities;

namespace UniYouth.Api.Infrastructure.Data;

public partial class UniYouthDbContext : DbContext
{
    public UniYouthDbContext(DbContextOptions<UniYouthDbContext> options)
        : base(options)
    {
    }

    public virtual DbSet<ActivityPoint> ActivityPoints { get; set; }

    public virtual DbSet<Attendance> Attendances { get; set; }

    public virtual DbSet<AuditLog> AuditLogs { get; set; }

    public virtual DbSet<Event> Events { get; set; }

    public virtual DbSet<EventImage> EventImages { get; set; }

    public virtual DbSet<EventPoint> EventPoints { get; set; }

    public virtual DbSet<EventQRCode> EventQRCodes { get; set; }

    public virtual DbSet<EventRegistration> EventRegistrations { get; set; }

    public virtual DbSet<EventType> EventTypes { get; set; }

    public virtual DbSet<FaceProfile> FaceProfiles { get; set; }

    public virtual DbSet<FaceRecognitionLog> FaceRecognitionLogs { get; set; }

    public virtual DbSet<Institute> Institutes { get; set; }

    public virtual DbSet<Notification> Notifications { get; set; }

    public virtual DbSet<NotificationArchive> NotificationArchives { get; set; }

    public virtual DbSet<NotificationDeliveryLog> NotificationDeliveryLogs { get; set; }

    public virtual DbSet<NotificationOutbox> NotificationOutboxes { get; set; }

    public virtual DbSet<NotificationType> NotificationTypes { get; set; }

    public virtual DbSet<Position> Positions { get; set; }

    public virtual DbSet<Role> Roles { get; set; }

    public virtual DbSet<SystemSetting> SystemSettings { get; set; }

    public virtual DbSet<Unit> Units { get; set; }

    public virtual DbSet<User> Users { get; set; }

    public virtual DbSet<UserRole> UserRoles { get; set; }

    public virtual DbSet<UserUnit> UserUnits { get; set; }

    public virtual DbSet<vw_EventAttendanceStat> vw_EventAttendanceStats { get; set; }

    public virtual DbSet<vw_UserTotalPoint> vw_UserTotalPoints { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<ActivityPoint>(entity =>
        {
            entity.HasKey(e => e.PointID).HasName("PK__Activity__40A977816D36EE4C");

            entity.HasIndex(e => e.EventID, "IX_ActivityPoints_EventID");

            entity.HasIndex(e => e.UserID, "IX_ActivityPoints_UserID");

            entity.Property(e => e.CreatedDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.PointType).HasMaxLength(50);

            entity.HasOne(d => d.AwardedByNavigation).WithMany(p => p.ActivityPointAwardedByNavigations)
                .HasForeignKey(d => d.AwardedBy)
                .HasConstraintName("FK__ActivityP__Award__208CD6FA");

            entity.HasOne(d => d.Event).WithMany(p => p.ActivityPoints)
                .HasForeignKey(d => d.EventID)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__ActivityP__Event__1DB06A4F");

            entity.HasOne(d => d.EventPoint).WithMany(p => p.ActivityPoints)
                .HasForeignKey(d => d.EventPointID)
                .HasConstraintName("FK__ActivityP__Event__1F98B2C1");

            entity.HasOne(d => d.User).WithMany(p => p.ActivityPointUsers)
                .HasForeignKey(d => d.UserID)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__ActivityP__UserI__1EA48E88");
        });

        modelBuilder.Entity<Attendance>(entity =>
        {
            entity.HasKey(e => e.AttendanceID).HasName("PK__Attendan__8B69263C133775C1");

            entity.HasIndex(e => e.CheckInTime, "IX_Attendances_CheckInTime");

            entity.HasIndex(e => e.EventID, "IX_Attendances_EventID");

            entity.HasIndex(e => new { e.EventID, e.RiskLevel, e.FaceVerificationStatus }, "IX_Attendances_EventID_RiskLevel_FaceVerificationStatus");

            entity.HasIndex(e => e.IsValid, "IX_Attendances_IsValid");

            entity.HasIndex(e => e.UserID, "IX_Attendances_UserID");

            entity.HasIndex(e => new { e.EventID, e.UserID }, "UQ__Attendan__A83C44BBDD097F01").IsUnique();

            entity.Property(e => e.CheckInMethod)
                .HasMaxLength(50)
                .HasDefaultValue("QR");
            entity.Property(e => e.CheckInTime)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.ClientDeviceId).HasMaxLength(128);
            entity.Property(e => e.CreatedDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.DeviceInfo).HasMaxLength(255);
            entity.Property(e => e.FaceVerificationProvider).HasMaxLength(50);
            entity.Property(e => e.FaceVerificationReason).HasMaxLength(255);
            entity.Property(e => e.FaceRetryCount).HasDefaultValue(0);
            entity.Property(e => e.FaceVerificationStatus).HasMaxLength(30);
            entity.Property(e => e.FaceVerificationVersion).HasMaxLength(50);
            entity.Property(e => e.FaceVerified).HasDefaultValue(false);
            entity.Property(e => e.IPAddress).HasMaxLength(50);
            entity.Property(e => e.InvalidReason).HasMaxLength(255);
            entity.Property(e => e.IsValid).HasDefaultValue(true);
            entity.Property(e => e.LivenessReason).HasMaxLength(255);
            entity.Property(e => e.RiskLevel).HasMaxLength(20);
            entity.Property(e => e.UserLatitude).HasColumnType("decimal(10, 6)");
            entity.Property(e => e.UserLongitude).HasColumnType("decimal(10, 6)");

            entity.HasOne(d => d.Event).WithMany(p => p.Attendances)
                .HasForeignKey(d => d.EventID)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__Attendanc__Event__05D8E0BE");

            entity.HasOne(d => d.QR).WithMany(p => p.Attendances)
                .HasForeignKey(d => d.QRID)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__Attendance__QRID__07C12930");

            entity.HasOne(d => d.User).WithMany(p => p.Attendances)
                .HasForeignKey(d => d.UserID)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__Attendanc__UserI__06CD04F7");
        });

        modelBuilder.Entity<AuditLog>(entity =>
        {
            entity.HasKey(e => e.AuditID).HasName("PK__AuditLog__A17F23B87B5FF2A2");

            entity.HasIndex(e => e.CreatedDate, "IX_AuditLogs_CreatedDate");

            entity.HasIndex(e => e.TableName, "IX_AuditLogs_TableName");

            entity.HasIndex(e => e.UserID, "IX_AuditLogs_UserID");

            entity.Property(e => e.Action).HasMaxLength(50);
            entity.Property(e => e.CreatedDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.IPAddress).HasMaxLength(50);
            entity.Property(e => e.TableName).HasMaxLength(100);
            entity.Property(e => e.UserAgent).HasMaxLength(255);

            entity.HasOne(d => d.User).WithMany(p => p.AuditLogs)
                .HasForeignKey(d => d.UserID)
                .HasConstraintName("FK__AuditLogs__UserI__2FCF1A8A");
        });

        modelBuilder.Entity<Event>(entity =>
        {
            entity.HasKey(e => e.EventID).HasName("PK__Events__7944C8701E4B3612");

            entity.HasIndex(e => e.CreatedBy, "IX_Events_CreatedBy");

            entity.HasIndex(e => e.InstituteID, "IX_Events_InstituteID");

            entity.HasIndex(e => new { e.Status, e.StartTime }, "IX_Events_Status_StartTime");

            entity.Property(e => e.AllowRadius).HasDefaultValue(100);
            entity.Property(e => e.CreatedDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.CurrentParticipants).HasDefaultValue(0);
            entity.Property(e => e.EndTime).HasColumnType("datetime");
            entity.Property(e => e.EventName).HasMaxLength(200);
            entity.Property(e => e.Latitude).HasColumnType("decimal(10, 6)");
            entity.Property(e => e.LocationName).HasMaxLength(200);
            entity.Property(e => e.Longitude).HasColumnType("decimal(10, 6)");
            entity.Property(e => e.RegistrationDeadline).HasColumnType("datetime");
            entity.Property(e => e.EnableFaceVerification).HasDefaultValue(false);
            entity.Property(e => e.StartTime).HasColumnType("datetime");
            entity.Property(e => e.Status).HasDefaultValue((byte)0);
            entity.Property(e => e.UpdatedDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");

            entity.HasOne(d => d.CreatedByNavigation).WithMany(p => p.Events)
                .HasForeignKey(d => d.CreatedBy)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__Events__CreatedB__628FA481");

            entity.HasOne(d => d.EventType).WithMany(p => p.Events)
                .HasForeignKey(d => d.EventTypeID)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__Events__EventTyp__6383C8BA");

            entity.HasOne(d => d.Institute).WithMany(p => p.Events)
                .HasForeignKey(d => d.InstituteID)
                .HasConstraintName("FK__Events__Institut__6477ECF3");
        });

        modelBuilder.Entity<EventImage>(entity =>
        {
            entity.HasKey(e => e.ImageID).HasName("PK__EventIma__7516F4EC6535771B");

            entity.HasIndex(e => e.EventID, "IX_EventImages_EventID");

            entity.Property(e => e.Caption).HasMaxLength(255);
            entity.Property(e => e.CreatedDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.DisplayOrder).HasDefaultValue(0);
            entity.Property(e => e.ImageType).HasMaxLength(50);
            entity.Property(e => e.ImageUrl).HasMaxLength(255);

            entity.HasOne(d => d.Event).WithMany(p => p.EventImages)
                .HasForeignKey(d => d.EventID)
                .HasConstraintName("FK__EventImag__Event__6B24EA82");
        });

        modelBuilder.Entity<EventPoint>(entity =>
        {
            entity.HasKey(e => e.EventPointID).HasName("PK__EventPoi__0F21E3FC30D73997");

            entity.HasIndex(e => e.EventID, "IX_EventPoints_EventID");

            entity.Property(e => e.CreatedDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.Description).HasMaxLength(255);
            entity.Property(e => e.RoleType).HasMaxLength(50);

            entity.HasOne(d => d.Event).WithMany(p => p.EventPoints)
                .HasForeignKey(d => d.EventID)
                .HasConstraintName("FK__EventPoin__Event__19DFD96B");
        });

        modelBuilder.Entity<EventQRCode>(entity =>
        {
            entity.HasKey(e => e.QRID).HasName("PK__EventQRC__D8E9E6F834F9BE41");

            entity.HasIndex(e => e.EventID, "IX_EventQRCodes_EventID");

            entity.HasIndex(e => e.QRToken, "IX_EventQRCodes_QRToken");

            entity.HasIndex(e => e.QRToken, "UQ__EventQRC__7CC967E53D20027C").IsUnique();

            entity.Property(e => e.CreatedDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.CurrentScans).HasDefaultValue(0);
            entity.Property(e => e.IsActive).HasDefaultValue(true);
            entity.Property(e => e.QRToken).HasMaxLength(255);
            entity.Property(e => e.UpdatedDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.ValidFrom).HasColumnType("datetime");
            entity.Property(e => e.ValidUntil).HasColumnType("datetime");

            entity.HasOne(d => d.CreatedByNavigation).WithMany(p => p.EventQRCodes)
                .HasForeignKey(d => d.CreatedBy)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__EventQRCo__Creat__7C4F7684");

            entity.HasOne(d => d.Event).WithMany(p => p.EventQRCodes)
                .HasForeignKey(d => d.EventID)
                .HasConstraintName("FK__EventQRCo__Event__7B5B524B");
        });

        modelBuilder.Entity<EventRegistration>(entity =>
        {
            entity.HasKey(e => e.RegistrationID).HasName("PK__EventReg__6EF58830E3B9E442");

            entity.HasIndex(e => e.EventID, "IX_EventRegistrations_EventID");

            entity.HasIndex(e => e.Status, "IX_EventRegistrations_Status");

            entity.HasIndex(e => e.UserID, "IX_EventRegistrations_UserID");

            entity.HasIndex(e => new { e.EventID, e.UserID }, "UQ__EventReg__A83C44BB5DC3F252").IsUnique();

            entity.Property(e => e.CancellationReason).HasMaxLength(255);
            entity.Property(e => e.CreatedDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.RegisterTime)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.Status).HasDefaultValue((byte)0);
            entity.Property(e => e.UpdatedDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");

            entity.HasOne(d => d.Event).WithMany(p => p.EventRegistrations)
                .HasForeignKey(d => d.EventID)
                .HasConstraintName("FK__EventRegi__Event__72C60C4A");

            entity.HasOne(d => d.User).WithMany(p => p.EventRegistrations)
                .HasForeignKey(d => d.UserID)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__EventRegi__UserI__73BA3083");
        });

        modelBuilder.Entity<EventType>(entity =>
        {
            entity.HasKey(e => e.TypeID).HasName("PK__EventTyp__516F03959E941232");

            entity.ToTable("EventType");

            entity.HasIndex(e => e.TypeName, "UQ__EventTyp__D4E7DFA8C708CE46").IsUnique();

            entity.Property(e => e.CreatedDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.Description).HasMaxLength(255);
            entity.Property(e => e.TypeName).HasMaxLength(200);
        });

        modelBuilder.Entity<FaceProfile>(entity =>
        {
            entity.HasKey(e => e.FaceProfileID).HasName("PK__FaceProf__FEEC36E3F358E81D");

            entity.HasIndex(e => new { e.UserID, e.IsActive }, "IX_FaceProfiles_UserID_IsActive");

            entity.HasIndex(e => e.UserID, "UX_FaceProfiles_UserID_Active")
                .IsUnique()
                .HasFilter("[IsActive] = 1");

            entity.Property(e => e.Algorithm)
                .HasMaxLength(50)
                .HasDefaultValue("ArcFace");
            entity.Property(e => e.CreatedDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.ImageUrl).HasMaxLength(255);
            entity.Property(e => e.IsActive).HasDefaultValue(true);
            entity.Property(e => e.UpdatedDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.Version)
                .HasMaxLength(20)
                .HasDefaultValue("1.0");

            entity.HasOne(d => d.User).WithMany(p => p.FaceProfiles)
                .HasForeignKey(d => d.UserID)
                .HasConstraintName("FK__FaceProfi__UserI__0F624AF8");
        });

        modelBuilder.Entity<FaceRecognitionLog>(entity =>
        {
            entity.HasKey(e => e.FaceLogID).HasName("PK__FaceReco__F3321BC6F5E3B585");

            entity.HasIndex(e => e.AttendanceID, "IX_FaceRecognitionLogs_AttendanceID");

            entity.HasIndex(e => e.IsMatched, "IX_FaceRecognitionLogs_IsMatched");

            entity.Property(e => e.CapturedImageUrl).HasMaxLength(255);
            entity.Property(e => e.CreatedDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.ErrorCode).HasMaxLength(50);
            entity.Property(e => e.ErrorMessage).HasMaxLength(255);
            entity.Property(e => e.IsMatched).HasDefaultValue(false);
            entity.Property(e => e.Model).HasMaxLength(50);
            entity.Property(e => e.Provider).HasMaxLength(50);
            entity.Property(e => e.Threshold).HasDefaultValue(0.69999999999999996);
            entity.Property(e => e.VerificationStatus).HasMaxLength(30);

            entity.HasOne(d => d.Attendance).WithMany(p => p.FaceRecognitionLogs)
                .HasForeignKey(d => d.AttendanceID)
                .HasConstraintName("FK__FaceRecog__Atten__151B244E");

            entity.HasOne(d => d.FaceProfile).WithMany(p => p.FaceRecognitionLogs)
                .HasForeignKey(d => d.FaceProfileID)
                .HasConstraintName("FK__FaceRecog__FaceP__160F4887");
        });

        modelBuilder.Entity<Institute>(entity =>
        {
            entity.HasKey(e => e.InstituteID).HasName("PK__Institut__09EC0D9B9FE2C5CA");

            entity.Property(e => e.ContactEmail).HasMaxLength(100);
            entity.Property(e => e.CreatedDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.Description).HasMaxLength(255);
            entity.Property(e => e.InstituteName).HasMaxLength(150);
            entity.Property(e => e.Status).HasDefaultValue((byte)1);
            entity.Property(e => e.UpdatedDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
        });

        modelBuilder.Entity<Notification>(entity =>
        {
            entity.HasKey(e => e.NotificationID).HasName("PK__Notifica__20CF2E32168176E0");

            entity.HasIndex(e => e.CreatedDate, "IX_Notifications_CreatedDate");

            entity.HasIndex(e => e.DedupKey, "UX_Notifications_DedupKey_NotNull")
                .IsUnique()
                .HasFilter("([DedupKey] IS NOT NULL)");

            entity.HasIndex(e => new { e.UserID, e.IsRead }, "IX_Notifications_UserID_IsRead");

            entity.Property(e => e.ActionUrl).HasMaxLength(255);
            entity.Property(e => e.Audience).HasMaxLength(30);
            entity.Property(e => e.CreatedDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.DedupKey).HasMaxLength(200);
            entity.Property(e => e.ExpiryDate).HasColumnType("datetime");
            entity.Property(e => e.IsRead).HasDefaultValue(false);
            entity.Property(e => e.Priority).HasDefaultValue((byte)0);
            entity.Property(e => e.ReadDate).HasColumnType("datetime");
            entity.Property(e => e.TargetRole).HasMaxLength(50);
            entity.Property(e => e.Title).HasMaxLength(200);

            entity.HasOne(d => d.Event).WithMany(p => p.Notifications)
                .HasForeignKey(d => d.EventID)
                .OnDelete(DeleteBehavior.SetNull)
                .HasConstraintName("FK__Notificat__Event__2B0A656D");

            entity.HasOne(d => d.NotificationType).WithMany(p => p.Notifications)
                .HasForeignKey(d => d.NotificationTypeID)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__Notificat__Notif__2BFE89A6");

            entity.HasOne(d => d.User).WithMany(p => p.Notifications)
                .HasForeignKey(d => d.UserID)
                .HasConstraintName("FK__Notificat__UserI__2A164134");
        });

        modelBuilder.Entity<NotificationArchive>(entity =>
        {
            entity.HasKey(e => e.NotificationID).HasName("PK_NotificationArchive");

            entity.ToTable("NotificationArchive");

            entity.HasIndex(e => e.ArchivedDate, "IX_NotificationArchive_ArchivedDate");

            entity.HasIndex(e => e.CreatedDate, "IX_NotificationArchive_CreatedDate");

            entity.HasIndex(e => e.UserID, "IX_NotificationArchive_UserID");

            entity.Property(e => e.ActionUrl).HasMaxLength(255);
            entity.Property(e => e.ArchiveReason).HasMaxLength(255);
            entity.Property(e => e.ArchivedDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.Audience).HasMaxLength(30);
            entity.Property(e => e.CreatedDate).HasColumnType("datetime");
            entity.Property(e => e.DedupKey).HasMaxLength(200);
            entity.Property(e => e.ExpiryDate).HasColumnType("datetime");
            entity.Property(e => e.ReadDate).HasColumnType("datetime");
            entity.Property(e => e.TargetRole).HasMaxLength(50);
            entity.Property(e => e.Title).HasMaxLength(200);
        });

        modelBuilder.Entity<NotificationDeliveryLog>(entity =>
        {
            entity.HasKey(e => e.DeliveryLogID).HasName("PK_NotificationDeliveryLog");

            entity.ToTable("NotificationDeliveryLog");

            entity.HasIndex(e => e.CreatedDate, "IX_NotificationDeliveryLog_CreatedDate");

            entity.HasIndex(e => e.NotificationID, "IX_NotificationDeliveryLog_NotificationID");

            entity.HasIndex(e => e.OutboxID, "IX_NotificationDeliveryLog_OutboxID");

            entity.Property(e => e.CreatedDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.ErrorMessage).HasMaxLength(1000);

            entity.HasOne(d => d.Notification).WithMany()
                .HasForeignKey(d => d.NotificationID)
                .OnDelete(DeleteBehavior.NoAction)
                .HasConstraintName("FK_NotificationDeliveryLog_Notification");

            entity.HasOne(d => d.Outbox).WithMany(p => p.NotificationDeliveryLogs)
                .HasForeignKey(d => d.OutboxID)
                .OnDelete(DeleteBehavior.Cascade)
                .HasConstraintName("FK_NotificationDeliveryLog_Outbox");
        });

        modelBuilder.Entity<NotificationOutbox>(entity =>
        {
            entity.HasKey(e => e.OutboxID).HasName("PK_NotificationOutbox");

            entity.ToTable("NotificationOutbox");

            entity.HasIndex(e => e.NotificationID, "IX_NotificationOutbox_NotificationID");

            entity.HasIndex(e => new { e.NotificationID, e.Channel }, "UX_NotificationOutbox_Notification_Channel")
                .IsUnique();

            entity.HasIndex(e => new { e.Status, e.NextAttemptAt }, "IX_NotificationOutbox_Status_NextAttemptAt");

            entity.HasIndex(e => e.UserID, "IX_NotificationOutbox_UserID");

            entity.Property(e => e.AttemptCount).HasDefaultValue(0);
            entity.Property(e => e.CreatedDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.LastAttemptAt).HasColumnType("datetime");
            entity.Property(e => e.LastError).HasMaxLength(1000);
            entity.Property(e => e.MaxAttempts).HasDefaultValue(5);
            entity.Property(e => e.NextAttemptAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.ProcessedAt).HasColumnType("datetime");
            entity.Property(e => e.Status).HasDefaultValue((byte)0);
            entity.Property(e => e.UpdatedDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");

            entity.HasOne(d => d.Notification).WithMany()
                .HasForeignKey(d => d.NotificationID)
                .OnDelete(DeleteBehavior.Cascade)
                .HasConstraintName("FK_NotificationOutbox_Notification");

            entity.HasOne<User>().WithMany()
                .HasForeignKey(d => d.UserID)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_NotificationOutbox_User");
        });

        modelBuilder.Entity<NotificationType>(entity =>
        {
            entity.HasKey(e => e.TypeID).HasName("PK__Notifica__516F0395F3A72592");

            entity.ToTable("NotificationType");

            entity.HasIndex(e => e.TypeName, "UQ__Notifica__D4E7DFA84C058C88").IsUnique();

            entity.Property(e => e.CreatedDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.Locale).HasMaxLength(10);
            entity.Property(e => e.TemplateVersion).HasDefaultValue(1);
            entity.Property(e => e.TypeName).HasMaxLength(200);
        });

        modelBuilder.Entity<Position>(entity =>
        {
            entity.HasKey(e => e.PositionID).HasName("PK__Positions__60BB9A59EFD0D9BE");

            entity.HasIndex(e => e.PositionCode, "UQ__Positions__CC3DA237DE2E5D69").IsUnique();

            entity.HasIndex(e => e.UnitID, "IX_Positions_UnitID");

            entity.HasIndex(e => new { e.UnitID, e.PositionName }, "UQ__Positions__UnitID_PositionName").IsUnique();

            entity.Property(e => e.CreatedDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.IsActive).HasDefaultValue((byte)1);
            entity.Property(e => e.PositionCode).HasMaxLength(50);
            entity.Property(e => e.PositionName).HasMaxLength(100);
            entity.Property(e => e.SortOrder).HasDefaultValue(0);
            entity.Property(e => e.UpdatedDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");

            entity.HasOne(d => d.Unit).WithMany(p => p.Positions)
                .HasForeignKey(d => d.UnitID)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__Positions__UnitI__6A30C649");
        });

        modelBuilder.Entity<Role>(entity =>
        {
            entity.HasKey(e => e.RoleID).HasName("PK__Roles__8AFACE3A40B3E135");

            entity.HasIndex(e => e.RoleName, "UQ__Roles__8A2B6160CE2EF755").IsUnique();

            entity.Property(e => e.CreatedDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.RoleName).HasMaxLength(50);
        });

        modelBuilder.Entity<SystemSetting>(entity =>
        {
            entity.HasKey(e => e.SettingID).HasName("PK__SystemSe__54372AFD733AAC6F");

            entity.HasIndex(e => e.SettingKey, "UQ__SystemSe__01E719AD4C0D81A2").IsUnique();

            entity.Property(e => e.DataType)
                .HasMaxLength(50)
                .HasDefaultValue("string");
            entity.Property(e => e.Description).HasMaxLength(255);
            entity.Property(e => e.SettingKey).HasMaxLength(100);
            entity.Property(e => e.UpdatedDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");

            entity.HasOne(d => d.UpdatedByNavigation).WithMany(p => p.SystemSettings)
                .HasForeignKey(d => d.UpdatedBy)
                .HasConstraintName("FK__SystemSet__Updat__3587F3E0");
        });

        modelBuilder.Entity<Unit>(entity =>
        {
            entity.HasKey(e => e.UnitID).HasName("PK__Units__44F5EC95F1B4A3B0");

            entity.HasIndex(e => e.InstituteID, "IX_Units_InstituteID");

            entity.Property(e => e.CreatedDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.Description).HasMaxLength(255);
            entity.Property(e => e.Status).HasDefaultValue((byte)1);
            entity.Property(e => e.UnitName).HasMaxLength(100);
            entity.Property(e => e.UnitType).HasMaxLength(50);
            entity.Property(e => e.UpdatedDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");

            entity.HasOne(d => d.Institute).WithMany(p => p.Units)
                .HasForeignKey(d => d.InstituteID)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__Units__Institute__4F7CD00D");

            entity.HasOne(d => d.ParentUnit).WithMany(p => p.InverseParentUnit)
                .HasForeignKey(d => d.ParentUnitID)
                .HasConstraintName("FK__Units__ParentUni__5070F446");
        });

        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(e => e.UserID).HasName("PK__Users__1788CCAC906271F5");

            entity.HasIndex(e => e.Status, "IX_Users_Status");

            entity.HasIndex(e => e.FullName, "IX_Users_FullName");

            entity.HasIndex(e => e.Code, "UQ__Users__1FC88604054AAE80").IsUnique();

            entity.HasIndex(e => e.Email, "UQ__Users__A9D105346B81BCAA").IsUnique();

            entity.Property(e => e.Address).HasMaxLength(255);
            entity.Property(e => e.AvatarUrl).HasMaxLength(255);
            entity.Property(e => e.CreatedDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.Email).HasMaxLength(100);
            entity.Property(e => e.FullName).HasMaxLength(100);
            entity.Property(e => e.LastLoginDate).HasColumnType("datetime");
            entity.Property(e => e.PasswordHash).HasMaxLength(255);
            entity.Property(e => e.Phone).HasMaxLength(20);
            entity.Property(e => e.Status).HasDefaultValue((byte)1);
            entity.Property(e => e.Code).HasMaxLength(20);
            entity.Property(e => e.UpdatedDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
        });

        modelBuilder.Entity<UserRole>(entity =>
        {
            entity.HasKey(e => e.UserRoleID).HasName("PK__UserRole__3D978A55A4314293");

            entity.HasIndex(e => e.RoleID, "IX_UserRoles_RoleID");

            entity.HasIndex(e => e.UserID, "IX_UserRoles_UserID");

            entity.HasIndex(e => new { e.UserID, e.RoleID }, "UQ__UserRole__AF27604EA7094FF2").IsUnique();

            entity.Property(e => e.AssignDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");

            entity.HasOne(d => d.Role).WithMany(p => p.UserRoles)
                .HasForeignKey(d => d.RoleID)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__UserRoles__RoleI__44FF419A");

            entity.HasOne(d => d.User).WithMany(p => p.UserRoles)
                .HasForeignKey(d => d.UserID)
                .HasConstraintName("FK__UserRoles__UserI__440B1D61");
        });

        modelBuilder.Entity<UserUnit>(entity =>
        {
            entity.HasKey(e => e.UserUnitID).HasName("PK__UserUnit__2DC94419A289636A");

            entity.HasIndex(e => e.PositionID, "IX_UserUnits_PositionID");

            entity.HasIndex(e => e.UnitID, "IX_UserUnits_UnitID");

            entity.HasIndex(e => e.UserID, "IX_UserUnits_UserID");

            entity.Property(e => e.CreatedDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.Position).HasMaxLength(50);
            entity.Property(e => e.Status).HasDefaultValue((byte)1);
            entity.Property(e => e.UpdatedDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");

            entity.HasOne(d => d.PositionNavigation).WithMany(p => p.UserUnits)
                .HasForeignKey(d => d.PositionID)
                .HasConstraintName("FK__UserUnits__Posit__5812160E");

            entity.HasOne(d => d.Unit).WithMany(p => p.UserUnits)
                .HasForeignKey(d => d.UnitID)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__UserUnits__UnitI__571DF1D5");

            entity.HasOne(d => d.User).WithMany(p => p.UserUnits)
                .HasForeignKey(d => d.UserID)
                .HasConstraintName("FK__UserUnits__UserI__5629CD9C");
        });

        modelBuilder.Entity<vw_EventAttendanceStat>(entity =>
        {
            entity
                .HasNoKey()
                .ToView("vw_EventAttendanceStats");

            entity.Property(e => e.AttendanceRate).HasColumnType("decimal(5, 2)");
            entity.Property(e => e.EventName).HasMaxLength(200);
            entity.Property(e => e.StartTime).HasColumnType("datetime");
        });

        modelBuilder.Entity<vw_UserTotalPoint>(entity =>
        {
            entity
                .HasNoKey()
                .ToView("vw_UserTotalPoints");

            entity.Property(e => e.FullName).HasMaxLength(100);
            entity.Property(e => e.Code).HasMaxLength(20);
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}

