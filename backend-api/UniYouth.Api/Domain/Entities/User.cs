using System;
using System.Collections.Generic;

namespace UniYouth.Api.Domain.Entities;

public partial class User
{
    public int UserID { get; set; }

    public string Code { get; set; } = null!;

    public string FullName { get; set; } = null!;

    public string Email { get; set; } = null!;

    public string? Phone { get; set; }

    public string PasswordHash { get; set; } = null!;

    public string? AvatarUrl { get; set; }

    public bool? Gender { get; set; }

    public DateOnly? DateOfBirth { get; set; }

    public string? Address { get; set; }

    public byte? Status { get; set; }

    public DateTime? LastLoginDate { get; set; }

    public DateTime? CreatedDate { get; set; }

    public DateTime? UpdatedDate { get; set; }

    public virtual ICollection<ActivityPoint> ActivityPointAwardedByNavigations { get; set; } = new List<ActivityPoint>();

    public virtual ICollection<ActivityPoint> ActivityPointUsers { get; set; } = new List<ActivityPoint>();

    public virtual ICollection<Attendance> Attendances { get; set; } = new List<Attendance>();

    public virtual ICollection<AuditLog> AuditLogs { get; set; } = new List<AuditLog>();

    public virtual ICollection<EventQRCode> EventQRCodes { get; set; } = new List<EventQRCode>();

    public virtual ICollection<EventRegistration> EventRegistrations { get; set; } = new List<EventRegistration>();

    public virtual ICollection<Event> Events { get; set; } = new List<Event>();

    public virtual ICollection<FaceProfile> FaceProfiles { get; set; } = new List<FaceProfile>();

    public virtual ICollection<Notification> Notifications { get; set; } = new List<Notification>();

    public virtual ICollection<SystemSetting> SystemSettings { get; set; } = new List<SystemSetting>();

    public virtual ICollection<UserRole> UserRoles { get; set; } = new List<UserRole>();

    public virtual ICollection<UserUnit> UserUnits { get; set; } = new List<UserUnit>();
}

