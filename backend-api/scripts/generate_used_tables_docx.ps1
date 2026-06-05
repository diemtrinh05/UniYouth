param(
    [string]$OutputPath = "USED_DATABASE_TABLE_DESIGN.docx",
    [ValidateSet("en", "vi")]
    [string]$Language = "en"
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$apiRoot = Join-Path $repoRoot "UniYouth.Api"
$entityRoot = Join-Path $apiRoot "Domain\Entities"
$dbContextFiles = @(
    (Join-Path $apiRoot "Infrastructure\Data\UniYouthDbContext.cs"),
    (Join-Path $apiRoot "Infrastructure\Data\UniYouthDbContext.PasswordResetTokens.cs"),
    (Join-Path $apiRoot "Infrastructure\Data\UniYouthDbContext.LocationPresets.cs")
) | Where-Object { Test-Path $_ }

$usedEntities = @(
    "ActivityPoint",
    "Attendance",
    "AuditLog",
    "Event",
    "EventImage",
    "EventPoint",
    "EventQRCode",
    "EventRegistration",
    "EventType",
    "FaceProfile",
    "FaceRecognitionLog",
    "Institute",
    "LocationPreset",
    "Notification",
    "NotificationArchive",
    "NotificationDeliveryLog",
    "NotificationOutbox",
    "NotificationType",
    "PasswordResetOtp",
    "PasswordResetSession",
    "PasswordResetToken",
    "RefreshToken",
    "Role",
    "Unit",
    "User",
    "UserDeviceToken",
    "UserNotificationPreference",
    "UserRole",
    "UserUnit"
)

function Escape-Xml {
    param([AllowNull()][string]$Text)
    if ($null -eq $Text) { return "" }
    return [System.Security.SecurityElement]::Escape($Text)
}

function Split-Name {
    param([string]$Name)
    if ([string]::IsNullOrWhiteSpace($Name)) { return $Name }
    $spaced = [System.Text.RegularExpressions.Regex]::Replace($Name, '([a-z0-9])([A-Z])', '$1 $2')
    return $spaced.Replace("ID", " ID").Replace("QR ", "QR ")
}

function Get-TableContext {
    param(
        [string]$TableName,
        [string]$Language
    )

    $mapEn = @{
        "ActivityPoints" = "activity point transaction"
        "Attendances" = "attendance record"
        "AuditLogs" = "audit log entry"
        "Events" = "event"
        "EventImages" = "event image"
        "EventPoints" = "event point rule"
        "EventQRCodes" = "event QR code"
        "EventRegistrations" = "event registration"
        "EventTypes" = "event type"
        "FaceProfiles" = "face profile"
        "FaceRecognitionLogs" = "face recognition log"
        "Institutes" = "institute"
        "LocationPresets" = "location preset"
        "Notifications" = "notification"
        "NotificationArchives" = "archived notification"
        "NotificationDeliveryLogs" = "notification delivery log"
        "NotificationOutboxes" = "notification outbox item"
        "NotificationTypes" = "notification type"
        "PasswordResetOtps" = "password reset OTP record"
        "PasswordResetSessions" = "password reset session"
        "PasswordResetTokens" = "password reset token"
        "RefreshTokens" = "refresh token"
        "Roles" = "role"
        "Units" = "unit"
        "Users" = "user account"
        "UserDeviceTokens" = "user device token"
        "UserNotificationPreferences" = "user notification preference"
        "UserRoles" = "user-role assignment"
        "UserUnits" = "user-unit assignment"
    }

    $mapVi = @{
        "ActivityPoints" = "giao dịch cộng điểm hoạt động"
        "Attendances" = "bản ghi điểm danh"
        "AuditLogs" = "bản ghi nhật ký hệ thống"
        "Events" = "sự kiện"
        "EventImages" = "ảnh sự kiện"
        "EventPoints" = "quy tắc cộng điểm của sự kiện"
        "EventQRCodes" = "mã QR của sự kiện"
        "EventRegistrations" = "bản ghi đăng ký sự kiện"
        "EventTypes" = "loại sự kiện"
        "FaceProfiles" = "hồ sơ khuôn mặt"
        "FaceRecognitionLogs" = "nhật ký nhận diện khuôn mặt"
        "Institutes" = "viện"
        "LocationPresets" = "vị trí định sẵn"
        "Notifications" = "thông báo"
        "NotificationArchives" = "thông báo lưu trữ"
        "NotificationDeliveryLogs" = "nhật ký gửi thông báo"
        "NotificationOutboxes" = "bản ghi hàng đợi gửi thông báo"
        "NotificationTypes" = "loại thông báo"
        "PasswordResetOtps" = "bản ghi OTP đặt lại mật khẩu"
        "PasswordResetSessions" = "phiên đặt lại mật khẩu"
        "PasswordResetTokens" = "token đặt lại mật khẩu"
        "RefreshTokens" = "refresh token đăng nhập"
        "Roles" = "vai trò"
        "Units" = "đơn vị"
        "Users" = "tài khoản người dùng"
        "UserDeviceTokens" = "token thiết bị người dùng"
        "UserNotificationPreferences" = "cấu hình nhận thông báo của người dùng"
        "UserRoles" = "bản ghi gán vai trò cho người dùng"
        "UserUnits" = "bản ghi gán đơn vị cho người dùng"
    }

    if ($Language -eq "vi") {
        if ($mapVi.ContainsKey($TableName)) { return $mapVi[$TableName] }
        return "bản ghi " + $TableName
    }

    if ($mapEn.ContainsKey($TableName)) { return $mapEn[$TableName] }
    return "record in $TableName"
}

function Get-FkDescription {
    param(
        [string]$TableName,
        [string]$FieldName,
        [string]$Language
    )

    $context = Get-TableContext -TableName $TableName -Language $Language

    if ($Language -eq "vi") {
        switch ($FieldName) {
            "UserID" { return "Tham chiếu tới người dùng liên quan đến $context." }
            "EventID" { return "Tham chiếu tới sự kiện liên quan đến $context." }
            "RoleID" { return "Tham chiếu tới vai trò được gán trong $context." }
            "UnitID" { return "Tham chiếu tới đơn vị liên quan đến $context." }
            "InstituteID" { return "Tham chiếu tới viện sở hữu hoặc sử dụng $context." }
            "QRID" { return "Tham chiếu tới mã QR được dùng cho bản ghi điểm danh." }
            "AttendanceID" { return "Tham chiếu tới bản ghi điểm danh liên quan." }
            "FaceProfileID" { return "Tham chiếu tới hồ sơ khuôn mặt dùng để so sánh hoặc xác minh." }
            "EventPointID" { return "Tham chiếu tới cấu hình điểm của sự kiện dùng để cộng điểm." }
            "NotificationID" { return "Tham chiếu tới thông báo gốc liên quan." }
            "NotificationTypeID" { return "Tham chiếu tới loại thông báo được áp dụng." }
            "OutboxID" { return "Tham chiếu tới bản ghi hàng đợi gửi thông báo." }
            "OtpID" { return "Tham chiếu tới OTP đã xác minh dùng để tạo phiên đặt lại mật khẩu." }
            "ParentUnitID" { return "Tham chiếu tới đơn vị cha của đơn vị hiện tại." }
            "CreatedBy" { return "Tham chiếu tới người dùng đã tạo $context." }
            "AwardedBy" { return "Tham chiếu tới người dùng đã thực hiện việc cộng điểm." }
            "UpdatedBy" { return "Tham chiếu tới người dùng cập nhật cấu hình này lần cuối." }
            default {
                $related = Split-Name ($FieldName -replace 'Id$', '' -replace 'ID$', '')
                return "Khóa ngoại tham chiếu tới bản ghi $related liên quan."
            }
        }
    }

    switch ($FieldName) {
        "UserID" { return "References the user associated with this $context." }
        "EventID" { return "References the event associated with this $context." }
        "RoleID" { return "References the role assigned in this $context." }
        "UnitID" { return "References the unit associated with this $context." }
        "InstituteID" { return "References the institute that owns or uses this $context." }
        "QRID" { return "References the QR code used for this attendance record." }
        "AttendanceID" { return "References the related attendance record." }
        "FaceProfileID" { return "References the face profile used for comparison or verification." }
        "EventPointID" { return "References the event point configuration used for awarding points." }
        "NotificationID" { return "References the source notification record." }
        "NotificationTypeID" { return "References the notification type applied to this record." }
        "OutboxID" { return "References the notification outbox item." }
        "OtpID" { return "References the verified OTP used to create this password reset session." }
        "ParentUnitID" { return "References the parent unit of the current unit." }
        "CreatedBy" { return "References the user who created this $context." }
        "AwardedBy" { return "References the user who granted the activity points." }
        "UpdatedBy" { return "References the user who last updated this setting." }
        default {
            $related = Split-Name ($FieldName -replace 'Id$', '' -replace 'ID$', '')
            return "Foreign key referencing the related $related record."
        }
    }
}

function Get-BusinessDescription {
    param(
        [string]$TableName,
        [string]$FieldName,
        [string]$Language
    )

    $key = "$TableName.$FieldName"

    $mapEn = @{
        "Users.Code" = "Stores the user code used as the main identity in the university workflow."
        "Users.FullName" = "Stores the full name shown on attendance, registration, and admin screens."
        "Users.Email" = "Stores the email address used for login, notifications, and account recovery."
        "Users.PasswordHash" = "Stores the hashed password for authentication."
        "Users.Status" = "Stores the current account status, such as active or inactive."

        "Events.EventName" = "Stores the display name of the event."
        "Events.Description" = "Stores the event description shown to participants and administrators."
        "Events.StartTime" = "Stores the scheduled start time of the event."
        "Events.EndTime" = "Stores the scheduled end time of the event."
        "Events.LocationName" = "Stores the name of the event location."
        "Events.Latitude" = "Stores the latitude of the event check-in location."
        "Events.Longitude" = "Stores the longitude of the event check-in location."
        "Events.AllowRadius" = "Stores the maximum GPS distance allowed for a valid event check-in."
        "Events.MaxParticipants" = "Stores the maximum number of participants allowed for the event."
        "Events.CurrentParticipants" = "Stores the current number of participants in the event."
        "Events.Status" = "Stores the lifecycle status of the event, such as draft, open, ongoing, or closed."
        "Events.EnableFaceVerification" = "Indicates whether the event requires face verification during check-in."
        "Events.RegistrationDeadline" = "Stores the deadline for event registration."

        "Attendances.CheckInTime" = "Stores the exact date and time when the user checked in."
        "Attendances.CheckInMethod" = "Stores the check-in method, such as QR, GPS, or QR_GPS."
        "Attendances.UserLatitude" = "Stores the GPS latitude sent from the user's device during check-in."
        "Attendances.UserLongitude" = "Stores the GPS longitude sent from the user's device during check-in."
        "Attendances.DistanceFromEvent" = "Stores the calculated distance between the user position and the event location."
        "Attendances.IsValid" = "Indicates whether the attendance is considered valid after QR, GPS, and fraud checks."
        "Attendances.InvalidReason" = "Stores the reason why the attendance was marked invalid."
        "Attendances.FaceVerified" = "Indicates whether face verification passed for this attendance."
        "Attendances.FaceVerificationScore" = "Stores the face matching confidence score returned by the face engine."
        "Attendances.FaceVerificationStatus" = "Stores the normalized face verification status, such as Matched, Review, or Mismatch."
        "Attendances.FaceVerificationReason" = "Stores the explanation returned for the face verification result."
        "Attendances.LivenessPassed" = "Indicates whether liveness verification passed."
        "Attendances.LivenessScore" = "Stores the liveness score returned by the anti-spoofing service."
        "Attendances.LivenessReason" = "Stores the explanation returned for the liveness result."
        "Attendances.RiskLevel" = "Stores the normalized fraud risk level of the attendance."
        "Attendances.RiskScore" = "Stores the numeric fraud risk score used for suspicious review."
        "Attendances.FaceRetryCount" = "Stores how many face verification retries were attempted during the attendance flow."

        "LocationPresets.Name" = "Stores the display name of the predefined location preset."
        "LocationPresets.Address" = "Stores the human-readable address of the preset location."
        "LocationPresets.Latitude" = "Stores the latitude of the preset location."
        "LocationPresets.Longitude" = "Stores the longitude of the preset location."
        "LocationPresets.RadiusMeters" = "Stores the default radius suggestion, in meters, when this preset is used for an event."
        "LocationPresets.IsActive" = "Indicates whether this location preset can still be selected in admin flows."

        "FaceProfiles.FaceEmbedding" = "Stores the face embedding vector used for face verification."
        "FaceProfiles.ImageUrl" = "Stores the image path of the enrolled face sample."
        "FaceProfiles.Algorithm" = "Stores the face recognition algorithm used to generate the embedding."
        "FaceProfiles.Version" = "Stores the version of the face profile generation pipeline."
        "FaceProfiles.IsActive" = "Indicates whether the face profile is the active reference for verification."
        "FaceProfiles.QualityScore" = "Stores the quality score of the enrolled face sample."

        "ActivityPoints.Points" = "Stores the number of activity points awarded or deducted for this transaction."
        "ActivityPoints.PointType" = "Stores the business category of the point transaction, such as attendance, bonus, or manual adjustment."

        "Attendances.Distance" = "Stores the calculated distance between the participant position and the event check-in location."
        "Attendances.FaceConfidence" = "Stores the face matching confidence score returned during attendance verification."
        "Attendances.FaceVerificationProvider" = "Stores the face engine provider that produced the verification result."
        "Attendances.FaceVerificationVersion" = "Stores the version of the face verification pipeline used for this attendance."
        "Attendances.RiskReasonsJson" = "Stores the detailed fraud rule hits in JSON format for audit and suspicious review."
        "Attendances.IPAddress" = "Stores the client IP address captured at check-in time."
        "Attendances.DeviceInfo" = "Stores a short description of the device used for the check-in."
        "Attendances.ClientDeviceId" = "Stores the application-level device identifier used to correlate suspicious check-ins."

        "AuditLogs.Action" = "Stores the action performed by the user or system, such as create, update, delete, or login."
        "AuditLogs.TableName" = "Stores the name of the business table affected by the audited action."
        "AuditLogs.RecordID" = "Stores the identifier of the business record affected by the audited action."
        "AuditLogs.OldValue" = "Stores the serialized data before the audited change was applied."
        "AuditLogs.NewValue" = "Stores the serialized data after the audited change was applied."
        "AuditLogs.IPAddress" = "Stores the IP address from which the audited action was made."
        "AuditLogs.UserAgent" = "Stores the browser or client user agent associated with the audited action."

        "EventImages.ImageUrl" = "Stores the image path used for the event banner, gallery, or supporting media."
        "EventImages.ImageType" = "Stores the business role of the image, such as cover or gallery."
        "EventImages.Caption" = "Stores the caption or short note shown with the event image."
        "EventImages.DisplayOrder" = "Stores the display order of the image in event media lists."

        "EventPoints.RoleType" = "Stores the participant role that this point rule applies to, such as student or organizer."
        "EventPoints.Points" = "Stores the number of points granted when the rule is applied."

        "EventQRCodes.QRToken" = "Stores the token encoded into the QR code used for event check-in."
        "EventQRCodes.ValidFrom" = "Stores the start time from which the QR code can be used."
        "EventQRCodes.ValidUntil" = "Stores the end time after which the QR code is no longer valid."
        "EventQRCodes.ScanLimit" = "Stores the maximum number of scans allowed for this QR code."
        "EventQRCodes.CurrentScans" = "Stores the number of scans already performed with this QR code."

        "EventRegistrations.RegisterTime" = "Stores the time when the user registered for the event."
        "EventRegistrations.Status" = "Stores the registration status, such as pending, approved, cancelled, or rejected."
        "EventRegistrations.CancellationReason" = "Stores the reason why the registration was cancelled or rejected."

        "EventTypes.TypeName" = "Stores the display name of the event category."

        "FaceRecognitionLogs.SimilarityScore" = "Stores the raw similarity score returned by the face comparison engine."
        "FaceRecognitionLogs.Threshold" = "Stores the matching threshold used to decide whether the face comparison passes."
        "FaceRecognitionLogs.IsMatched" = "Indicates whether the face engine considered the compared faces a match."
        "FaceRecognitionLogs.ProcessingTime" = "Stores the processing time of the face verification request."
        "FaceRecognitionLogs.VerificationStatus" = "Stores the normalized verification status recorded for audit purposes."
        "FaceRecognitionLogs.Provider" = "Stores the provider or service that produced the face verification result."
        "FaceRecognitionLogs.Model" = "Stores the model name used for face verification."
        "FaceRecognitionLogs.ErrorCode" = "Stores the technical error code returned when face verification fails."
        "FaceRecognitionLogs.CapturedImageUrl" = "Stores the saved path of the captured face image used during verification."
        "FaceRecognitionLogs.ErrorMessage" = "Stores the technical error message returned by the face verification flow."

        "Institutes.InstituteName" = "Stores the official name of the institute that owns users, units, and events."
        "Institutes.Description" = "Stores the institute description shown in administration flows."
        "Institutes.ContactEmail" = "Stores the main contact email of the institute."
        "Institutes.Status" = "Stores whether the institute is active and allowed to operate in the system."

        "Notifications.Title" = "Stores the notification title shown in app and admin delivery flows."
        "Notifications.Content" = "Stores the full notification content delivered to the target user."
        "Notifications.Priority" = "Stores the priority level used to order and highlight the notification."
        "Notifications.ActionUrl" = "Stores the deep link or URL opened when the user taps the notification."
        "Notifications.DedupKey" = "Stores the deduplication key used to avoid sending duplicate notifications."
        "Notifications.Audience" = "Stores the intended audience scope of the notification, such as single user or broadcast."
        "Notifications.TargetRole" = "Stores the target role filter used for role-based notification delivery."

        "NotificationArchives.Title" = "Stores the archived notification title for historical lookup."
        "NotificationArchives.Content" = "Stores the archived notification content."
        "NotificationArchives.Priority" = "Stores the archived notification priority."
        "NotificationArchives.ActionUrl" = "Stores the action URL that was attached to the archived notification."
        "NotificationArchives.DedupKey" = "Stores the deduplication key of the archived notification."
        "NotificationArchives.Audience" = "Stores the audience scope of the archived notification."
        "NotificationArchives.TargetRole" = "Stores the role filter that was used for the archived notification."
        "NotificationArchives.ArchiveReason" = "Stores the reason why the notification was archived."

        "NotificationDeliveryLogs.Channel" = "Stores the delivery channel used for the notification attempt, such as in-app or push."
        "NotificationDeliveryLogs.AttemptNumber" = "Stores which delivery attempt this log entry represents."
        "NotificationDeliveryLogs.IsSuccess" = "Indicates whether the notification delivery attempt succeeded."

        "NotificationOutboxes.Channel" = "Stores the channel that the queued notification should be delivered through."
        "NotificationOutboxes.Status" = "Stores the processing status of the queued notification."
        "NotificationOutboxes.AttemptCount" = "Stores how many delivery attempts have already been made."
        "NotificationOutboxes.MaxAttempts" = "Stores the maximum number of delivery attempts allowed."
        "NotificationOutboxes.LastError" = "Stores the last delivery error returned by the notification channel."

        "NotificationTypes.TypeName" = "Stores the display name of the notification type."
        "NotificationTypes.Template" = "Stores the message template used to render this notification type."
        "NotificationTypes.Locale" = "Stores the locale of the notification template."
        "NotificationTypes.TemplateVersion" = "Stores the version of the notification template."

        "PasswordResetOtps.OtpHash" = "Stores the hashed OTP value used for password reset verification."
        "PasswordResetOtps.Purpose" = "Stores the business purpose of the OTP, such as forgot-password verification."
        "PasswordResetOtps.AttemptCount" = "Stores how many verification attempts have been made for this OTP."
        "PasswordResetOtps.MaxAttempts" = "Stores the maximum number of allowed verification attempts for this OTP."
        "PasswordResetOtps.ResendCount" = "Stores how many times the OTP has been resent."
        "PasswordResetOtps.MaxResends" = "Stores the maximum number of OTP resends allowed."
        "PasswordResetOtps.RevokedAt" = "Stores the time when the OTP was revoked before normal expiry."
        "PasswordResetOtps.LastSentAt" = "Stores the most recent time the OTP was sent to the user."
        "PasswordResetOtps.RequestIp" = "Stores the IP address that initiated the password reset OTP request."
        "PasswordResetOtps.RequestUserAgent" = "Stores the client user agent that initiated the password reset OTP request."

        "PasswordResetSessions.SessionTokenHash" = "Stores the hashed reset session token issued after OTP verification."

        "RefreshTokens.UserID" = "Stores the user that owns this refresh token."
        "RefreshTokens.TokenHash" = "Stores the hashed refresh token used for token rotation and validation."
        "RefreshTokens.ExpiresAt" = "Stores the expiration time of the refresh token."
        "RefreshTokens.LastUsedAt" = "Stores the last time this refresh token was used to request a new access token."
        "RefreshTokens.RevokedAt" = "Stores when the refresh token was revoked."
        "RefreshTokens.ReplacedByTokenHash" = "Stores the hash of the new refresh token that replaced this token during rotation."
        "RefreshTokens.CreatedByIp" = "Stores the client IP address that created this refresh token."
        "RefreshTokens.CreatedByUserAgent" = "Stores the client user agent that created this refresh token."
        "RefreshTokens.RevokedByIp" = "Stores the client IP address that revoked this refresh token."
        "RefreshTokens.RevokedByUserAgent" = "Stores the client user agent that revoked this refresh token."
        "RefreshTokens.RevokedReason" = "Stores the reason why the refresh token was revoked."

        "Roles.RoleName" = "Stores the system role name used for authorization, such as Admin, CanBo, or SinhVien."

        "Units.UnitName" = "Stores the display name of the unit within the institute."
        "Units.UnitType" = "Stores the business type of the unit, such as faculty, class, or department."
        "Units.Description" = "Stores the description or note for the unit."

        "Users.Phone" = "Stores the phone number used for contact and account support."
        "Users.AvatarUrl" = "Stores the profile image path shown in the mobile app and admin screens."
        "Users.Gender" = "Stores the gender value used in the user profile."
        "Users.DateOfBirth" = "Stores the date of birth shown in the user profile."
        "Users.Address" = "Stores the contact address of the user."

        "UserDeviceTokens.Platform" = "Stores the mobile platform associated with the device token, such as Android or iOS."
        "UserDeviceTokens.Token" = "Stores the push notification token issued by the device platform."
        "UserDeviceTokens.DeviceId" = "Stores the application-level device identifier for the registered device."

        "UserNotificationPreferences.IsInAppEnabled" = "Indicates whether the user wants to receive in-app notifications."
        "UserNotificationPreferences.IsRealtimeEnabled" = "Indicates whether the user wants realtime notification delivery."
        "UserNotificationPreferences.IsPushEnabled" = "Indicates whether the user allows push notifications."
        "UserNotificationPreferences.IsMuted" = "Indicates whether notifications are temporarily muted for the user."
        "UserNotificationPreferences.QuietHoursStartMinute" = "Stores the start minute of the user's quiet hours window."
        "UserNotificationPreferences.QuietHoursEndMinute" = "Stores the end minute of the user's quiet hours window."

        "UserRoles.AssignDate" = "Stores the time when the role was assigned to the user."

        "UserUnits.Position" = "Stores the position or title of the user inside the unit."
    }

    $mapVi = @{
        "Users.Code" = "Lưu mã người dùng dùng làm định danh chính trong hệ thống."
        "Users.FullName" = "Lưu họ và tên đầy đủ hiển thị trên app, web admin và báo cáo."
        "Users.Email" = "Lưu địa chỉ email dùng để đăng nhập, nhận thông báo và khôi phục tài khoản."
        "Users.PasswordHash" = "Lưu giá trị băm của mật khẩu phục vụ xác thực đăng nhập."
        "Users.Status" = "Lưu trạng thái tài khoản, ví dụ đang hoạt động hoặc bị khóa."

        "Events.EventName" = "Lưu tên hiển thị của sự kiện."
        "Events.Description" = "Lưu mô tả chi tiết của sự kiện để hiển thị cho người dùng và quản trị."
        "Events.StartTime" = "Lưu thời điểm bắt đầu dự kiến của sự kiện."
        "Events.EndTime" = "Lưu thời điểm kết thúc dự kiến của sự kiện."
        "Events.LocationName" = "Lưu tên địa điểm của event."
        "Events.Latitude" = "Lưu vĩ độ của vị trí check-in của sự kiện."
        "Events.Longitude" = "Lưu kinh độ của vị trí check-in của sự kiện."
        "Events.AllowRadius" = "Lưu bán kính GPS cho phép để người tham gia được xem là đứng đúng vị trí check-in."
        "Events.MaxParticipants" = "Lưu số lượng người tham gia tối đa của sự kiện."
        "Events.CurrentParticipants" = "Lưu số lượng người tham gia hiện tại của sự kiện."
        "Events.Status" = "Lưu trạng thái vòng đời của sự kiện như nháp, mở đăng ký, đang diễn ra hoặc đã kết thúc."
        "Events.EnableFaceVerification" = "Cho biết sự kiện có yêu cầu xác thực khuôn mặt khi check-in hay không."
        "Events.RegistrationDeadline" = "Lưu hạn cuối cho phép người dùng đăng ký sự kiện."

        "Attendances.CheckInTime" = "Lưu thời điểm chính xác người dùng thực hiện check-in."
        "Attendances.CheckInMethod" = "Lưu phương thức check-in, ví dụ QR, GPS hoặc QR_GPS."
        "Attendances.UserLatitude" = "Lưu vĩ độ GPS do thiết bị người dùng gửi lên khi điểm danh."
        "Attendances.UserLongitude" = "Lưu kinh độ GPS do thiết bị người dùng gửi lên khi điểm danh."
        "Attendances.DistanceFromEvent" = "Lưu khoảng cách tính toán giữa vị trí người dùng và vị trí sự kiện."
        "Attendances.IsValid" = "Cho biết bản ghi điểm danh có hợp lệ sau khi kiểm tra QR, GPS và fraud hay không."
        "Attendances.InvalidReason" = "Lưu lý do khiến bản ghi điểm danh bị đánh dấu không hợp lệ."
        "Attendances.FaceVerified" = "Cho biết lần điểm danh này đã vượt qua bước xác thực khuôn mặt hay chưa."
        "Attendances.FaceVerificationScore" = "Lưu điểm so khớp khuôn mặt trả về từ engine xác thực."
        "Attendances.FaceVerificationStatus" = "Lưu trạng thái chuẩn hóa của kết quả xác thực khuôn mặt, ví dụ Matched, Review hoặc Mismatch."
        "Attendances.FaceVerificationReason" = "Lưu lý do hoặc giải thích đi kèm kết quả xác thực khuôn mặt."
        "Attendances.LivenessPassed" = "Cho biết kiểm tra liveness đã đạt hay chưa."
        "Attendances.LivenessScore" = "Lưu điểm liveness trả về từ dịch vụ chống giả mạo."
        "Attendances.LivenessReason" = "Lưu lý do hoặc giải thích đi kèm kết quả liveness."
        "Attendances.RiskLevel" = "Lưu mức rủi ro chuẩn hóa của bản ghi điểm danh."
        "Attendances.RiskScore" = "Lưu điểm rủi ro số dùng cho suspicious review và fraud rules."
        "Attendances.FaceRetryCount" = "Lưu số lần thử lại xác thực khuôn mặt trong luồng điểm danh."

        "LocationPresets.Name" = "Lưu tên hiển thị của vị trí định sẵn."
        "LocationPresets.Address" = "Lưu địa chỉ dễ đọc của vị trí định sẵn."
        "LocationPresets.Latitude" = "Lưu vĩ độ của vị trí định sẵn."
        "LocationPresets.Longitude" = "Lưu kinh độ của vị trí định sẵn."
        "LocationPresets.RadiusMeters" = "Lưu bán kính gợi ý mặc định theo mét khi dùng preset này cho event."
        "LocationPresets.IsActive" = "Cho biết vị trí định sẵn còn được phép chọn trong các màn quản trị hay không."

        "FaceProfiles.FaceEmbedding" = "Lưu vector embedding khuôn mặt dùng làm dữ liệu so sánh khi xác thực."
        "FaceProfiles.ImageUrl" = "Lưu đường dẫn ảnh mẫu khuôn mặt đã đăng ký."
        "FaceProfiles.Algorithm" = "Lưu tên thuật toán nhận diện dùng để tạo embedding."
        "FaceProfiles.Version" = "Lưu phiên bản pipeline tạo hồ sơ khuôn mặt."
        "FaceProfiles.IsActive" = "Cho biết hồ sơ khuôn mặt này có đang là mẫu active để đối chiếu hay không."
        "FaceProfiles.QualityScore" = "Lưu điểm chất lượng của ảnh hoặc mẫu khuôn mặt đã đăng ký."

        "ActivityPoints.Points" = "Lưu số điểm hoạt động được cộng hoặc trừ trong giao dịch này."
        "ActivityPoints.PointType" = "Lưu loại nghiệp vụ của giao dịch điểm, ví dụ điểm điểm danh, thưởng hoặc điều chỉnh thủ công."

        "Attendances.Distance" = "Lưu khoảng cách tính toán giữa vị trí người tham gia và vị trí check-in của sự kiện."
        "Attendances.FaceConfidence" = "Lưu điểm độ tin cậy của kết quả so khớp khuôn mặt khi điểm danh."
        "Attendances.FaceVerificationProvider" = "Lưu tên nhà cung cấp hoặc engine tạo ra kết quả xác thực khuôn mặt."
        "Attendances.FaceVerificationVersion" = "Lưu phiên bản pipeline xác thực khuôn mặt áp dụng cho bản ghi này."
        "Attendances.RiskReasonsJson" = "Lưu danh sách rule fraud bị kích hoạt dưới dạng JSON để phục vụ audit và review."
        "Attendances.IPAddress" = "Lưu địa chỉ IP của client tại thời điểm check-in."
        "Attendances.DeviceInfo" = "Lưu mô tả ngắn về thiết bị được dùng để điểm danh."
        "Attendances.ClientDeviceId" = "Lưu mã định danh thiết bị ở mức ứng dụng để liên kết các lần check-in đáng ngờ."

        "AuditLogs.Action" = "Lưu hành động do người dùng hoặc hệ thống thực hiện, ví dụ tạo, cập nhật, xóa hoặc đăng nhập."
        "AuditLogs.TableName" = "Lưu tên bảng nghiệp vụ bị tác động bởi hành động được audit."
        "AuditLogs.RecordID" = "Lưu mã bản ghi nghiệp vụ bị tác động bởi hành động được audit."
        "AuditLogs.OldValue" = "Lưu dữ liệu trước khi thay đổi được áp dụng."
        "AuditLogs.NewValue" = "Lưu dữ liệu sau khi thay đổi được áp dụng."
        "AuditLogs.IPAddress" = "Lưu địa chỉ IP phát sinh hành động được audit."
        "AuditLogs.UserAgent" = "Lưu thông tin user agent của trình duyệt hoặc client thực hiện hành động."

        "EventImages.ImageUrl" = "Lưu đường dẫn ảnh dùng cho banner, thư viện ảnh hoặc nội dung minh họa của sự kiện."
        "EventImages.ImageType" = "Lưu vai trò nghiệp vụ của ảnh, ví dụ ảnh bìa hoặc ảnh thư viện."
        "EventImages.Caption" = "Lưu chú thích ngắn đi kèm ảnh sự kiện."
        "EventImages.DisplayOrder" = "Lưu thứ tự hiển thị của ảnh trong danh sách ảnh sự kiện."

        "EventPoints.RoleType" = "Lưu loại vai trò người tham gia mà quy tắc cộng điểm này áp dụng, ví dụ sinh viên hoặc ban tổ chức."
        "EventPoints.Points" = "Lưu số điểm được cộng khi áp dụng quy tắc này."

        "EventQRCodes.QRToken" = "Lưu token được mã hóa vào QR code dùng cho check-in sự kiện."
        "EventQRCodes.ValidFrom" = "Lưu thời điểm bắt đầu mà QR code được phép sử dụng."
        "EventQRCodes.ValidUntil" = "Lưu thời điểm hết hiệu lực của QR code."
        "EventQRCodes.ScanLimit" = "Lưu số lần quét tối đa được phép của QR code này."
        "EventQRCodes.CurrentScans" = "Lưu số lần quét đã phát sinh của QR code này."

        "EventRegistrations.RegisterTime" = "Lưu thời điểm người dùng đăng ký tham gia sự kiện."
        "EventRegistrations.Status" = "Lưu trạng thái đăng ký, ví dụ chờ duyệt, đã duyệt, đã hủy hoặc bị từ chối."
        "EventRegistrations.CancellationReason" = "Lưu lý do hủy hoặc từ chối đăng ký sự kiện."

        "EventTypes.TypeName" = "Lưu tên hiển thị của loại sự kiện."

        "FaceRecognitionLogs.SimilarityScore" = "Lưu điểm tương đồng thô do engine so khớp khuôn mặt trả về."
        "FaceRecognitionLogs.Threshold" = "Lưu ngưỡng so khớp được dùng để quyết định pass hay fail."
        "FaceRecognitionLogs.IsMatched" = "Cho biết engine khuôn mặt có coi kết quả so sánh là khớp hay không."
        "FaceRecognitionLogs.ProcessingTime" = "Lưu thời gian xử lý của request xác thực khuôn mặt."
        "FaceRecognitionLogs.VerificationStatus" = "Lưu trạng thái xác thực khuôn mặt chuẩn hóa phục vụ audit."
        "FaceRecognitionLogs.Provider" = "Lưu tên provider hoặc service trả về kết quả xác thực khuôn mặt."
        "FaceRecognitionLogs.Model" = "Lưu tên model được dùng cho lần xác thực khuôn mặt."
        "FaceRecognitionLogs.ErrorCode" = "Lưu mã lỗi kỹ thuật khi quá trình xác thực khuôn mặt thất bại."
        "FaceRecognitionLogs.CapturedImageUrl" = "Lưu đường dẫn ảnh khuôn mặt đã capture để dùng trong lần xác thực."
        "FaceRecognitionLogs.ErrorMessage" = "Lưu thông báo lỗi kỹ thuật trả về trong quá trình xác thực khuôn mặt."

        "Institutes.InstituteName" = "Lưu tên chính thức của viện quản lý người dùng, đơn vị và sự kiện."
        "Institutes.Description" = "Lưu mô tả của viện để hiển thị trong các màn quản trị."
        "Institutes.ContactEmail" = "Lưu email liên hệ chính của viện."
        "Institutes.Status" = "Lưu trạng thái hoạt động của viện trong hệ thống."

        "Notifications.Title" = "Lưu tiêu đề thông báo hiển thị trên app và các luồng gửi thông báo."
        "Notifications.Content" = "Lưu nội dung đầy đủ của thông báo gửi tới người nhận."
        "Notifications.Priority" = "Lưu mức độ ưu tiên dùng để sắp xếp hoặc nhấn mạnh thông báo."
        "Notifications.ActionUrl" = "Lưu deep link hoặc URL sẽ mở khi người dùng bấm vào thông báo."
        "Notifications.DedupKey" = "Lưu khóa chống trùng để tránh gửi lặp cùng một thông báo."
        "Notifications.Audience" = "Lưu phạm vi đối tượng nhận thông báo, ví dụ cá nhân hoặc broadcast."
        "Notifications.TargetRole" = "Lưu bộ lọc vai trò được nhắm tới khi gửi thông báo."

        "NotificationArchives.Title" = "Lưu tiêu đề của thông báo đã được lưu trữ."
        "NotificationArchives.Content" = "Lưu nội dung của thông báo đã được lưu trữ."
        "NotificationArchives.Priority" = "Lưu mức ưu tiên của thông báo đã được lưu trữ."
        "NotificationArchives.ActionUrl" = "Lưu action URL gắn với thông báo đã lưu trữ."
        "NotificationArchives.DedupKey" = "Lưu khóa chống trùng của thông báo đã lưu trữ."
        "NotificationArchives.Audience" = "Lưu phạm vi đối tượng nhận của thông báo đã lưu trữ."
        "NotificationArchives.TargetRole" = "Lưu bộ lọc vai trò của thông báo đã lưu trữ."
        "NotificationArchives.ArchiveReason" = "Lưu lý do tại sao thông báo được lưu trữ."

        "NotificationDeliveryLogs.Channel" = "Lưu kênh gửi của lần phát thông báo, ví dụ in-app hoặc push."
        "NotificationDeliveryLogs.AttemptNumber" = "Lưu số thứ tự của lần thử gửi tương ứng với log này."
        "NotificationDeliveryLogs.IsSuccess" = "Cho biết lần thử gửi thông báo này có thành công hay không."

        "NotificationOutboxes.Channel" = "Lưu kênh mà bản ghi hàng đợi này cần gửi thông báo qua."
        "NotificationOutboxes.Status" = "Lưu trạng thái xử lý hiện tại của bản ghi hàng đợi gửi thông báo."
        "NotificationOutboxes.AttemptCount" = "Lưu số lần hệ thống đã thử gửi bản ghi hàng đợi này."
        "NotificationOutboxes.MaxAttempts" = "Lưu số lần thử gửi tối đa cho phép."
        "NotificationOutboxes.LastError" = "Lưu lỗi gần nhất phát sinh khi gửi thông báo."

        "NotificationTypes.TypeName" = "Lưu tên hiển thị của loại thông báo."
        "NotificationTypes.Template" = "Lưu mẫu nội dung dùng để dựng loại thông báo này."
        "NotificationTypes.Locale" = "Lưu locale của mẫu thông báo."
        "NotificationTypes.TemplateVersion" = "Lưu phiên bản của mẫu thông báo."

        "PasswordResetOtps.OtpHash" = "Lưu giá trị OTP đã băm dùng để xác minh luồng đặt lại mật khẩu."
        "PasswordResetOtps.Purpose" = "Lưu mục đích nghiệp vụ của OTP, ví dụ xác minh quên mật khẩu."
        "PasswordResetOtps.AttemptCount" = "Lưu số lần người dùng đã thử xác minh OTP này."
        "PasswordResetOtps.MaxAttempts" = "Lưu số lần xác minh OTP tối đa được phép."
        "PasswordResetOtps.ResendCount" = "Lưu số lần OTP đã được gửi lại."
        "PasswordResetOtps.MaxResends" = "Lưu số lần gửi lại OTP tối đa được phép."
        "PasswordResetOtps.RevokedAt" = "Lưu thời điểm OTP bị thu hồi trước khi hết hạn."
        "PasswordResetOtps.LastSentAt" = "Lưu lần gần nhất OTP được gửi tới người dùng."
        "PasswordResetOtps.RequestIp" = "Lưu địa chỉ IP đã khởi tạo yêu cầu OTP đặt lại mật khẩu."
        "PasswordResetOtps.RequestUserAgent" = "Lưu user agent của client khởi tạo yêu cầu OTP đặt lại mật khẩu."

        "PasswordResetSessions.SessionTokenHash" = "Lưu giá trị băm của reset session token được cấp sau khi xác minh OTP."

        "RefreshTokens.UserID" = "Lưu người dùng sở hữu refresh token này."
        "RefreshTokens.TokenHash" = "Lưu giá trị băm của refresh token dùng cho xác minh và token rotation."
        "RefreshTokens.ExpiresAt" = "Lưu thời điểm hết hạn của refresh token."
        "RefreshTokens.LastUsedAt" = "Lưu lần gần nhất refresh token này được dùng để xin access token mới."
        "RefreshTokens.RevokedAt" = "Lưu thời điểm refresh token bị thu hồi."
        "RefreshTokens.ReplacedByTokenHash" = "Lưu giá trị băm của refresh token mới đã thay thế token hiện tại khi rotation."
        "RefreshTokens.CreatedByIp" = "Lưu địa chỉ IP của client đã tạo refresh token này."
        "RefreshTokens.CreatedByUserAgent" = "Lưu user agent của client đã tạo refresh token này."
        "RefreshTokens.RevokedByIp" = "Lưu địa chỉ IP của client đã thu hồi refresh token này."
        "RefreshTokens.RevokedByUserAgent" = "Lưu user agent của client đã thu hồi refresh token này."
        "RefreshTokens.RevokedReason" = "Lưu lý do refresh token bị thu hồi."

        "Roles.RoleName" = "Lưu tên vai trò hệ thống dùng cho phân quyền, ví dụ Admin, CanBo hoặc SinhVien."

        "Units.UnitName" = "Lưu tên hiển thị của đơn vị trong viện."
        "Units.UnitType" = "Lưu loại nghiệp vụ của đơn vị, ví dụ khoa, lớp hoặc phòng ban."
        "Units.Description" = "Lưu mô tả hoặc ghi chú về đơn vị."

        "Users.Phone" = "Lưu số điện thoại dùng để liên hệ hoặc hỗ trợ tài khoản."
        "Users.AvatarUrl" = "Lưu đường dẫn ảnh đại diện hiển thị trên app và web admin."
        "Users.Gender" = "Lưu giới tính trong hồ sơ người dùng."
        "Users.DateOfBirth" = "Lưu ngày sinh trong hồ sơ người dùng."
        "Users.Address" = "Lưu địa chỉ liên hệ của người dùng."

        "UserDeviceTokens.Platform" = "Lưu nền tảng di động gắn với device token, ví dụ Android hoặc iOS."
        "UserDeviceTokens.Token" = "Lưu push token do nền tảng thiết bị cấp."
        "UserDeviceTokens.DeviceId" = "Lưu mã định danh thiết bị ở mức ứng dụng cho thiết bị đã đăng ký."

        "UserNotificationPreferences.IsInAppEnabled" = "Cho biết người dùng có muốn nhận thông báo trong ứng dụng hay không."
        "UserNotificationPreferences.IsRealtimeEnabled" = "Cho biết người dùng có bật nhận thông báo realtime hay không."
        "UserNotificationPreferences.IsPushEnabled" = "Cho biết người dùng có cho phép push notification hay không."
        "UserNotificationPreferences.IsMuted" = "Cho biết thông báo của người dùng đang bị tắt tạm thời hay không."
        "UserNotificationPreferences.QuietHoursStartMinute" = "Lưu phút bắt đầu của khoảng thời gian không làm phiền."
        "UserNotificationPreferences.QuietHoursEndMinute" = "Lưu phút kết thúc của khoảng thời gian không làm phiền."

        "UserRoles.AssignDate" = "Lưu thời điểm vai trò được gán cho người dùng."

        "UserUnits.Position" = "Lưu chức vụ hoặc vai trò của người dùng trong đơn vị."
    }

    if ($Language -eq "vi") {
        if ($mapVi.ContainsKey($key)) { return $mapVi[$key] }
        return $null
    }

    if ($mapEn.ContainsKey($key)) { return $mapEn[$key] }
    return $null
}

function Get-SqlType {
    param(
        [string]$ClrType,
        [string]$PropertyChain
    )

    if ($PropertyChain -match 'HasColumnType\("([^"]+)"\)') {
        return $matches[1]
    }

    if ($ClrType -like "string*") {
        if ($PropertyChain -match 'HasMaxLength\((\d+)\)') {
            return "nvarchar($($matches[1]))"
        }
        return "nvarchar(max)"
    }

    if ($ClrType -like "int*") { return "int" }
    if ($ClrType -like "long*") { return "bigint" }
    if ($ClrType -like "short*") { return "smallint" }
    if ($ClrType -match '^byte\[\]\??$') { return "varbinary(max)" }
    if ($ClrType -like "byte*") { return "tinyint" }
    if ($ClrType -like "bool*") { return "bit" }
    if ($ClrType -like "decimal*") { return "decimal(18, 2)" }
    if ($ClrType -like "double*") { return "float" }
    if ($ClrType -like "float*") { return "real" }
    if ($ClrType -like "Guid*") { return "uniqueidentifier" }
    if ($ClrType -like "DateTime*") { return "datetime" }

    return $ClrType.TrimEnd('?')
}

function Get-Description {
    param(
        [string]$TableName,
        [string]$FieldName,
        [string]$KeyType,
        [string]$Language
    )

    $businessDescription = Get-BusinessDescription -TableName $TableName -FieldName $FieldName -Language $Language
    if (-not [string]::IsNullOrWhiteSpace($businessDescription)) {
        return $businessDescription
    }

    if ($KeyType -eq "PK") {
        if ($Language -eq "vi") { return "Khóa chính của bảng $TableName." }
        return "Primary key of the $TableName table."
    }

    if ($KeyType -eq "FK") {
        $related = Split-Name ($FieldName -replace 'Id$', '' -replace 'ID$', '')
        if ($Language -eq "vi") { return "Khóa ngoại tham chiếu tới bản ghi $related liên quan." }
        return "Foreign key referencing the related $related record."
    }

    switch -Regex ($FieldName) {
        '^(CreatedDate|CreatedAt)$' { if ($Language -eq "vi") { return "Lưu thời điểm bản ghi được tạo." } return "Stores when the record was created." }
        '^(UpdatedDate|UpdatedAt)$' { if ($Language -eq "vi") { return "Lưu thời điểm bản ghi được cập nhật lần cuối." } return "Stores when the record was last updated." }
        '^(DeletedDate|ArchivedDate)$' { if ($Language -eq "vi") { return "Lưu thời điểm bản ghi bị lưu trữ hoặc xóa." } return "Stores when the record was archived or deleted." }
        '^(StartTime|ValidFrom|JoinDate|RegisterTime|ReadDate|UsedAt|VerifiedAt|ProcessedAt|LastAttemptAt|NextAttemptAt|LastSeenAt|LastLoginDate)$' { if ($Language -eq "vi") { return "Lưu thời điểm liên quan của quy trình." } return "Stores the relevant date and time for this process." }
        '^(EndTime|ValidUntil|ExpiredAt|ExpiresAt|ExpiryDate)$' { if ($Language -eq "vi") { return "Lưu thời điểm kết thúc hoặc hết hạn." } return "Stores the end or expiration date and time." }
        '^Name$' { if ($Language -eq "vi") { return "Lưu tên của bản ghi." } return "Stores the name of the record." }
        'Name$' { if ($Language -eq "vi") { return "Lưu tên hoặc tiêu đề của trường này." } return "Stores the name or title for this field." }
        'Description$' { if ($Language -eq "vi") { return "Lưu thông tin mô tả của bản ghi." } return "Stores the descriptive information for the record." }
        '^Status$' { if ($Language -eq "vi") { return "Lưu trạng thái hiện tại của bản ghi." } return "Stores the current status of the record." }
        '^IsActive$' { if ($Language -eq "vi") { return "Cho biết bản ghi có đang hoạt động hay không." } return "Indicates whether the record is active." }
        '^IsRead$' { if ($Language -eq "vi") { return "Cho biết thông báo đã được đọc hay chưa." } return "Indicates whether the notification has been read." }
        '^IsValid$' { if ($Language -eq "vi") { return "Cho biết bản ghi có được xem là hợp lệ hay không." } return "Indicates whether the record is considered valid." }
        '^IsMatched$' { if ($Language -eq "vi") { return "Cho biết kết quả so khớp khuôn mặt có trùng khớp hay không." } return "Indicates whether the face comparison result is a match." }
        '^IsUsed$' { if ($Language -eq "vi") { return "Cho biết token hoặc OTP đã được sử dụng hay chưa." } return "Indicates whether the token or OTP has already been used." }
        '^Latitude$' { if ($Language -eq "vi") { return "Lưu tọa độ vĩ độ." } return "Stores the latitude coordinate." }
        '^Longitude$' { if ($Language -eq "vi") { return "Lưu tọa độ kinh độ." } return "Stores the longitude coordinate." }
        'Radius' { if ($Language -eq "vi") { return "Lưu bán kính cho phép theo mét." } return "Stores the allowed radius in meters." }
        'Email$' { if ($Language -eq "vi") { return "Lưu địa chỉ email." } return "Stores the email address." }
        'Phone$' { if ($Language -eq "vi") { return "Lưu số điện thoại." } return "Stores the phone number." }
        'Address$' { if ($Language -eq "vi") { return "Lưu địa chỉ hoặc ghi chú địa điểm." } return "Stores the address or address note." }
        'PasswordHash$' { if ($Language -eq "vi") { return "Lưu mật khẩu đã băm." } return "Stores the hashed password." }
        'Token$' { if ($Language -eq "vi") { return "Lưu giá trị token." } return "Stores the token value." }
        'Hash$' { if ($Language -eq "vi") { return "Lưu giá trị băm để xác thực bảo mật." } return "Stores the hashed value for security verification." }
        'Code$' { if ($Language -eq "vi") { return "Lưu mã dùng trong hệ thống." } return "Stores the code value used by the system." }
        'Url$' { if ($Language -eq "vi") { return "Lưu URL hoặc đường dẫn của tài nguyên liên quan." } return "Stores the URL or path to the related resource." }
        'Reason$' { if ($Language -eq "vi") { return "Lưu lý do hoặc giải thích cho trạng thái này." } return "Stores the reason or explanation for this state." }
        'Message$' { if ($Language -eq "vi") { return "Lưu nội dung thông điệp liên quan." } return "Stores the related message content." }
        'Provider$' { if ($Language -eq "vi") { return "Lưu tên nhà cung cấp được sử dụng." } return "Stores the provider name used by the process." }
        'Version$' { if ($Language -eq "vi") { return "Lưu thông tin phiên bản." } return "Stores the version information." }
        'Score$' { if ($Language -eq "vi") { return "Lưu giá trị điểm số được tính toán." } return "Stores the calculated score value." }
        'Count$' { if ($Language -eq "vi") { return "Lưu số lượng liên quan của trường này." } return "Stores the numeric count for this field." }
        'Attempt' { if ($Language -eq "vi") { return "Lưu thông tin số lần thử hoặc retry." } return "Stores the retry or attempt information." }
        'Priority$' { if ($Language -eq "vi") { return "Lưu mức độ ưu tiên." } return "Stores the priority level." }
        'Platform$' { if ($Language -eq "vi") { return "Lưu tên nền tảng hoặc thiết bị." } return "Stores the device or platform name." }
        'Audience$' { if ($Language -eq "vi") { return "Lưu phạm vi đối tượng nhận." } return "Stores the target audience scope." }
        'Role' { if ($Language -eq "vi") { return "Lưu giá trị liên quan đến vai trò." } return "Stores the role-related value." }
        'Point' { if ($Language -eq "vi") { return "Lưu giá trị liên quan đến điểm." } return "Stores the point-related value." }
        'Image' { if ($Language -eq "vi") { return "Lưu thông tin liên quan đến ảnh." } return "Stores the image-related information." }
        'Face' { if ($Language -eq "vi") { return "Lưu thông tin liên quan đến khuôn mặt hoặc xác thực khuôn mặt." } return "Stores the face verification or profile information." }
        'Notification' { if ($Language -eq "vi") { return "Lưu thông tin liên quan đến thông báo." } return "Stores the notification-related information." }
        default {
            $label = (Split-Name $FieldName).ToLowerInvariant()
            if ($Language -eq "vi") { return "Lưu thông tin cho trường $label." }
            return "Stores the $label."
        }
    }
}

function Write-Utf8File {
    param(
        [string]$Path,
        [string]$Content
    )
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8)
}

function New-WordCellXml {
    param(
        [string]$Text,
        [switch]$Bold,
        [switch]$Center,
        [int]$GridSpan = 1
    )

    $escaped = Escape-Xml $Text
    $jc = if ($Center) { '<w:jc w:val="center"/>' } else { '' }
    $boldXml = if ($Bold) { '<w:b/>' } else { '' }
    $gridSpanXml = if ($GridSpan -gt 1) { "<w:gridSpan w:val=`"$GridSpan`"/>" } else { '' }

    return @"
<w:tc>
  <w:tcPr>
    <w:tcW w:w="0" w:type="auto"/>
    $gridSpanXml
  </w:tcPr>
  <w:p>
    <w:pPr>$jc</w:pPr>
    <w:r>
      <w:rPr>$boldXml</w:rPr>
      <w:t xml:space="preserve">$escaped</w:t>
    </w:r>
  </w:p>
</w:tc>
"@
}

function New-WordRowXml {
    param([string[]]$Cells)
    return "<w:tr>`n$($Cells -join "`n")`n</w:tr>"
}

function Get-DbSetMap {
    $map = @{}
    foreach ($file in $dbContextFiles) {
        $content = Get-Content -Raw -Encoding UTF8 $file
        foreach ($m in [regex]::Matches($content, 'public virtual DbSet<(?<entity>[^>]+)>\s+(?<dbset>\w+)')) {
            $map[$m.Groups['entity'].Value] = $m.Groups['dbset'].Value
        }
    }
    return $map
}

function Get-EntityBlock {
    param([string]$EntityName)

    foreach ($file in $dbContextFiles) {
        $content = Get-Content -Raw -Encoding UTF8 $file
        $pattern = "modelBuilder\.Entity<$EntityName>\(entity =>\s*\{(?<body>.*?)\n\s*\}\);"
        $match = [regex]::Match($content, $pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
        if ($match.Success) {
            return $match.Groups["body"].Value
        }
    }

    throw "Cannot find EF mapping block for entity $EntityName"
}

function Get-EntityProperties {
    param([string]$EntityName)

    $entityFile = Join-Path $entityRoot "$EntityName.cs"
    if (-not (Test-Path $entityFile)) {
        throw "Cannot find entity file $entityFile"
    }

    $content = Get-Content -Raw -Encoding UTF8 $entityFile
    $properties = New-Object System.Collections.Generic.List[object]

    foreach ($m in [regex]::Matches($content, 'public\s+(?<type>[A-Za-z0-9_\?\.\[\]]+)\s+(?<name>\w+)\s*\{\s*get;\s*set;\s*\}')) {
        $type = $m.Groups["type"].Value
        $name = $m.Groups["name"].Value

        if ($type -like "ICollection*" -or $type -like "virtual*") { continue }
        if ($name -like "Inverse*") { continue }

        $properties.Add([PSCustomObject]@{
            Name = $name
            ClrType = $type
            Nullable = ($type.Contains("?"))
        })
    }

    return $properties
}

function Get-PropertyChains {
    param([string]$Block)
    $chains = @{}
    foreach ($m in [regex]::Matches($Block, 'entity\.Property\(e => e\.(?<name>\w+)\)(?<chain>.*?);', [System.Text.RegularExpressions.RegexOptions]::Singleline)) {
        $chains[$m.Groups["name"].Value] = $m.Groups["chain"].Value
    }
    return $chains
}

$dbSetMap = Get-DbSetMap

$tables = foreach ($entity in $usedEntities) {
    $block = Get-EntityBlock -EntityName $entity
    $properties = Get-EntityProperties -EntityName $entity
    $propertyChains = Get-PropertyChains -Block $block

    $tableName = if ($block -match 'ToTable\("([^"]+)"\)') { $matches[1] } else { $dbSetMap[$entity] }
    $pkColumns = @([regex]::Matches($block, 'HasKey\(e => e\.(\w+)\)') | ForEach-Object { $_.Groups[1].Value })
    $fkColumns = @([regex]::Matches($block, 'HasForeignKey\(d => d\.(\w+)\)') | ForEach-Object { $_.Groups[1].Value })

    $rows = foreach ($property in $properties) {
        $chain = if ($propertyChains.ContainsKey($property.Name)) { $propertyChains[$property.Name] } else { "" }
        $keyType = if ($pkColumns -contains $property.Name) { "PK" } elseif ($fkColumns -contains $property.Name) { "FK" } else { "" }

        [PSCustomObject]@{
            FieldName = $property.Name
            DataType = Get-SqlType -ClrType $property.ClrType -PropertyChain $chain
            Null = if ($property.Nullable) { "Yes" } else { "No" }
            Key = $keyType
            Description = Get-Description -TableName $tableName -FieldName $property.Name -KeyType $keyType -Language $Language
        }
    }

    [PSCustomObject]@{
        EntityName = $entity
        TableName = $tableName
        Rows = $rows
    }
}

$sectionXml = New-Object System.Collections.Generic.List[string]

if ($Language -eq "vi") {
    $docTitle = Escape-Xml "Thiết Kế Cơ Sở Dữ Liệu UniYouth (Chỉ Bao Gồm Các Bảng Đang Sử Dụng)"
    $generatedAt = Escape-Xml ("Tạo lúc " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
    $introText = "Tài liệu này chỉ bao gồm các bảng dữ liệu đang được hệ thống sử dụng. Các view không được đưa vào."
}
else {
    $docTitle = Escape-Xml "UniYouth Database Design (Used Tables Only)"
    $generatedAt = Escape-Xml ("Generated on " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
    $introText = "This document includes only database tables that are currently used by the system. Views are excluded."
}

$sectionXml.Add(@"
<w:p>
  <w:pPr><w:jc w:val="center"/></w:pPr>
  <w:r><w:rPr><w:b/><w:sz w:val="32"/></w:rPr><w:t>$docTitle</w:t></w:r>
</w:p>
<w:p>
  <w:pPr><w:jc w:val="center"/></w:pPr>
  <w:r><w:rPr><w:sz w:val="20"/></w:rPr><w:t>$generatedAt</w:t></w:r>
</w:p>
<w:p>
  <w:r><w:t>$([System.Security.SecurityElement]::Escape($introText))</w:t></w:r>
</w:p>
"@)

for ($i = 0; $i -lt $tables.Count; $i++) {
    $table = $tables[$i]
    if ($Language -eq "vi") {
        $tableLabel = "Bảng"
        $fieldNameLabel = "Tên Trường"
        $dataTypeLabel = "Kiểu Dữ Liệu"
        $keyLabel = "Khóa"
        $descriptionLabel = "Mô Tả"
    }
    else {
        $tableLabel = "Table"
        $fieldNameLabel = "Field Name"
        $dataTypeLabel = "Data Type"
        $keyLabel = "Key"
        $descriptionLabel = "Description"
    }
    $nullLabel = "Null"

    $titleRow = New-WordRowXml -Cells @(
        (New-WordCellXml -Text ("{0}: {1}" -f $tableLabel, $table.TableName) -Bold -Center -GridSpan 5)
    )
    $headerRow = New-WordRowXml -Cells @(
        (New-WordCellXml -Text $fieldNameLabel -Bold -Center),
        (New-WordCellXml -Text $dataTypeLabel -Bold -Center),
        (New-WordCellXml -Text $nullLabel -Bold -Center),
        (New-WordCellXml -Text $keyLabel -Bold -Center),
        (New-WordCellXml -Text $descriptionLabel -Bold -Center)
    )

    $dataRows = foreach ($row in $table.Rows) {
        if ($Language -eq "vi") {
            if ($row.Null -eq "Yes") { $nullText = "Có" } else { $nullText = "Không" }
            if ($row.Key -eq "PK") { $keyText = "PK" }
            elseif ($row.Key -eq "FK") { $keyText = "FK" }
            else { $keyText = "" }
        }
        else {
            $nullText = $row.Null
            $keyText = $row.Key
        }

        New-WordRowXml -Cells @(
            (New-WordCellXml -Text $row.FieldName),
            (New-WordCellXml -Text $row.DataType),
            (New-WordCellXml -Text $nullText -Center),
            (New-WordCellXml -Text $keyText -Center),
            (New-WordCellXml -Text $row.Description)
        )
    }

    $tableXml = @"
<w:tbl>
  <w:tblPr>
    <w:tblStyle w:val="TableGrid"/>
    <w:tblW w:w="0" w:type="auto"/>
    <w:tblBorders>
      <w:top w:val="single" w:sz="8" w:space="0" w:color="000000"/>
      <w:left w:val="single" w:sz="8" w:space="0" w:color="000000"/>
      <w:bottom w:val="single" w:sz="8" w:space="0" w:color="000000"/>
      <w:right w:val="single" w:sz="8" w:space="0" w:color="000000"/>
      <w:insideH w:val="single" w:sz="8" w:space="0" w:color="000000"/>
      <w:insideV w:val="single" w:sz="8" w:space="0" w:color="000000"/>
    </w:tblBorders>
  </w:tblPr>
  <w:tblGrid>
    <w:gridCol w:w="2200"/>
    <w:gridCol w:w="1900"/>
    <w:gridCol w:w="800"/>
    <w:gridCol w:w="800"/>
    <w:gridCol w:w="4700"/>
  </w:tblGrid>
  $titleRow
  $headerRow
  $($dataRows -join "`n")
</w:tbl>
"@

    $sectionXml.Add($tableXml)

    if ($i -lt ($tables.Count - 1)) {
        $sectionXml.Add('<w:p><w:r><w:br w:type="page"/></w:r></w:p>')
    }
}

$documentXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:wpc="http://schemas.microsoft.com/office/word/2010/wordprocessingCanvas"
 xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
 xmlns:o="urn:schemas-microsoft-com:office:office"
 xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
 xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math"
 xmlns:v="urn:schemas-microsoft-com:vml"
 xmlns:wp14="http://schemas.microsoft.com/office/word/2010/wordprocessingDrawing"
 xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
 xmlns:w10="urn:schemas-microsoft-com:office:word"
 xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
 xmlns:w14="http://schemas.microsoft.com/office/word/2010/wordml"
 xmlns:w15="http://schemas.microsoft.com/office/word/2012/wordml"
 xmlns:wpg="http://schemas.microsoft.com/office/word/2010/wordprocessingGroup"
 xmlns:wpi="http://schemas.microsoft.com/office/word/2010/wordprocessingInk"
 xmlns:wne="http://schemas.microsoft.com/office/word/2006/wordml"
 xmlns:wps="http://schemas.microsoft.com/office/word/2010/wordprocessingShape"
 mc:Ignorable="w14 w15 wp14">
  <w:body>
    $($sectionXml -join "`n")
    <w:sectPr>
      <w:pgSz w:w="11906" w:h="16838"/>
      <w:pgMar w:top="720" w:right="720" w:bottom="720" w:left="720" w:header="708" w:footer="708" w:gutter="0"/>
    </w:sectPr>
  </w:body>
</w:document>
"@

$stylesXml = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:style w:type="paragraph" w:default="1" w:styleId="Normal">
    <w:name w:val="Normal"/>
    <w:qFormat/>
    <w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman"/>
      <w:sz w:val="22"/>
    </w:rPr>
  </w:style>
  <w:style w:type="table" w:default="1" w:styleId="TableGrid">
    <w:name w:val="Table Grid"/>
    <w:tblPr>
      <w:tblBorders>
        <w:top w:val="single" w:sz="8" w:space="0" w:color="000000"/>
        <w:left w:val="single" w:sz="8" w:space="0" w:color="000000"/>
        <w:bottom w:val="single" w:sz="8" w:space="0" w:color="000000"/>
        <w:right w:val="single" w:sz="8" w:space="0" w:color="000000"/>
        <w:insideH w:val="single" w:sz="8" w:space="0" w:color="000000"/>
        <w:insideV w:val="single" w:sz="8" w:space="0" w:color="000000"/>
      </w:tblBorders>
    </w:tblPr>
  </w:style>
</w:styles>
'@

$contentTypesXml = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
  <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
</Types>
'@

$relsXml = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>
'@

$documentRelsXml = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>
'@

$nowIso = (Get-Date).ToString("s") + "Z"
if ($Language -eq "vi") {
    $coreTitle = "Thiết kế cơ sở dữ liệu UniYouth"
}
else {
    $coreTitle = "UniYouth Database Design"
}
$coreXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties"
 xmlns:dc="http://purl.org/dc/elements/1.1/"
 xmlns:dcterms="http://purl.org/dc/terms/"
 xmlns:dcmitype="http://purl.org/dc/dcmitype/"
 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <dc:title>$coreTitle</dc:title>
  <dc:creator>Codex</dc:creator>
  <cp:lastModifiedBy>Codex</cp:lastModifiedBy>
  <dcterms:created xsi:type="dcterms:W3CDTF">$nowIso</dcterms:created>
  <dcterms:modified xsi:type="dcterms:W3CDTF">$nowIso</dcterms:modified>
</cp:coreProperties>
"@

$appXml = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties"
 xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">
  <Application>Codex</Application>
</Properties>
'@

$tempDirName = ".tmp_used_db_docx_" + [System.IO.Path]::GetFileNameWithoutExtension($OutputPath) + "_" + [guid]::NewGuid().ToString("N")
$tempDir = Join-Path $repoRoot $tempDirName
if (Test-Path $tempDir) {
    Remove-Item -Recurse -Force $tempDir
}

New-Item -ItemType Directory -Path $tempDir | Out-Null
New-Item -ItemType Directory -Path (Join-Path $tempDir "_rels") | Out-Null
New-Item -ItemType Directory -Path (Join-Path $tempDir "word") | Out-Null
New-Item -ItemType Directory -Path (Join-Path $tempDir "word\_rels") | Out-Null
New-Item -ItemType Directory -Path (Join-Path $tempDir "docProps") | Out-Null

Write-Utf8File -Path (Join-Path $tempDir "[Content_Types].xml") -Content $contentTypesXml
Write-Utf8File -Path (Join-Path $tempDir "_rels\.rels") -Content $relsXml
Write-Utf8File -Path (Join-Path $tempDir "word\document.xml") -Content $documentXml
Write-Utf8File -Path (Join-Path $tempDir "word\styles.xml") -Content $stylesXml
Write-Utf8File -Path (Join-Path $tempDir "word\_rels\document.xml.rels") -Content $documentRelsXml
Write-Utf8File -Path (Join-Path $tempDir "docProps\core.xml") -Content $coreXml
Write-Utf8File -Path (Join-Path $tempDir "docProps\app.xml") -Content $appXml

$outputFullPath = if ([System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath
} else {
    Join-Path $repoRoot $OutputPath
}

if (Test-Path $outputFullPath) {
    Remove-Item -Force $outputFullPath
}

$zipPath = [System.IO.Path]::ChangeExtension($outputFullPath, ".zip")
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}

Compress-Archive -Path (Join-Path $tempDir '*') -DestinationPath $zipPath -Force
Move-Item -Force $zipPath $outputFullPath
Remove-Item -Recurse -Force $tempDir

Write-Host "Generated: $outputFullPath"
