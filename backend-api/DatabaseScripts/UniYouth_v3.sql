USE [master]
GO
/****** Object:  Database [UniYouth]    Script Date: 3/13/2026 6:20:28 AM ******/
IF DB_ID(N'UniYouth') IS NOT NULL
BEGIN
    ALTER DATABASE [UniYouth] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [UniYouth];
END
GO
CREATE DATABASE [UniYouth]
  CONTAINMENT = NONE
  WITH CATALOG_COLLATION = DATABASE_DEFAULT, LEDGER = OFF
GO
ALTER DATABASE [UniYouth] SET COMPATIBILITY_LEVEL = 160
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [UniYouth].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [UniYouth] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [UniYouth] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [UniYouth] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [UniYouth] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [UniYouth] SET ARITHABORT OFF 
GO
ALTER DATABASE [UniYouth] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [UniYouth] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [UniYouth] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [UniYouth] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [UniYouth] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [UniYouth] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [UniYouth] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [UniYouth] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [UniYouth] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [UniYouth] SET  ENABLE_BROKER 
GO
ALTER DATABASE [UniYouth] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [UniYouth] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [UniYouth] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [UniYouth] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [UniYouth] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [UniYouth] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [UniYouth] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [UniYouth] SET RECOVERY FULL 
GO
ALTER DATABASE [UniYouth] SET  MULTI_USER 
GO
ALTER DATABASE [UniYouth] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [UniYouth] SET DB_CHAINING OFF 
GO
ALTER DATABASE [UniYouth] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [UniYouth] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [UniYouth] SET DELAYED_DURABILITY = DISABLED 
GO
ALTER DATABASE [UniYouth] SET ACCELERATED_DATABASE_RECOVERY = OFF  
GO
EXEC sys.sp_db_vardecimal_storage_format N'UniYouth', N'ON'
GO
ALTER DATABASE [UniYouth] SET QUERY_STORE = ON
GO
ALTER DATABASE [UniYouth] SET QUERY_STORE (OPERATION_MODE = READ_WRITE, CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 30), DATA_FLUSH_INTERVAL_SECONDS = 900, INTERVAL_LENGTH_MINUTES = 60, MAX_STORAGE_SIZE_MB = 1000, QUERY_CAPTURE_MODE = AUTO, SIZE_BASED_CLEANUP_MODE = AUTO, MAX_PLANS_PER_QUERY = 200, WAIT_STATS_CAPTURE_MODE = ON)
GO
USE [UniYouth]
GO
/****** Object:  Table [dbo].[Events]    Script Date: 3/13/2026 6:20:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Events](
	[EventID] [int] IDENTITY(1,1) NOT NULL,
	[EventName] [nvarchar](200) NOT NULL,
	[Description] [nvarchar](max) NULL,
	[StartTime] [datetime] NOT NULL,
	[EndTime] [datetime] NOT NULL,
	[LocationName] [nvarchar](200) NULL,
	[Latitude] [decimal](10, 6) NULL,
	[Longitude] [decimal](10, 6) NULL,
	[AllowRadius] [int] NULL,
	[MaxParticipants] [int] NULL,
	[CurrentParticipants] [int] NULL,
	[CreatedBy] [int] NOT NULL,
	[EventTypeID] [int] NOT NULL,
	[InstituteID] [int] NULL,
	[Status] [tinyint] NULL,
	[RegistrationDeadline] [datetime] NULL,
	[CreatedDate] [datetime] NULL,
	[UpdatedDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[EventID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[EventRegistrations]    Script Date: 3/13/2026 6:20:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EventRegistrations](
	[RegistrationID] [int] IDENTITY(1,1) NOT NULL,
	[EventID] [int] NOT NULL,
	[UserID] [int] NOT NULL,
	[RegisterTime] [datetime] NULL,
	[Status] [tinyint] NULL,
	[CancellationReason] [nvarchar](255) NULL,
	[CreatedDate] [datetime] NULL,
	[UpdatedDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[RegistrationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Attendances]    Script Date: 3/13/2026 6:20:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Attendances](
	[AttendanceID] [int] IDENTITY(1,1) NOT NULL,
	[EventID] [int] NOT NULL,
	[UserID] [int] NOT NULL,
	[QRID] [int] NOT NULL,
	[CheckInMethod] [nvarchar](50) NULL,
	[CheckInTime] [datetime] NULL,
	[UserLatitude] [decimal](10, 6) NULL,
	[UserLongitude] [decimal](10, 6) NULL,
	[Distance] [float] NULL,
	[FaceVerified] [bit] NULL,
	[FaceConfidence] [float] NULL,
	[IsValid] [bit] NULL,
	[InvalidReason] [nvarchar](255) NULL,
	[IPAddress] [nvarchar](50) NULL,
	[DeviceInfo] [nvarchar](255) NULL,
	[CreatedDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[AttendanceID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[vw_EventAttendanceStats]    Script Date: 3/13/2026 6:20:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vw_EventAttendanceStats] AS
SELECT 
    e.EventID,
    e.EventName,
    -- Convert UTC -> Vietnam Time (UTC+7)
e.StartTime,
    e.MaxParticipants,

    -- Tổng số người đăng ký hợp lệ
    COUNT(DISTINCT er.UserID) AS TotalRegistrations,

    -- Số người check-in hợp lệ
    COUNT(DISTINCT CASE 
        WHEN a.IsValid = 1 THEN a.UserID 
    END) AS ValidAttendances,

    -- Số người check-in không hợp lệ
    COUNT(DISTINCT CASE 
        WHEN a.IsValid = 0 THEN a.UserID 
    END) AS InvalidAttendances,

    -- Tỷ lệ điểm danh
    CAST(
        COUNT(DISTINCT CASE WHEN a.IsValid = 1 THEN a.UserID END) * 100.0
        / NULLIF(COUNT(DISTINCT er.UserID), 0)
        AS DECIMAL(5,2)
    ) AS AttendanceRate

FROM Events e

-- Chỉ tính người đăng ký hợp lệ
LEFT JOIN EventRegistrations er 
    ON e.EventID = er.EventID
   AND er.Status = 0

-- Attendance PHẢI thuộc user đã đăng ký
LEFT JOIN Attendances a 
    ON e.EventID = a.EventID
   AND a.UserID = er.UserID   
GROUP BY 
    e.EventID,
    e.EventName,
    e.StartTime,
    e.MaxParticipants;
GO
/****** Object:  Table [dbo].[ActivityPoints]    Script Date: 3/13/2026 6:20:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ActivityPoints](
	[PointID] [int] IDENTITY(1,1) NOT NULL,
	[EventID] [int] NOT NULL,
	[UserID] [int] NOT NULL,
	[EventPointID] [int] NULL,
	[Points] [int] NOT NULL,
	[PointType] [nvarchar](50) NULL,
	[AwardedBy] [int] NULL,
	[CreatedDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[PointID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Users]    Script Date: 3/13/2026 6:20:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Users](
	[UserID] [int] IDENTITY(1,1) NOT NULL,
	[Code] [nvarchar](20) NOT NULL,
	[FullName] [nvarchar](100) NOT NULL,
	[Email] [nvarchar](100) NOT NULL,
	[Phone] [nvarchar](20) NULL,
	[PasswordHash] [nvarchar](255) NOT NULL,
	[AvatarUrl] [nvarchar](255) NULL,
	[Gender] [bit] NULL,
	[DateOfBirth] [date] NULL,
	[Address] [nvarchar](255) NULL,
	[Status] [tinyint] NULL,
	[LastLoginDate] [datetime] NULL,
	[CreatedDate] [datetime] NULL,
	[UpdatedDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[UserID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[vw_UserTotalPoints]    Script Date: 3/13/2026 6:20:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   VIEW [dbo].[vw_UserTotalPoints] AS
SELECT 
    u.UserID,
    u.FullName,
    u.Code,

    ISNULL(SUM(
        CASE 
            WHEN a.IsValid = 1 THEN ap.Points 
            ELSE 0 
        END
    ), 0) AS TotalPoints,

    COUNT(DISTINCT CASE 
        WHEN a.IsValid = 1 THEN a.EventID 
    END) AS EventsParticipated,

    COUNT(DISTINCT CASE 
        WHEN a.IsValid = 1 THEN a.EventID 
    END) AS ValidAttendances

FROM Users u
LEFT JOIN Attendances a 
    ON u.UserID = a.UserID
LEFT JOIN ActivityPoints ap 
    ON ap.UserID = u.UserID
   AND ap.EventID = a.EventID

GROUP BY 
    u.UserID,
    u.FullName,
    u.Code;
GO
/****** Object:  Table [dbo].[AuditLogs]    Script Date: 3/13/2026 6:20:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AuditLogs](
	[AuditID] [int] IDENTITY(1,1) NOT NULL,
	[UserID] [int] NULL,
	[Action] [nvarchar](50) NOT NULL,
	[TableName] [nvarchar](100) NULL,
	[RecordID] [int] NULL,
	[OldValue] [nvarchar](max) NULL,
	[NewValue] [nvarchar](max) NULL,
	[IPAddress] [nvarchar](50) NULL,
	[UserAgent] [nvarchar](255) NULL,
	[CreatedDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[AuditID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[EventImages]    Script Date: 3/13/2026 6:20:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EventImages](
	[ImageID] [int] IDENTITY(1,1) NOT NULL,
	[EventID] [int] NOT NULL,
	[ImageUrl] [nvarchar](255) NOT NULL,
	[ImageType] [nvarchar](50) NULL,
	[Caption] [nvarchar](255) NULL,
	[DisplayOrder] [int] NULL,
	[CreatedDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[ImageID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[EventPoints]    Script Date: 3/13/2026 6:20:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EventPoints](
	[EventPointID] [int] IDENTITY(1,1) NOT NULL,
	[EventID] [int] NOT NULL,
	[RoleType] [nvarchar](50) NOT NULL,
	[Points] [int] NOT NULL,
	[Description] [nvarchar](255) NULL,
	[CreatedDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[EventPointID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[EventQRCodes]    Script Date: 3/13/2026 6:20:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EventQRCodes](
	[QRID] [int] IDENTITY(1,1) NOT NULL,
	[EventID] [int] NOT NULL,
	[QRToken] [nvarchar](255) NOT NULL,
	[ValidFrom] [datetime] NOT NULL,
	[ValidUntil] [datetime] NOT NULL,
	[IsActive] [bit] NULL,
	[ScanLimit] [int] NULL,
	[CurrentScans] [int] NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NULL,
	[UpdatedDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[QRID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[EventType]    Script Date: 3/13/2026 6:20:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EventType](
	[TypeID] [int] IDENTITY(1,1) NOT NULL,
	[TypeName] [nvarchar](200) NOT NULL,
	[Description] [nvarchar](255) NULL,
	[CreatedDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[TypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FaceProfiles]    Script Date: 3/13/2026 6:20:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FaceProfiles](
	[FaceProfileID] [int] IDENTITY(1,1) NOT NULL,
	[UserID] [int] NOT NULL,
	[FaceEmbedding] [varbinary](max) NOT NULL,
	[Algorithm] [nvarchar](50) NULL,
	[Version] [nvarchar](20) NULL,
	[QualityScore] [float] NULL,
	[ImageUrl] [nvarchar](255) NULL,
	[IsActive] [bit] NULL,
	[CreatedDate] [datetime] NULL,
	[UpdatedDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[FaceProfileID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FaceRecognitionLogs]    Script Date: 3/13/2026 6:20:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FaceRecognitionLogs](
	[FaceLogID] [int] IDENTITY(1,1) NOT NULL,
	[AttendanceID] [int] NOT NULL,
	[FaceProfileID] [int] NOT NULL,
	[SimilarityScore] [float] NOT NULL,
	[Threshold] [float] NULL,
	[IsMatched] [bit] NULL,
	[ProcessingTime] [int] NULL,
	[CapturedImageUrl] [nvarchar](255) NULL,
	[ErrorMessage] [nvarchar](255) NULL,
	[CreatedDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[FaceLogID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Institutes]    Script Date: 3/13/2026 6:20:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Institutes](
	[InstituteID] [int] IDENTITY(1,1) NOT NULL,
	[InstituteName] [nvarchar](150) NOT NULL,
	[Description] [nvarchar](255) NULL,
	[ContactEmail] [nvarchar](100) NULL,
	[Status] [tinyint] NULL,
	[CreatedDate] [datetime] NULL,
	[UpdatedDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[InstituteID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[LocationPresets]    Script Date: 3/13/2026 6:20:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LocationPresets](
	[LocationPresetID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](200) NOT NULL,
	[Address] [nvarchar](500) NULL,
	[Latitude] [decimal](10, 6) NOT NULL,
	[Longitude] [decimal](10, 6) NOT NULL,
	[RadiusMeters] [int] NULL,
	[InstituteID] [int] NULL,
	[UnitID] [int] NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NULL,
	[CreatedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_LocationPresets] PRIMARY KEY CLUSTERED 
(
	[LocationPresetID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[NotificationArchive]    Script Date: 3/13/2026 6:20:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[NotificationArchive](
	[NotificationID] [int] NOT NULL,
	[UserID] [int] NOT NULL,
	[EventID] [int] NULL,
	[Title] [nvarchar](200) NOT NULL,
	[Content] [nvarchar](max) NOT NULL,
	[NotificationTypeID] [int] NOT NULL,
	[Priority] [tinyint] NULL,
	[IsRead] [bit] NULL,
	[ReadDate] [datetime] NULL,
	[ActionUrl] [nvarchar](255) NULL,
	[DedupKey] [nvarchar](200) NULL,
	[Audience] [nvarchar](30) NULL,
	[TargetRole] [nvarchar](50) NULL,
	[CreatedDate] [datetime] NULL,
	[ExpiryDate] [datetime] NULL,
	[ArchivedDate] [datetime] NOT NULL,
	[ArchiveReason] [nvarchar](255) NULL,
 CONSTRAINT [PK_NotificationArchive] PRIMARY KEY CLUSTERED 
(
	[NotificationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[NotificationDeliveryLog]    Script Date: 3/13/2026 6:20:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[NotificationDeliveryLog](
	[DeliveryLogID] [int] IDENTITY(1,1) NOT NULL,
	[OutboxID] [int] NOT NULL,
	[NotificationID] [int] NOT NULL,
	[UserID] [int] NOT NULL,
	[Channel] [tinyint] NOT NULL,
	[AttemptNumber] [int] NOT NULL,
	[IsSuccess] [bit] NOT NULL,
	[ErrorMessage] [nvarchar](1000) NULL,
	[CreatedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_NotificationDeliveryLog] PRIMARY KEY CLUSTERED 
(
	[DeliveryLogID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[NotificationOutbox]    Script Date: 3/13/2026 6:20:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[NotificationOutbox](
	[OutboxID] [int] IDENTITY(1,1) NOT NULL,
	[NotificationID] [int] NOT NULL,
	[UserID] [int] NOT NULL,
	[Channel] [tinyint] NOT NULL,
	[Status] [tinyint] NOT NULL,
	[AttemptCount] [int] NOT NULL,
	[MaxAttempts] [int] NOT NULL,
	[NextAttemptAt] [datetime] NOT NULL,
	[LastAttemptAt] [datetime] NULL,
	[ProcessedAt] [datetime] NULL,
	[LastError] [nvarchar](1000) NULL,
	[CreatedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_NotificationOutbox] PRIMARY KEY CLUSTERED 
(
	[OutboxID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Notifications]    Script Date: 3/13/2026 6:20:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Notifications](
	[NotificationID] [int] IDENTITY(1,1) NOT NULL,
	[UserID] [int] NOT NULL,
	[EventID] [int] NULL,
	[Title] [nvarchar](200) NOT NULL,
	[Content] [nvarchar](max) NOT NULL,
	[NotificationTypeID] [int] NOT NULL,
	[Priority] [tinyint] NULL,
	[IsRead] [bit] NULL,
	[ReadDate] [datetime] NULL,
	[ActionUrl] [nvarchar](255) NULL,
	[CreatedDate] [datetime] NULL,
	[ExpiryDate] [datetime] NULL,
	[DedupKey] [nvarchar](200) NULL,
	[Audience] [nvarchar](30) NULL,
	[TargetRole] [nvarchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[NotificationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[NotificationType]    Script Date: 3/13/2026 6:20:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[NotificationType](
	[TypeID] [int] IDENTITY(1,1) NOT NULL,
	[TypeName] [nvarchar](200) NOT NULL,
	[Template] [nvarchar](max) NULL,
	[CreatedDate] [datetime] NULL,
	[Locale] [nvarchar](10) NULL,
	[TemplateVersion] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[TypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[PasswordResetOtps]    Script Date: 3/13/2026 6:20:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PasswordResetOtps](
	[OtpID] [int] IDENTITY(1,1) NOT NULL,
	[UserID] [int] NOT NULL,
	[OtpHash] [nvarchar](200) NOT NULL,
	[Purpose] [nvarchar](50) NOT NULL,
	[ExpiresAt] [datetime] NOT NULL,
	[AttemptCount] [int] NOT NULL,
	[MaxAttempts] [int] NOT NULL,
	[ResendCount] [int] NOT NULL,
	[MaxResends] [int] NOT NULL,
	[IsUsed] [bit] NOT NULL,
	[VerifiedAt] [datetime] NULL,
	[UsedAt] [datetime] NULL,
	[RevokedAt] [datetime] NULL,
	[CreatedDate] [datetime] NOT NULL,
	[LastSentAt] [datetime] NOT NULL,
	[RequestIp] [nvarchar](64) NULL,
	[RequestUserAgent] [nvarchar](512) NULL,
 CONSTRAINT [PK_PasswordResetOtps] PRIMARY KEY CLUSTERED 
(
	[OtpID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[PasswordResetSessions]    Script Date: 3/13/2026 6:20:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PasswordResetSessions](
	[ResetSessionID] [int] IDENTITY(1,1) NOT NULL,
	[UserID] [int] NOT NULL,
	[OtpID] [int] NOT NULL,
	[SessionTokenHash] [nvarchar](200) NOT NULL,
	[ExpiresAt] [datetime] NOT NULL,
	[IsUsed] [bit] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[UsedAt] [datetime] NULL,
 CONSTRAINT [PK_PasswordResetSessions] PRIMARY KEY CLUSTERED 
(
	[ResetSessionID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[PasswordResetTokens]    Script Date: 3/13/2026 6:20:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PasswordResetTokens](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[UserID] [int] NOT NULL,
	[Token] [nvarchar](200) NOT NULL,
	[ExpiredAt] [datetime] NOT NULL,
	[IsUsed] [bit] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_PasswordResetTokens] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Roles]    Script Date: 3/13/2026 6:20:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Roles](
	[RoleID] [int] IDENTITY(1,1) NOT NULL,
	[RoleName] [nvarchar](50) NOT NULL,
	[CreatedDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[RoleID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SystemSettings]    Script Date: 3/13/2026 6:20:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SystemSettings](
	[SettingID] [int] IDENTITY(1,1) NOT NULL,
	[SettingKey] [nvarchar](100) NOT NULL,
	[SettingValue] [nvarchar](max) NOT NULL,
	[DataType] [nvarchar](50) NULL,
	[Description] [nvarchar](255) NULL,
	[UpdatedBy] [int] NULL,
	[UpdatedDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[SettingID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Units]    Script Date: 3/13/2026 6:20:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Units](
	[UnitID] [int] IDENTITY(1,1) NOT NULL,
	[UnitName] [nvarchar](100) NOT NULL,
	[UnitType] [nvarchar](50) NOT NULL,
	[InstituteID] [int] NOT NULL,
	[ParentUnitID] [int] NULL,
	[Description] [nvarchar](255) NULL,
	[Status] [tinyint] NULL,
	[CreatedDate] [datetime] NULL,
	[UpdatedDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[UnitID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[UserDeviceTokens]    Script Date: 3/13/2026 6:20:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserDeviceTokens](
	[UserDeviceTokenID] [int] IDENTITY(1,1) NOT NULL,
	[UserID] [int] NOT NULL,
	[Platform] [nvarchar](20) NOT NULL,
	[Token] [nvarchar](512) NOT NULL,
	[DeviceId] [nvarchar](100) NULL,
	[IsActive] [bit] NOT NULL,
	[LastSeenAt] [datetime] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_UserDeviceTokens] PRIMARY KEY CLUSTERED 
(
	[UserDeviceTokenID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[UserNotificationPreferences]    Script Date: 3/13/2026 6:20:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserNotificationPreferences](
	[PreferenceID] [int] IDENTITY(1,1) NOT NULL,
	[UserID] [int] NOT NULL,
	[NotificationTypeID] [int] NOT NULL,
	[IsInAppEnabled] [bit] NOT NULL,
	[IsRealtimeEnabled] [bit] NOT NULL,
	[IsPushEnabled] [bit] NOT NULL,
	[IsMuted] [bit] NOT NULL,
	[QuietHoursStartMinute] [smallint] NULL,
	[QuietHoursEndMinute] [smallint] NULL,
	[CreatedDate] [datetime] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_UserNotificationPreferences] PRIMARY KEY CLUSTERED 
(
	[PreferenceID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[UserRoles]    Script Date: 3/13/2026 6:20:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserRoles](
	[UserRoleID] [int] IDENTITY(1,1) NOT NULL,
	[UserID] [int] NOT NULL,
	[RoleID] [int] NOT NULL,
	[AssignDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[UserRoleID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[UserUnits]    Script Date: 3/13/2026 6:20:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserUnits](
	[UserUnitID] [int] IDENTITY(1,1) NOT NULL,
	[UserID] [int] NOT NULL,
	[UnitID] [int] NOT NULL,
	[JoinDate] [date] NOT NULL,
	[Position] [nvarchar](50) NULL,
	[Status] [tinyint] NULL,
	[CreatedDate] [datetime] NULL,
	[UpdatedDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[UserUnitID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
SET IDENTITY_INSERT [dbo].[ActivityPoints] ON 

INSERT [dbo].[ActivityPoints] ([PointID], [EventID], [UserID], [EventPointID], [Points], [PointType], [AwardedBy], [CreatedDate]) VALUES (1, 8, 4, 16, 10, N'Attendance', NULL, CAST(N'2026-01-04T06:07:50.437' AS DateTime))
INSERT [dbo].[ActivityPoints] ([PointID], [EventID], [UserID], [EventPointID], [Points], [PointType], [AwardedBy], [CreatedDate]) VALUES (2, 7, 5, 15, 10, N'Attendance', NULL, CAST(N'2026-01-04T06:12:28.297' AS DateTime))
INSERT [dbo].[ActivityPoints] ([PointID], [EventID], [UserID], [EventPointID], [Points], [PointType], [AwardedBy], [CreatedDate]) VALUES (3, 10, 5, 18, 10, N'Attendance', NULL, CAST(N'2026-01-04T06:22:18.147' AS DateTime))
INSERT [dbo].[ActivityPoints] ([PointID], [EventID], [UserID], [EventPointID], [Points], [PointType], [AwardedBy], [CreatedDate]) VALUES (4, 9, 4, 17, 10, N'Attendance', NULL, CAST(N'2026-01-07T02:30:49.877' AS DateTime))
INSERT [dbo].[ActivityPoints] ([PointID], [EventID], [UserID], [EventPointID], [Points], [PointType], [AwardedBy], [CreatedDate]) VALUES (5, 10, 4, 18, 10, N'Attendance', NULL, CAST(N'2026-01-09T02:00:14.637' AS DateTime))
INSERT [dbo].[ActivityPoints] ([PointID], [EventID], [UserID], [EventPointID], [Points], [PointType], [AwardedBy], [CreatedDate]) VALUES (1005, 1013, 4, NULL, 10, N'Attendance', NULL, CAST(N'2026-02-02T10:19:01.040' AS DateTime))
INSERT [dbo].[ActivityPoints] ([PointID], [EventID], [UserID], [EventPointID], [Points], [PointType], [AwardedBy], [CreatedDate]) VALUES (1007, 1016, 4, 24, 10, N'@p3', NULL, CAST(N'2026-02-25T19:37:54.210' AS DateTime))
SET IDENTITY_INSERT [dbo].[ActivityPoints] OFF
GO
SET IDENTITY_INSERT [dbo].[Attendances] ON 

INSERT [dbo].[Attendances] ([AttendanceID], [EventID], [UserID], [QRID], [CheckInMethod], [CheckInTime], [UserLatitude], [UserLongitude], [Distance], [FaceVerified], [FaceConfidence], [IsValid], [InvalidReason], [IPAddress], [DeviceInfo], [CreatedDate]) VALUES (1, 4, 4, 3, N'QR_GPS', CAST(N'2026-01-02T07:44:35.703' AS DateTime), CAST(90.000000 AS Decimal(10, 6)), CAST(180.000000 AS Decimal(10, 6)), 8809418.063415166, 0, NULL, 0, N'Vị trí quá xa (8809418m). Phạm vi cho phép: 100m', N'::1', N'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36 Edg/143.0.0.0', CAST(N'2026-01-02T07:44:35.703' AS DateTime))
INSERT [dbo].[Attendances] ([AttendanceID], [EventID], [UserID], [QRID], [CheckInMethod], [CheckInTime], [UserLatitude], [UserLongitude], [Distance], [FaceVerified], [FaceConfidence], [IsValid], [InvalidReason], [IPAddress], [DeviceInfo], [CreatedDate]) VALUES (2, 5, 4, 6, N'QR_GPS', CAST(N'2026-01-02T11:44:24.760' AS DateTime), CAST(10.775000 AS Decimal(10, 6)), CAST(106.700000 AS Decimal(10, 6)), 0, 0, NULL, 1, NULL, N'::1', N'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36 Edg/143.0.0.0', CAST(N'2026-01-02T11:44:24.760' AS DateTime))
INSERT [dbo].[Attendances] ([AttendanceID], [EventID], [UserID], [QRID], [CheckInMethod], [CheckInTime], [UserLatitude], [UserLongitude], [Distance], [FaceVerified], [FaceConfidence], [IsValid], [InvalidReason], [IPAddress], [DeviceInfo], [CreatedDate]) VALUES (3, 6, 4, 10, N'QR_GPS', CAST(N'2026-01-04T02:24:06.457' AS DateTime), CAST(10.775000 AS Decimal(10, 6)), CAST(106.700000 AS Decimal(10, 6)), 0, 0, NULL, 1, NULL, N'::1', N'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36 Edg/143.0.0.0', CAST(N'2026-01-04T02:24:06.457' AS DateTime))
INSERT [dbo].[Attendances] ([AttendanceID], [EventID], [UserID], [QRID], [CheckInMethod], [CheckInTime], [UserLatitude], [UserLongitude], [Distance], [FaceVerified], [FaceConfidence], [IsValid], [InvalidReason], [IPAddress], [DeviceInfo], [CreatedDate]) VALUES (4, 7, 4, 11, N'QR_GPS', CAST(N'2026-01-04T06:05:24.717' AS DateTime), CAST(10.771900 AS Decimal(10, 6)), CAST(106.699500 AS Decimal(10, 6)), 651.90567791506828, 0, NULL, 0, N'Vị trí quá xa (652m). Phạm vi cho phép: 150m', N'::1', N'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36 Edg/143.0.0.0', CAST(N'2026-01-04T06:05:24.717' AS DateTime))
INSERT [dbo].[Attendances] ([AttendanceID], [EventID], [UserID], [QRID], [CheckInMethod], [CheckInTime], [UserLatitude], [UserLongitude], [Distance], [FaceVerified], [FaceConfidence], [IsValid], [InvalidReason], [IPAddress], [DeviceInfo], [CreatedDate]) VALUES (5, 8, 4, 12, N'QR_GPS', CAST(N'2026-01-04T06:07:50.350' AS DateTime), CAST(10.776500 AS Decimal(10, 6)), CAST(106.695800 AS Decimal(10, 6)), 0, 0, NULL, 1, NULL, N'::1', N'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36 Edg/143.0.0.0', CAST(N'2026-01-04T06:07:50.350' AS DateTime))
INSERT [dbo].[Attendances] ([AttendanceID], [EventID], [UserID], [QRID], [CheckInMethod], [CheckInTime], [UserLatitude], [UserLongitude], [Distance], [FaceVerified], [FaceConfidence], [IsValid], [InvalidReason], [IPAddress], [DeviceInfo], [CreatedDate]) VALUES (6, 7, 5, 11, N'QR_GPS', CAST(N'2026-01-04T06:12:28.227' AS DateTime), CAST(10.776500 AS Decimal(10, 6)), CAST(106.695800 AS Decimal(10, 6)), 0, 0, NULL, 1, NULL, N'::1', N'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36 Edg/143.0.0.0', CAST(N'2026-01-04T06:12:28.227' AS DateTime))
INSERT [dbo].[Attendances] ([AttendanceID], [EventID], [UserID], [QRID], [CheckInMethod], [CheckInTime], [UserLatitude], [UserLongitude], [Distance], [FaceVerified], [FaceConfidence], [IsValid], [InvalidReason], [IPAddress], [DeviceInfo], [CreatedDate]) VALUES (7, 8, 5, 12, N'QR_GPS', CAST(N'2026-01-04T06:13:43.433' AS DateTime), CAST(10.771900 AS Decimal(10, 6)), CAST(106.699500 AS Decimal(10, 6)), 651.90567791506828, 0, NULL, 0, N'Vị trí quá xa (652m). Phạm vi cho phép: 150m', N'::1', N'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36 Edg/143.0.0.0', CAST(N'2026-01-04T06:13:43.433' AS DateTime))
INSERT [dbo].[Attendances] ([AttendanceID], [EventID], [UserID], [QRID], [CheckInMethod], [CheckInTime], [UserLatitude], [UserLongitude], [Distance], [FaceVerified], [FaceConfidence], [IsValid], [InvalidReason], [IPAddress], [DeviceInfo], [CreatedDate]) VALUES (8, 9, 5, 13, N'QR_GPS', CAST(N'2026-01-04T06:15:56.983' AS DateTime), CAST(10.771900 AS Decimal(10, 6)), CAST(106.699500 AS Decimal(10, 6)), 651.90567791506828, 0, NULL, 0, N'Vị trí quá xa (652m). Phạm vi cho phép: 150m', N'::1', N'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36 Edg/143.0.0.0', CAST(N'2026-01-04T06:15:56.983' AS DateTime))
INSERT [dbo].[Attendances] ([AttendanceID], [EventID], [UserID], [QRID], [CheckInMethod], [CheckInTime], [UserLatitude], [UserLongitude], [Distance], [FaceVerified], [FaceConfidence], [IsValid], [InvalidReason], [IPAddress], [DeviceInfo], [CreatedDate]) VALUES (9, 10, 5, 14, N'QR_GPS', CAST(N'2026-01-04T06:22:17.660' AS DateTime), CAST(10.776500 AS Decimal(10, 6)), CAST(106.695800 AS Decimal(10, 6)), 0, 0, NULL, 1, NULL, N'::1', N'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36 Edg/143.0.0.0', CAST(N'2026-01-04T06:22:17.660' AS DateTime))
INSERT [dbo].[Attendances] ([AttendanceID], [EventID], [UserID], [QRID], [CheckInMethod], [CheckInTime], [UserLatitude], [UserLongitude], [Distance], [FaceVerified], [FaceConfidence], [IsValid], [InvalidReason], [IPAddress], [DeviceInfo], [CreatedDate]) VALUES (10, 9, 4, 13, N'QR_GPS', CAST(N'2026-01-07T02:30:49.497' AS DateTime), CAST(10.776500 AS Decimal(10, 6)), CAST(106.695800 AS Decimal(10, 6)), 0, 0, NULL, 1, NULL, N'::1', N'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36 Edg/143.0.0.0', CAST(N'2026-01-07T02:30:49.497' AS DateTime))
INSERT [dbo].[Attendances] ([AttendanceID], [EventID], [UserID], [QRID], [CheckInMethod], [CheckInTime], [UserLatitude], [UserLongitude], [Distance], [FaceVerified], [FaceConfidence], [IsValid], [InvalidReason], [IPAddress], [DeviceInfo], [CreatedDate]) VALUES (11, 10, 4, 14, N'QR_GPS', CAST(N'2026-01-09T02:00:14.313' AS DateTime), CAST(10.776500 AS Decimal(10, 6)), CAST(106.695800 AS Decimal(10, 6)), 0, 0, NULL, 1, NULL, N'::1', N'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36 Edg/143.0.0.0', CAST(N'2026-01-09T02:00:14.313' AS DateTime))
INSERT [dbo].[Attendances] ([AttendanceID], [EventID], [UserID], [QRID], [CheckInMethod], [CheckInTime], [UserLatitude], [UserLongitude], [Distance], [FaceVerified], [FaceConfidence], [IsValid], [InvalidReason], [IPAddress], [DeviceInfo], [CreatedDate]) VALUES (1011, 1016, 4, 18, N'QR_GPS', CAST(N'2026-02-02T02:23:42.257' AS DateTime), CAST(90.000000 AS Decimal(10, 6)), CAST(180.000000 AS Decimal(10, 6)), 0, 0, NULL, 1, NULL, N'::1', N'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0', CAST(N'2026-02-02T02:23:42.257' AS DateTime))
INSERT [dbo].[Attendances] ([AttendanceID], [EventID], [UserID], [QRID], [CheckInMethod], [CheckInTime], [UserLatitude], [UserLongitude], [Distance], [FaceVerified], [FaceConfidence], [IsValid], [InvalidReason], [IPAddress], [DeviceInfo], [CreatedDate]) VALUES (1012, 1018, 4, 20, N'QR_GPS', CAST(N'2026-02-02T02:31:02.580' AS DateTime), CAST(10.000000 AS Decimal(10, 6)), CAST(10.000000 AS Decimal(10, 6)), 8895594.1315646973, 0, NULL, 0, N'Vị trí quá xa (8895594m). Phạm vi cho phép: 100m', N'::1', N'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0', CAST(N'2026-02-02T02:31:02.580' AS DateTime))
INSERT [dbo].[Attendances] ([AttendanceID], [EventID], [UserID], [QRID], [CheckInMethod], [CheckInTime], [UserLatitude], [UserLongitude], [Distance], [FaceVerified], [FaceConfidence], [IsValid], [InvalidReason], [IPAddress], [DeviceInfo], [CreatedDate]) VALUES (1013, 1028, 4, 34, N'QR_GPS', CAST(N'2026-02-20T14:38:29.043' AS DateTime), CAST(11.016823 AS Decimal(10, 6)), CAST(106.713946 AS Decimal(10, 6)), 0, 0, NULL, 1, NULL, N'::1', N'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0', CAST(N'2026-02-20T14:38:29.043' AS DateTime))
SET IDENTITY_INSERT [dbo].[Attendances] OFF
GO
SET IDENTITY_INSERT [dbo].[AuditLogs] ON 

INSERT [dbo].[AuditLogs] ([AuditID], [UserID], [Action], [TableName], [RecordID], [OldValue], [NewValue], [IPAddress], [UserAgent], [CreatedDate]) VALUES (1, 4, N'ATTENDANCE_CHECKIN_FAILED', N'EventRegistrations', 1017, NULL, N'{"reason":"USER_NOT_REGISTERED","eventId":1017,"qrId":19}', N'::1', N'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0', CAST(N'2026-02-02T02:23:18.347' AS DateTime))
INSERT [dbo].[AuditLogs] ([AuditID], [UserID], [Action], [TableName], [RecordID], [OldValue], [NewValue], [IPAddress], [UserAgent], [CreatedDate]) VALUES (2, 4, N'ATTENDANCE_CHECKIN_FAILED', N'EventQRCodes', 20, NULL, N'{"reason":"QR_NOT_STARTED","eventId":1018,"qrId":20,"validFromUtc":"2026-02-02T02:30:00","nowUtc":"2026-02-02T02:27:15.6521174Z"}', N'::1', N'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0', CAST(N'2026-02-02T02:27:15.653' AS DateTime))
INSERT [dbo].[AuditLogs] ([AuditID], [UserID], [Action], [TableName], [RecordID], [OldValue], [NewValue], [IPAddress], [UserAgent], [CreatedDate]) VALUES (3, 4, N'ATTENDANCE_CHECKIN_FAILED', N'Events', 1018, NULL, N'{"reason":"EVENT_NOT_ONGOING","eventId":1018,"currentStatus":1,"qrId":20}', N'::1', N'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0', CAST(N'2026-02-02T02:30:17.193' AS DateTime))
INSERT [dbo].[AuditLogs] ([AuditID], [UserID], [Action], [TableName], [RecordID], [OldValue], [NewValue], [IPAddress], [UserAgent], [CreatedDate]) VALUES (4, 4, N'ATTENDANCE_CHECKIN_FAILED', N'Attendances', 1012, NULL, N'{"reason":"DUPLICATE_CHECKIN","eventId":1018,"existingAttendanceId":1012,"existingCheckInTimeUtc":"2026-02-02T02:31:02.58"}', N'::1', N'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0', CAST(N'2026-02-02T02:31:53.367' AS DateTime))
INSERT [dbo].[AuditLogs] ([AuditID], [UserID], [Action], [TableName], [RecordID], [OldValue], [NewValue], [IPAddress], [UserAgent], [CreatedDate]) VALUES (5, 4, N'ATTENDANCE_CHECKIN_FAILED', N'Attendances', 1012, NULL, N'{"reason":"DUPLICATE_CHECKIN","eventId":1018,"existingAttendanceId":1012,"existingCheckInTimeUtc":"2026-02-02T02:31:02.58"}', N'::1', N'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0', CAST(N'2026-02-02T02:33:06.953' AS DateTime))
INSERT [dbo].[AuditLogs] ([AuditID], [UserID], [Action], [TableName], [RecordID], [OldValue], [NewValue], [IPAddress], [UserAgent], [CreatedDate]) VALUES (6, 4, N'ATTENDANCE_CHECKIN_FAILED', N'EventQRCodes', 36, NULL, N'{"reason":"QR_EXPIRED","eventId":1034,"qrId":36,"validUntilUtc":"2026-02-22T11:20:00","nowUtc":"2026-02-25T19:26:58.9852899+07:00"}', N'192.168.1.7', N'Dart/3.10 (dart:io)', CAST(N'2026-02-25T19:26:58.987' AS DateTime))
INSERT [dbo].[AuditLogs] ([AuditID], [UserID], [Action], [TableName], [RecordID], [OldValue], [NewValue], [IPAddress], [UserAgent], [CreatedDate]) VALUES (7, 4, N'ATTENDANCE_CHECKIN_FAILED', N'Events', 1036, NULL, N'{"reason":"EVENT_NOT_ONGOING","eventId":1036,"currentStatus":1,"qrId":37}', N'192.168.1.7', N'Dart/3.10 (dart:io)', CAST(N'2026-02-25T19:33:08.143' AS DateTime))
INSERT [dbo].[AuditLogs] ([AuditID], [UserID], [Action], [TableName], [RecordID], [OldValue], [NewValue], [IPAddress], [UserAgent], [CreatedDate]) VALUES (8, 4, N'ATTENDANCE_CHECKIN_FAILED', N'Events', 1037, NULL, N'{"reason":"EVENT_NOT_ONGOING","eventId":1037,"currentStatus":1,"qrId":38}', N'192.168.1.7', N'Dart/3.10 (dart:io)', CAST(N'2026-02-25T19:36:38.227' AS DateTime))
INSERT [dbo].[AuditLogs] ([AuditID], [UserID], [Action], [TableName], [RecordID], [OldValue], [NewValue], [IPAddress], [UserAgent], [CreatedDate]) VALUES (9, 4, N'ATTENDANCE_CHECKIN_FAILED', N'EventQRCodes', 35, NULL, N'{"reason":"QR_EXPIRED","eventId":1033,"qrId":35,"validUntilUtc":"2026-02-22T11:18:00","nowUtc":"2026-02-27T09:27:02.3358136+07:00"}', N'::1', N'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', CAST(N'2026-02-27T09:27:02.337' AS DateTime))
INSERT [dbo].[AuditLogs] ([AuditID], [UserID], [Action], [TableName], [RecordID], [OldValue], [NewValue], [IPAddress], [UserAgent], [CreatedDate]) VALUES (10, 4, N'ATTENDANCE_CHECKIN_FAILED', N'EventQRCodes', 36, NULL, N'{"reason":"QR_EXPIRED","eventId":1034,"qrId":36,"validUntilUtc":"2026-02-22T11:20:00","nowUtc":"2026-02-27T09:35:21.0541613+07:00"}', N'192.168.1.7', N'Dart/3.10 (dart:io)', CAST(N'2026-02-27T09:35:21.053' AS DateTime))
INSERT [dbo].[AuditLogs] ([AuditID], [UserID], [Action], [TableName], [RecordID], [OldValue], [NewValue], [IPAddress], [UserAgent], [CreatedDate]) VALUES (11, 4, N'ATTENDANCE_CHECKIN_FAILED', N'EventQRCodes', 36, NULL, N'{"reason":"QR_EXPIRED","eventId":1034,"qrId":36,"validUntilUtc":"2026-02-22T11:20:00","nowUtc":"2026-03-04T19:16:12.7506184+07:00"}', N'192.168.1.7', N'Dart/3.10 (dart:io)', CAST(N'2026-03-04T19:16:12.750' AS DateTime))
INSERT [dbo].[AuditLogs] ([AuditID], [UserID], [Action], [TableName], [RecordID], [OldValue], [NewValue], [IPAddress], [UserAgent], [CreatedDate]) VALUES (12, 4, N'ATTENDANCE_CHECKIN_FAILED', N'EventQRCodes', 36, NULL, N'{"reason":"QR_EXPIRED","eventId":1034,"qrId":36,"validUntilUtc":"2026-02-22T11:20:00","nowUtc":"2026-03-04T19:16:22.1297993+07:00"}', N'192.168.1.7', N'Dart/3.10 (dart:io)', CAST(N'2026-03-04T19:16:22.130' AS DateTime))
INSERT [dbo].[AuditLogs] ([AuditID], [UserID], [Action], [TableName], [RecordID], [OldValue], [NewValue], [IPAddress], [UserAgent], [CreatedDate]) VALUES (13, 4, N'ATTENDANCE_CHECKIN_FAILED', N'EventQRCodes', 36, NULL, N'{"reason":"QR_EXPIRED","eventId":1034,"qrId":36,"validUntilUtc":"2026-02-22T11:20:00","nowUtc":"2026-03-05T14:20:40.6469433+07:00"}', N'10.15.148.215', N'Dart/3.10 (dart:io)', CAST(N'2026-03-05T14:20:40.647' AS DateTime))
INSERT [dbo].[AuditLogs] ([AuditID], [UserID], [Action], [TableName], [RecordID], [OldValue], [NewValue], [IPAddress], [UserAgent], [CreatedDate]) VALUES (14, 4, N'ATTENDANCE_CHECKIN_FAILED', N'EventQRCodes', NULL, NULL, N'{"reason":"QR_NOT_FOUND","qrTokenPreview":"https://za...","latitude":10.9801754,"longitude":106.6744773}', N'10.15.148.215', N'Dart/3.10 (dart:io)', CAST(N'2026-03-05T14:25:52.353' AS DateTime))
INSERT [dbo].[AuditLogs] ([AuditID], [UserID], [Action], [TableName], [RecordID], [OldValue], [NewValue], [IPAddress], [UserAgent], [CreatedDate]) VALUES (15, 4, N'ATTENDANCE_CHECKIN_FAILED', N'EventQRCodes', NULL, NULL, N'{"reason":"QR_NOT_FOUND","qrTokenPreview":"https://za...","latitude":10.9801754,"longitude":106.6744773}', N'10.15.148.215', N'Dart/3.10 (dart:io)', CAST(N'2026-03-05T14:25:59.307' AS DateTime))
INSERT [dbo].[AuditLogs] ([AuditID], [UserID], [Action], [TableName], [RecordID], [OldValue], [NewValue], [IPAddress], [UserAgent], [CreatedDate]) VALUES (16, 4, N'ATTENDANCE_CHECKIN_FAILED', N'EventQRCodes', NULL, NULL, N'{"reason":"QR_NOT_FOUND","qrTokenPreview":"https://za...","latitude":10.9801754,"longitude":106.6744773}', N'10.15.148.215', N'Dart/3.10 (dart:io)', CAST(N'2026-03-05T14:26:01.907' AS DateTime))
INSERT [dbo].[AuditLogs] ([AuditID], [UserID], [Action], [TableName], [RecordID], [OldValue], [NewValue], [IPAddress], [UserAgent], [CreatedDate]) VALUES (17, 4, N'ATTENDANCE_CHECKIN_FAILED', N'EventQRCodes', NULL, NULL, N'{"reason":"QR_NOT_FOUND","qrTokenPreview":"https://za...","latitude":10.9801754,"longitude":106.6744773}', N'10.15.148.215', N'Dart/3.10 (dart:io)', CAST(N'2026-03-05T14:26:03.823' AS DateTime))
INSERT [dbo].[AuditLogs] ([AuditID], [UserID], [Action], [TableName], [RecordID], [OldValue], [NewValue], [IPAddress], [UserAgent], [CreatedDate]) VALUES (18, 4, N'ATTENDANCE_CHECKIN_FAILED', N'EventQRCodes', NULL, NULL, N'{"reason":"QR_NOT_FOUND","qrTokenPreview":"https://za...","latitude":10.9801754,"longitude":106.6744773}', N'10.15.148.215', N'Dart/3.10 (dart:io)', CAST(N'2026-03-05T14:26:05.283' AS DateTime))
INSERT [dbo].[AuditLogs] ([AuditID], [UserID], [Action], [TableName], [RecordID], [OldValue], [NewValue], [IPAddress], [UserAgent], [CreatedDate]) VALUES (19, 4, N'ATTENDANCE_CHECKIN_FAILED', N'EventQRCodes', NULL, NULL, N'{"reason":"QR_NOT_FOUND","qrTokenPreview":"https://za...","latitude":10.9801979,"longitude":106.6744888}', N'10.15.148.215', N'Dart/3.10 (dart:io)', CAST(N'2026-03-05T14:26:13.803' AS DateTime))
INSERT [dbo].[AuditLogs] ([AuditID], [UserID], [Action], [TableName], [RecordID], [OldValue], [NewValue], [IPAddress], [UserAgent], [CreatedDate]) VALUES (20, 4, N'ATTENDANCE_CHECKIN_FAILED', N'EventQRCodes', 36, NULL, N'{"reason":"QR_EXPIRED","eventId":1034,"qrId":36,"validUntilUtc":"2026-02-22T11:20:00","nowUtc":"2026-03-05T14:29:45.2599309+07:00"}', N'10.15.148.215', N'Dart/3.10 (dart:io)', CAST(N'2026-03-05T14:29:45.260' AS DateTime))
INSERT [dbo].[AuditLogs] ([AuditID], [UserID], [Action], [TableName], [RecordID], [OldValue], [NewValue], [IPAddress], [UserAgent], [CreatedDate]) VALUES (21, 4, N'ATTENDANCE_CHECKIN_FAILED', N'EventQRCodes', 35, NULL, N'{"reason":"QR_EXPIRED","eventId":1033,"qrId":35,"validUntilUtc":"2026-02-22T11:18:00","nowUtc":"2026-03-11T20:36:43.8786419+07:00"}', N'192.168.1.7', N'Dart/3.10 (dart:io)', CAST(N'2026-03-11T20:36:43.880' AS DateTime))
INSERT [dbo].[AuditLogs] ([AuditID], [UserID], [Action], [TableName], [RecordID], [OldValue], [NewValue], [IPAddress], [UserAgent], [CreatedDate]) VALUES (22, 4, N'ATTENDANCE_CHECKIN_FAILED', N'EventQRCodes', 35, NULL, N'{"reason":"QR_EXPIRED","eventId":1033,"qrId":35,"validUntilUtc":"2026-02-22T11:18:00","nowUtc":"2026-03-11T20:36:48.1727948+07:00"}', N'192.168.1.7', N'Dart/3.10 (dart:io)', CAST(N'2026-03-11T20:36:48.173' AS DateTime))
SET IDENTITY_INSERT [dbo].[AuditLogs] OFF
GO
SET IDENTITY_INSERT [dbo].[EventImages] ON 

INSERT [dbo].[EventImages] ([ImageID], [EventID], [ImageUrl], [ImageType], [Caption], [DisplayOrder], [CreatedDate]) VALUES (1, 1, N'/uploads/events/1/event_1_f246a30d85cc47aa8e28f66501166230.jpg', N'Gallery', N'Event', 1, CAST(N'2025-12-29T01:50:44.883' AS DateTime))
INSERT [dbo].[EventImages] ([ImageID], [EventID], [ImageUrl], [ImageType], [Caption], [DisplayOrder], [CreatedDate]) VALUES (3, 2, N'/uploads/events/2/event_2_5d2181653d32426b8450f5cb2e63ea9c.jpg', N'Gallery', N'Event', 1, CAST(N'2025-12-29T01:51:39.223' AS DateTime))
INSERT [dbo].[EventImages] ([ImageID], [EventID], [ImageUrl], [ImageType], [Caption], [DisplayOrder], [CreatedDate]) VALUES (4, 2, N'/uploads/events/2/event_2_eed3336333fa4542854950f8b53b8674.jpg', N'Gallery', N'Event', 2, CAST(N'2025-12-29T02:02:49.197' AS DateTime))
INSERT [dbo].[EventImages] ([ImageID], [EventID], [ImageUrl], [ImageType], [Caption], [DisplayOrder], [CreatedDate]) VALUES (5, 2, N'/uploads/events/2/event_2_a6d0fbb08c40444d94d0d331d229007d.jpg', N'Gallery', N'Event', 4, CAST(N'2025-12-29T02:02:49.273' AS DateTime))
INSERT [dbo].[EventImages] ([ImageID], [EventID], [ImageUrl], [ImageType], [Caption], [DisplayOrder], [CreatedDate]) VALUES (1004, 1012, N'/uploads/events/1012/event_1012_a5304c23ea79475bb620188a35686977.jpg', N'Banner', NULL, 2, CAST(N'2026-01-25T08:27:05.940' AS DateTime))
INSERT [dbo].[EventImages] ([ImageID], [EventID], [ImageUrl], [ImageType], [Caption], [DisplayOrder], [CreatedDate]) VALUES (1005, 1012, N'/uploads/events/1012/event_1012_3580ea5cecbe4be19cabdfd72258dc8a.jpg', N'Gallery', NULL, 1, CAST(N'2026-01-25T08:54:41.097' AS DateTime))
INSERT [dbo].[EventImages] ([ImageID], [EventID], [ImageUrl], [ImageType], [Caption], [DisplayOrder], [CreatedDate]) VALUES (1010, 1011, N'/uploads/events/1011/event_1011_2352859b04314e669c4ad1e145cdd005.jpg', N'Banner', NULL, 1, CAST(N'2026-01-26T08:09:11.460' AS DateTime))
INSERT [dbo].[EventImages] ([ImageID], [EventID], [ImageUrl], [ImageType], [Caption], [DisplayOrder], [CreatedDate]) VALUES (1011, 1012, N'/uploads/events/1012/event_1012_6e66e995f7054f5a867219c418d6f5ac.jpg', N'Thumbnail', NULL, 3, CAST(N'2026-01-26T08:51:21.793' AS DateTime))
INSERT [dbo].[EventImages] ([ImageID], [EventID], [ImageUrl], [ImageType], [Caption], [DisplayOrder], [CreatedDate]) VALUES (2009, 1018, N'/uploads/events/1018/event_1018_42857cde65054670ac479be1e30e5f05.jpg', N'Thumbnail', N'string', 1, CAST(N'2026-02-02T11:52:35.113' AS DateTime))
INSERT [dbo].[EventImages] ([ImageID], [EventID], [ImageUrl], [ImageType], [Caption], [DisplayOrder], [CreatedDate]) VALUES (2010, 1018, N'/uploads/events/1018/event_1018_cbac71a7870a488d989f6e42172600b1.jpg', N'Banner', N'string', 2, CAST(N'2026-02-02T11:54:10.863' AS DateTime))
INSERT [dbo].[EventImages] ([ImageID], [EventID], [ImageUrl], [ImageType], [Caption], [DisplayOrder], [CreatedDate]) VALUES (2016, 1021, N'/uploads/events/1021/event_1021_9c4a93018f5d4ed19e4873f3f92da417.jpg', N'Thumbnail', NULL, 1, CAST(N'2026-02-11T14:19:24.397' AS DateTime))
INSERT [dbo].[EventImages] ([ImageID], [EventID], [ImageUrl], [ImageType], [Caption], [DisplayOrder], [CreatedDate]) VALUES (3016, 1025, N'/uploads/events/1025/event_1025_057522086b0e4f51a8ff92e2108b19d7.jpg', N'Banner', NULL, 2, CAST(N'2026-02-11T19:54:30.177' AS DateTime))
INSERT [dbo].[EventImages] ([ImageID], [EventID], [ImageUrl], [ImageType], [Caption], [DisplayOrder], [CreatedDate]) VALUES (3017, 1025, N'/uploads/events/1025/event_1025_8206fb0192324413b86ffa9e5bf73063.jpg', N'Thumbnail', NULL, 3, CAST(N'2026-02-13T14:52:09.200' AS DateTime))
INSERT [dbo].[EventImages] ([ImageID], [EventID], [ImageUrl], [ImageType], [Caption], [DisplayOrder], [CreatedDate]) VALUES (3018, 1, N'/uploads/events/1/event_1_061fa2086baa4d0c889081ed79178b93.jpg', N'Banner', N'string', 2, CAST(N'2026-02-13T14:54:45.150' AS DateTime))
INSERT [dbo].[EventImages] ([ImageID], [EventID], [ImageUrl], [ImageType], [Caption], [DisplayOrder], [CreatedDate]) VALUES (3020, 1022, N'/uploads/events/1022/event_1022_e2e19144e2344512ab359889cd7e094e.jpg', N'Thumbnail', NULL, 1, CAST(N'2026-02-13T15:41:42.273' AS DateTime))
INSERT [dbo].[EventImages] ([ImageID], [EventID], [ImageUrl], [ImageType], [Caption], [DisplayOrder], [CreatedDate]) VALUES (3023, 1037, N'/uploads/events/1037/event_1037_c274e6cbad3b4980b415a848e08ac894.jpg', N'Banner', NULL, 1, CAST(N'2026-02-28T08:58:38.740' AS DateTime))
SET IDENTITY_INSERT [dbo].[EventImages] OFF
GO
SET IDENTITY_INSERT [dbo].[EventPoints] ON 

INSERT [dbo].[EventPoints] ([EventPointID], [EventID], [RoleType], [Points], [Description], [CreatedDate]) VALUES (1, 1, N'Participant', 10, N'Điểm danh tham gia', CAST(N'2026-01-04T08:49:56.737' AS DateTime))
INSERT [dbo].[EventPoints] ([EventPointID], [EventID], [RoleType], [Points], [Description], [CreatedDate]) VALUES (2, 1, N'Organizer', 20, N'Điểm tổ chức', CAST(N'2026-01-04T08:49:56.737' AS DateTime))
INSERT [dbo].[EventPoints] ([EventPointID], [EventID], [RoleType], [Points], [Description], [CreatedDate]) VALUES (3, 1, N'Volunteer', 15, N'Điểm tình nguyện', CAST(N'2026-01-04T08:49:56.737' AS DateTime))
INSERT [dbo].[EventPoints] ([EventPointID], [EventID], [RoleType], [Points], [Description], [CreatedDate]) VALUES (4, 4, N'Participant', 10, N'Điểm danh tham gia', CAST(N'2026-01-04T08:50:18.593' AS DateTime))
INSERT [dbo].[EventPoints] ([EventPointID], [EventID], [RoleType], [Points], [Description], [CreatedDate]) VALUES (6, 4, N'Volunteer', 15, N'Điểm tình nguyện', CAST(N'2026-01-04T08:50:18.593' AS DateTime))
INSERT [dbo].[EventPoints] ([EventPointID], [EventID], [RoleType], [Points], [Description], [CreatedDate]) VALUES (7, 5, N'Participant', 10, N'Điểm danh tham gia', CAST(N'2026-01-04T08:50:26.080' AS DateTime))
INSERT [dbo].[EventPoints] ([EventPointID], [EventID], [RoleType], [Points], [Description], [CreatedDate]) VALUES (8, 5, N'Organizer', 20, N'Điểm tổ chức', CAST(N'2026-01-04T08:50:26.080' AS DateTime))
INSERT [dbo].[EventPoints] ([EventPointID], [EventID], [RoleType], [Points], [Description], [CreatedDate]) VALUES (9, 5, N'Volunteer', 15, N'Điểm tình nguyện', CAST(N'2026-01-04T08:50:26.080' AS DateTime))
INSERT [dbo].[EventPoints] ([EventPointID], [EventID], [RoleType], [Points], [Description], [CreatedDate]) VALUES (11, 6, N'Organizer', 20, N'Điểm tổ chức', CAST(N'2026-01-04T10:04:02.917' AS DateTime))
INSERT [dbo].[EventPoints] ([EventPointID], [EventID], [RoleType], [Points], [Description], [CreatedDate]) VALUES (12, 6, N'Volunteer', 15, N'Điểm tình nguyện', CAST(N'2026-01-04T10:04:02.917' AS DateTime))
INSERT [dbo].[EventPoints] ([EventPointID], [EventID], [RoleType], [Points], [Description], [CreatedDate]) VALUES (13, 2, N'Participant', 10, N'Điểm danh tham gia', CAST(N'2026-01-04T10:12:28.940' AS DateTime))
INSERT [dbo].[EventPoints] ([EventPointID], [EventID], [RoleType], [Points], [Description], [CreatedDate]) VALUES (14, 3, N'Participant', 10, N'Điểm danh tham gia', CAST(N'2026-01-04T10:12:28.940' AS DateTime))
INSERT [dbo].[EventPoints] ([EventPointID], [EventID], [RoleType], [Points], [Description], [CreatedDate]) VALUES (15, 7, N'Participant', 10, N'Điểm danh tham gia', CAST(N'2026-01-04T10:31:30.273' AS DateTime))
INSERT [dbo].[EventPoints] ([EventPointID], [EventID], [RoleType], [Points], [Description], [CreatedDate]) VALUES (16, 8, N'Participant', 10, N'Điểm danh tham gia', CAST(N'2026-01-04T10:31:30.273' AS DateTime))
INSERT [dbo].[EventPoints] ([EventPointID], [EventID], [RoleType], [Points], [Description], [CreatedDate]) VALUES (17, 9, N'Participant', 10, N'Điểm danh tham gia', CAST(N'2026-01-04T10:31:30.273' AS DateTime))
INSERT [dbo].[EventPoints] ([EventPointID], [EventID], [RoleType], [Points], [Description], [CreatedDate]) VALUES (18, 10, N'Participant', 10, N'Điểm danh tham gia', CAST(N'2026-01-04T10:31:30.273' AS DateTime))
INSERT [dbo].[EventPoints] ([EventPointID], [EventID], [RoleType], [Points], [Description], [CreatedDate]) VALUES (19, 10, N'Volunteer', 15, N'string', CAST(N'2026-01-06T02:31:11.373' AS DateTime))
INSERT [dbo].[EventPoints] ([EventPointID], [EventID], [RoleType], [Points], [Description], [CreatedDate]) VALUES (21, 1012, N'Volunteer', 50, NULL, CAST(N'2026-01-30T12:05:32.470' AS DateTime))
INSERT [dbo].[EventPoints] ([EventPointID], [EventID], [RoleType], [Points], [Description], [CreatedDate]) VALUES (22, 1022, N'Volunteer', 10, NULL, CAST(N'2026-02-04T15:24:38.960' AS DateTime))
INSERT [dbo].[EventPoints] ([EventPointID], [EventID], [RoleType], [Points], [Description], [CreatedDate]) VALUES (23, 1027, N'Volunteer', 10, NULL, CAST(N'2026-02-13T14:35:46.153' AS DateTime))
INSERT [dbo].[EventPoints] ([EventPointID], [EventID], [RoleType], [Points], [Description], [CreatedDate]) VALUES (24, 1016, N'Participant', 10, NULL, CAST(N'2026-02-25T19:37:54.127' AS DateTime))
INSERT [dbo].[EventPoints] ([EventPointID], [EventID], [RoleType], [Points], [Description], [CreatedDate]) VALUES (25, 1016, N'Volunteer', 1, NULL, CAST(N'2026-02-25T19:39:14.297' AS DateTime))
SET IDENTITY_INSERT [dbo].[EventPoints] OFF
GO
SET IDENTITY_INSERT [dbo].[EventQRCodes] ON 

INSERT [dbo].[EventQRCodes] ([QRID], [EventID], [QRToken], [ValidFrom], [ValidUntil], [IsActive], [ScanLimit], [CurrentScans], [CreatedBy], [CreatedDate], [UpdatedDate]) VALUES (1, 4, N'uAkXxK1VTUupXX2JFgV4Nl7_h_F9RhRRHr6LM2qItgA', CAST(N'2026-02-15T13:00:00.000' AS DateTime), CAST(N'2026-02-15T15:00:00.000' AS DateTime), 0, 200, 0, 3, CAST(N'2026-01-01T09:58:39.087' AS DateTime), CAST(N'2026-01-01T09:59:31.207' AS DateTime))
INSERT [dbo].[EventQRCodes] ([QRID], [EventID], [QRToken], [ValidFrom], [ValidUntil], [IsActive], [ScanLimit], [CurrentScans], [CreatedBy], [CreatedDate], [UpdatedDate]) VALUES (2, 4, N'vWFF0LSXtGfn76mq0Jb1o60oNc7CcDYgBMZrO8XmaEE', CAST(N'2026-01-01T10:02:00.000' AS DateTime), CAST(N'2026-01-01T15:00:00.000' AS DateTime), 0, 200, 0, 3, CAST(N'2026-01-01T10:01:22.387' AS DateTime), CAST(N'2026-01-02T01:59:03.337' AS DateTime))
INSERT [dbo].[EventQRCodes] ([QRID], [EventID], [QRToken], [ValidFrom], [ValidUntil], [IsActive], [ScanLimit], [CurrentScans], [CreatedBy], [CreatedDate], [UpdatedDate]) VALUES (3, 4, N'3zyrDTLiGysROwSkg-5V7VFxS0WbabYe4urFyJN0pok', CAST(N'2026-01-02T00:00:00.000' AS DateTime), CAST(N'2026-01-10T00:00:00.000' AS DateTime), 0, 10, 1, 3, CAST(N'2026-01-02T01:59:03.343' AS DateTime), CAST(N'2026-01-03T03:29:17.667' AS DateTime))
INSERT [dbo].[EventQRCodes] ([QRID], [EventID], [QRToken], [ValidFrom], [ValidUntil], [IsActive], [ScanLimit], [CurrentScans], [CreatedBy], [CreatedDate], [UpdatedDate]) VALUES (4, 5, N'9JpKDSDXX9-rojwbQkplMj71ATeo6_0nczRu1vIKZhU', CAST(N'2026-01-02T15:00:00.000' AS DateTime), CAST(N'2026-01-31T18:00:00.000' AS DateTime), 0, 100, 0, 3, CAST(N'2026-01-02T11:36:56.440' AS DateTime), CAST(N'2026-01-02T11:39:45.167' AS DateTime))
INSERT [dbo].[EventQRCodes] ([QRID], [EventID], [QRToken], [ValidFrom], [ValidUntil], [IsActive], [ScanLimit], [CurrentScans], [CreatedBy], [CreatedDate], [UpdatedDate]) VALUES (5, 5, N'w-IdWGT6VfcRT__OmFbIaM5aoY7FrsGRRdHFzFb9OWA', CAST(N'2026-01-02T18:40:00.000' AS DateTime), CAST(N'2026-01-31T18:00:00.000' AS DateTime), 0, 100, 0, 3, CAST(N'2026-01-02T11:39:45.173' AS DateTime), CAST(N'2026-01-02T11:41:16.097' AS DateTime))
INSERT [dbo].[EventQRCodes] ([QRID], [EventID], [QRToken], [ValidFrom], [ValidUntil], [IsActive], [ScanLimit], [CurrentScans], [CreatedBy], [CreatedDate], [UpdatedDate]) VALUES (6, 5, N'C9tiD1v1eCiHPmolCSQwGzg-LvBvUrqRokP9Z_UULKc', CAST(N'2026-01-02T00:00:00.000' AS DateTime), CAST(N'2026-01-31T18:00:00.000' AS DateTime), 0, 100, 1, 3, CAST(N'2026-01-02T11:41:16.107' AS DateTime), CAST(N'2026-01-02T11:55:52.560' AS DateTime))
INSERT [dbo].[EventQRCodes] ([QRID], [EventID], [QRToken], [ValidFrom], [ValidUntil], [IsActive], [ScanLimit], [CurrentScans], [CreatedBy], [CreatedDate], [UpdatedDate]) VALUES (7, 5, N'-hKYNUC0Wjr__-L8qOARJQzLW3R26UyOwukCM8qVLjE', CAST(N'2026-01-02T18:56:00.000' AS DateTime), CAST(N'2026-02-01T00:00:00.000' AS DateTime), 0, 10, 0, 3, CAST(N'2026-01-02T11:55:52.577' AS DateTime), CAST(N'2026-01-02T12:03:58.097' AS DateTime))
INSERT [dbo].[EventQRCodes] ([QRID], [EventID], [QRToken], [ValidFrom], [ValidUntil], [IsActive], [ScanLimit], [CurrentScans], [CreatedBy], [CreatedDate], [UpdatedDate]) VALUES (8, 5, N'DUTzvnZ1OvaXlwPWvOYnP6Vja00tn5HhnMfdVOgc4kA', CAST(N'2026-01-02T12:04:00.000' AS DateTime), CAST(N'2026-02-01T00:00:00.000' AS DateTime), 1, 40, 0, 3, CAST(N'2026-01-02T12:03:58.110' AS DateTime), CAST(N'2026-01-02T12:03:58.110' AS DateTime))
INSERT [dbo].[EventQRCodes] ([QRID], [EventID], [QRToken], [ValidFrom], [ValidUntil], [IsActive], [ScanLimit], [CurrentScans], [CreatedBy], [CreatedDate], [UpdatedDate]) VALUES (9, 6, N'WKwkOFQgNDpgoxUtpwXswWYc7a5jPxnziDQqENQomlU', CAST(N'2026-01-04T00:00:00.000' AS DateTime), CAST(N'2026-01-25T11:00:00.000' AS DateTime), 0, 500, 0, 3, CAST(N'2026-01-03T03:28:10.163' AS DateTime), CAST(N'2026-01-04T02:22:15.137' AS DateTime))
INSERT [dbo].[EventQRCodes] ([QRID], [EventID], [QRToken], [ValidFrom], [ValidUntil], [IsActive], [ScanLimit], [CurrentScans], [CreatedBy], [CreatedDate], [UpdatedDate]) VALUES (10, 6, N'rt9BSnKmtyuWblx7jIDIoaDpOg8HNJFu_BUz6xtpy48', CAST(N'2026-01-04T02:20:00.000' AS DateTime), CAST(N'2026-01-25T11:00:00.000' AS DateTime), 1, 100, 1, 3, CAST(N'2026-01-04T02:22:15.147' AS DateTime), CAST(N'2026-01-04T02:24:06.457' AS DateTime))
INSERT [dbo].[EventQRCodes] ([QRID], [EventID], [QRToken], [ValidFrom], [ValidUntil], [IsActive], [ScanLimit], [CurrentScans], [CreatedBy], [CreatedDate], [UpdatedDate]) VALUES (11, 7, N'4yBXXUyuyOFx9LUBV_2DBHCshxnI7nogI0yw5uP5zu4', CAST(N'2026-01-04T05:30:00.000' AS DateTime), CAST(N'2026-01-30T16:59:59.000' AS DateTime), 1, 20, 2, 3, CAST(N'2026-01-04T06:00:45.503' AS DateTime), CAST(N'2026-01-04T06:12:28.227' AS DateTime))
INSERT [dbo].[EventQRCodes] ([QRID], [EventID], [QRToken], [ValidFrom], [ValidUntil], [IsActive], [ScanLimit], [CurrentScans], [CreatedBy], [CreatedDate], [UpdatedDate]) VALUES (12, 8, N'dra6-fF24-158qCgy2zQyaTyKNNmTfl7xxfyZP1837Q', CAST(N'2026-01-04T05:30:00.000' AS DateTime), CAST(N'2026-01-30T16:59:59.000' AS DateTime), 1, 20, 2, 3, CAST(N'2026-01-04T06:00:58.330' AS DateTime), CAST(N'2026-01-04T06:13:43.433' AS DateTime))
INSERT [dbo].[EventQRCodes] ([QRID], [EventID], [QRToken], [ValidFrom], [ValidUntil], [IsActive], [ScanLimit], [CurrentScans], [CreatedBy], [CreatedDate], [UpdatedDate]) VALUES (13, 9, N'4Zu324zI5ICnfvdjuL0MlpMeXt208iXkDpoqKgWH7R8', CAST(N'2026-01-04T05:30:00.000' AS DateTime), CAST(N'2026-01-30T16:59:59.000' AS DateTime), 1, 20, 2, 3, CAST(N'2026-01-04T06:01:01.427' AS DateTime), CAST(N'2026-01-07T02:30:49.497' AS DateTime))
INSERT [dbo].[EventQRCodes] ([QRID], [EventID], [QRToken], [ValidFrom], [ValidUntil], [IsActive], [ScanLimit], [CurrentScans], [CreatedBy], [CreatedDate], [UpdatedDate]) VALUES (14, 10, N'yMlM8rZFGgZYfwJgaNJu3-JpxVVhvJEiePNye9GcH0g', CAST(N'2026-01-04T05:30:00.000' AS DateTime), CAST(N'2026-01-30T16:59:59.000' AS DateTime), 0, 20, 2, 3, CAST(N'2026-01-04T06:01:04.243' AS DateTime), CAST(N'2026-01-27T01:56:46.513' AS DateTime))
INSERT [dbo].[EventQRCodes] ([QRID], [EventID], [QRToken], [ValidFrom], [ValidUntil], [IsActive], [ScanLimit], [CurrentScans], [CreatedBy], [CreatedDate], [UpdatedDate]) VALUES (15, 10, N'WqTzEDQw1NZwwJ1ZfiobScn_e_7vkU8cMYzGdX0FNFk', CAST(N'2026-01-27T01:56:00.000' AS DateTime), CAST(N'2026-01-27T03:56:00.000' AS DateTime), 1, NULL, 0, 2, CAST(N'2026-01-27T01:56:46.523' AS DateTime), CAST(N'2026-01-27T01:56:46.523' AS DateTime))
INSERT [dbo].[EventQRCodes] ([QRID], [EventID], [QRToken], [ValidFrom], [ValidUntil], [IsActive], [ScanLimit], [CurrentScans], [CreatedBy], [CreatedDate], [UpdatedDate]) VALUES (16, 1012, N'h0rmTPbSwsDkqFxdEypn_27vHY-luNhQvLks-GH90Qo', CAST(N'2026-01-26T18:59:22.953' AS DateTime), CAST(N'2026-01-27T03:59:22.953' AS DateTime), 0, 10, 0, 2, CAST(N'2026-01-27T02:00:21.083' AS DateTime), CAST(N'2026-01-27T02:01:11.580' AS DateTime))
INSERT [dbo].[EventQRCodes] ([QRID], [EventID], [QRToken], [ValidFrom], [ValidUntil], [IsActive], [ScanLimit], [CurrentScans], [CreatedBy], [CreatedDate], [UpdatedDate]) VALUES (17, 1012, N'lSufHUTd_fxOINte0sKqeMQfQpWSPg2TLEF6Hs9GJfc', CAST(N'2026-01-27T02:00:00.000' AS DateTime), CAST(N'2026-01-27T04:00:00.000' AS DateTime), 0, 100, 0, 2, CAST(N'2026-01-27T02:01:11.583' AS DateTime), CAST(N'2026-01-27T02:34:40.753' AS DateTime))
INSERT [dbo].[EventQRCodes] ([QRID], [EventID], [QRToken], [ValidFrom], [ValidUntil], [IsActive], [ScanLimit], [CurrentScans], [CreatedBy], [CreatedDate], [UpdatedDate]) VALUES (18, 1016, N'YzFoLr4qwqoR411H3Waex0KywWy_rITziz3luq9EJo8', CAST(N'2026-02-02T02:20:00.000' AS DateTime), CAST(N'2026-02-02T03:00:00.000' AS DateTime), 1, 10, 1, 2, CAST(N'2026-02-02T02:21:15.583' AS DateTime), CAST(N'2026-02-02T02:23:42.257' AS DateTime))
INSERT [dbo].[EventQRCodes] ([QRID], [EventID], [QRToken], [ValidFrom], [ValidUntil], [IsActive], [ScanLimit], [CurrentScans], [CreatedBy], [CreatedDate], [UpdatedDate]) VALUES (19, 1017, N'PYQ52WrIY2dErJF98-gYr6dz8fLMaSIvGnUgVsc1slo', CAST(N'2026-02-02T02:20:00.000' AS DateTime), CAST(N'2026-02-02T03:00:00.000' AS DateTime), 1, 10, 0, 2, CAST(N'2026-02-02T02:21:27.537' AS DateTime), CAST(N'2026-02-02T02:21:27.537' AS DateTime))
INSERT [dbo].[EventQRCodes] ([QRID], [EventID], [QRToken], [ValidFrom], [ValidUntil], [IsActive], [ScanLimit], [CurrentScans], [CreatedBy], [CreatedDate], [UpdatedDate]) VALUES (20, 1018, N'8e4Yuokes081bjQx0FnO3UyiBVj0nx26Vx-srb2jWh4', CAST(N'2026-02-02T02:30:00.000' AS DateTime), CAST(N'2026-02-02T03:00:00.000' AS DateTime), 1, 10, 1, 2, CAST(N'2026-02-02T02:26:37.463' AS DateTime), CAST(N'2026-02-02T02:31:02.580' AS DateTime))
INSERT [dbo].[EventQRCodes] ([QRID], [EventID], [QRToken], [ValidFrom], [ValidUntil], [IsActive], [ScanLimit], [CurrentScans], [CreatedBy], [CreatedDate], [UpdatedDate]) VALUES (24, 1022, N'8lyZQYZpgWsJveMMmLQu7zMEqzw5rV5ZX5NuMLC8iXg', CAST(N'2026-02-04T15:23:00.000' AS DateTime), CAST(N'2026-02-04T17:23:00.000' AS DateTime), 0, NULL, 0, 2, CAST(N'2026-02-04T15:23:50.083' AS DateTime), CAST(N'2026-02-04T15:24:08.103' AS DateTime))
INSERT [dbo].[EventQRCodes] ([QRID], [EventID], [QRToken], [ValidFrom], [ValidUntil], [IsActive], [ScanLimit], [CurrentScans], [CreatedBy], [CreatedDate], [UpdatedDate]) VALUES (25, 1022, N'XpOv3PDrKFhSJLsWwoihQDtCivWMCQXIjv4T2tw2HmU', CAST(N'2026-02-04T15:23:00.000' AS DateTime), CAST(N'2026-02-04T17:23:00.000' AS DateTime), 0, NULL, 0, 2, CAST(N'2026-02-04T15:24:08.107' AS DateTime), CAST(N'2026-02-04T15:56:17.450' AS DateTime))
INSERT [dbo].[EventQRCodes] ([QRID], [EventID], [QRToken], [ValidFrom], [ValidUntil], [IsActive], [ScanLimit], [CurrentScans], [CreatedBy], [CreatedDate], [UpdatedDate]) VALUES (26, 1022, N'50UTvSdujJpnD0ojxJlhnACzLRXGMca5lSIxCaccotg', CAST(N'2026-02-04T15:56:00.000' AS DateTime), CAST(N'2026-02-04T17:56:00.000' AS DateTime), 0, NULL, 0, 2, CAST(N'2026-02-04T15:56:17.453' AS DateTime), CAST(N'2026-02-04T16:17:15.867' AS DateTime))
INSERT [dbo].[EventQRCodes] ([QRID], [EventID], [QRToken], [ValidFrom], [ValidUntil], [IsActive], [ScanLimit], [CurrentScans], [CreatedBy], [CreatedDate], [UpdatedDate]) VALUES (27, 1022, N'roZ3mWCRHXxy_bDB3_RUKONtNwFYHELlyR9w6NsZ5n8', CAST(N'2026-02-04T16:17:00.000' AS DateTime), CAST(N'2026-02-04T18:17:00.000' AS DateTime), 0, NULL, 0, 2, CAST(N'2026-02-04T16:17:22.330' AS DateTime), CAST(N'2026-02-06T15:24:32.870' AS DateTime))
INSERT [dbo].[EventQRCodes] ([QRID], [EventID], [QRToken], [ValidFrom], [ValidUntil], [IsActive], [ScanLimit], [CurrentScans], [CreatedBy], [CreatedDate], [UpdatedDate]) VALUES (28, 12, N'VH6tFl9YCBtnBUwpC-Sg7uB-7jrlF18LyUF6wW_5H9U', CAST(N'2026-02-06T15:01:00.000' AS DateTime), CAST(N'2026-02-06T17:01:00.000' AS DateTime), 1, NULL, 0, 2, CAST(N'2026-02-06T15:01:49.747' AS DateTime), CAST(N'2026-02-06T15:01:49.747' AS DateTime))
INSERT [dbo].[EventQRCodes] ([QRID], [EventID], [QRToken], [ValidFrom], [ValidUntil], [IsActive], [ScanLimit], [CurrentScans], [CreatedBy], [CreatedDate], [UpdatedDate]) VALUES (29, 1022, N'MpChGuef1m1aUiMF-5RFzgJvDED9gslTlxFQKVKDP4A', CAST(N'2026-02-06T15:24:00.000' AS DateTime), CAST(N'2026-02-06T17:24:00.000' AS DateTime), 0, NULL, 0, 2, CAST(N'2026-02-06T15:24:32.877' AS DateTime), CAST(N'2026-02-07T10:04:23.533' AS DateTime))
INSERT [dbo].[EventQRCodes] ([QRID], [EventID], [QRToken], [ValidFrom], [ValidUntil], [IsActive], [ScanLimit], [CurrentScans], [CreatedBy], [CreatedDate], [UpdatedDate]) VALUES (30, 1021, N'XoVZDkBCOSX3sRS1llderHM95NJxy5HSo2hW-kUB9ew', CAST(N'2026-02-06T15:54:00.000' AS DateTime), CAST(N'2026-02-06T17:54:00.000' AS DateTime), 0, NULL, 0, 2, CAST(N'2026-02-06T15:54:59.617' AS DateTime), CAST(N'2026-02-12T10:04:45.960' AS DateTime))
INSERT [dbo].[EventQRCodes] ([QRID], [EventID], [QRToken], [ValidFrom], [ValidUntil], [IsActive], [ScanLimit], [CurrentScans], [CreatedBy], [CreatedDate], [UpdatedDate]) VALUES (31, 1022, N'uS6zJGRoHEnzHtrzByyQMRx5kxdi7YfTUMR_4XsTeUc', CAST(N'2026-02-07T10:04:00.000' AS DateTime), CAST(N'2026-02-07T12:04:00.000' AS DateTime), 0, NULL, 0, 2, CAST(N'2026-02-07T10:04:23.550' AS DateTime), CAST(N'2026-02-07T15:25:20.043' AS DateTime))
INSERT [dbo].[EventQRCodes] ([QRID], [EventID], [QRToken], [ValidFrom], [ValidUntil], [IsActive], [ScanLimit], [CurrentScans], [CreatedBy], [CreatedDate], [UpdatedDate]) VALUES (32, 1022, N'LKwiAyL1IDox-OlmBixBhTCEwG0kS7Wf4U4JGkQB4JE', CAST(N'2026-02-07T15:25:00.000' AS DateTime), CAST(N'2026-02-07T17:25:00.000' AS DateTime), 0, NULL, 0, 2, CAST(N'2026-02-07T15:25:20.060' AS DateTime), CAST(N'2026-02-07T15:25:29.207' AS DateTime))
INSERT [dbo].[EventQRCodes] ([QRID], [EventID], [QRToken], [ValidFrom], [ValidUntil], [IsActive], [ScanLimit], [CurrentScans], [CreatedBy], [CreatedDate], [UpdatedDate]) VALUES (33, 1021, N'bTDC815fFpjunM85sqWbJ3qT37L7GkwO2VA0bHVOffk', CAST(N'2026-02-12T10:04:00.000' AS DateTime), CAST(N'2026-02-12T12:04:00.000' AS DateTime), 1, NULL, 0, 2, CAST(N'2026-02-12T10:04:45.987' AS DateTime), CAST(N'2026-02-12T10:04:45.987' AS DateTime))
INSERT [dbo].[EventQRCodes] ([QRID], [EventID], [QRToken], [ValidFrom], [ValidUntil], [IsActive], [ScanLimit], [CurrentScans], [CreatedBy], [CreatedDate], [UpdatedDate]) VALUES (34, 1028, N'-UYt96ywOex7-isdqP0l6RIkEvR-wdFegKA8yYAJPtc', CAST(N'2026-02-20T14:35:00.000' AS DateTime), CAST(N'2026-02-22T16:35:00.000' AS DateTime), 1, NULL, 1, 2, CAST(N'2026-02-20T14:36:03.130' AS DateTime), CAST(N'2026-02-20T14:38:29.043' AS DateTime))
INSERT [dbo].[EventQRCodes] ([QRID], [EventID], [QRToken], [ValidFrom], [ValidUntil], [IsActive], [ScanLimit], [CurrentScans], [CreatedBy], [CreatedDate], [UpdatedDate]) VALUES (35, 1033, N'DTABq4EJJm5_O4hSvbvtJ9Ad9hRGozOgqJiZ72Vzrrk', CAST(N'2026-02-21T09:31:00.000' AS DateTime), CAST(N'2026-02-22T11:18:00.000' AS DateTime), 1, NULL, 0, 2, CAST(N'2026-02-21T09:18:54.343' AS DateTime), CAST(N'2026-02-21T09:18:54.343' AS DateTime))
INSERT [dbo].[EventQRCodes] ([QRID], [EventID], [QRToken], [ValidFrom], [ValidUntil], [IsActive], [ScanLimit], [CurrentScans], [CreatedBy], [CreatedDate], [UpdatedDate]) VALUES (36, 1034, N'Iufy9F6guwacyQk2iziLgElQMg8ygAOHWNi7-XJwdXM', CAST(N'2026-02-21T09:31:00.000' AS DateTime), CAST(N'2026-02-22T11:20:00.000' AS DateTime), 1, NULL, 0, 2, CAST(N'2026-02-21T09:20:15.417' AS DateTime), CAST(N'2026-02-21T09:20:15.417' AS DateTime))
INSERT [dbo].[EventQRCodes] ([QRID], [EventID], [QRToken], [ValidFrom], [ValidUntil], [IsActive], [ScanLimit], [CurrentScans], [CreatedBy], [CreatedDate], [UpdatedDate]) VALUES (37, 1036, N'32Ob849TPzee5bdl0q_EJkdqoQpZ4BCwZDryyQy6uU4', CAST(N'2026-02-25T19:32:00.000' AS DateTime), CAST(N'2026-02-25T21:32:00.000' AS DateTime), 1, NULL, 0, 2, CAST(N'2026-02-25T19:32:56.250' AS DateTime), CAST(N'2026-02-25T19:32:56.250' AS DateTime))
INSERT [dbo].[EventQRCodes] ([QRID], [EventID], [QRToken], [ValidFrom], [ValidUntil], [IsActive], [ScanLimit], [CurrentScans], [CreatedBy], [CreatedDate], [UpdatedDate]) VALUES (38, 1037, N'x_70B4oHpbw_RsY-dF83D8ssInm-lJZyCKoYn7CbxKw', CAST(N'2026-02-25T19:36:00.000' AS DateTime), CAST(N'2026-02-25T21:36:00.000' AS DateTime), 1, NULL, 0, 2, CAST(N'2026-02-25T19:36:31.593' AS DateTime), CAST(N'2026-02-25T19:36:31.593' AS DateTime))
SET IDENTITY_INSERT [dbo].[EventQRCodes] OFF
GO
SET IDENTITY_INSERT [dbo].[EventRegistrations] ON 

INSERT [dbo].[EventRegistrations] ([RegistrationID], [EventID], [UserID], [RegisterTime], [Status], [CancellationReason], [CreatedDate], [UpdatedDate]) VALUES (1, 3, 4, CAST(N'2025-12-31T15:34:50.393' AS DateTime), 1, NULL, CAST(N'2025-12-31T15:34:50.393' AS DateTime), CAST(N'2025-12-31T15:39:57.613' AS DateTime))
INSERT [dbo].[EventRegistrations] ([RegistrationID], [EventID], [UserID], [RegisterTime], [Status], [CancellationReason], [CreatedDate], [UpdatedDate]) VALUES (3, 4, 4, CAST(N'2026-01-01T02:07:22.680' AS DateTime), 0, NULL, CAST(N'2026-01-01T02:07:22.680' AS DateTime), CAST(N'2026-01-01T02:07:22.680' AS DateTime))
INSERT [dbo].[EventRegistrations] ([RegistrationID], [EventID], [UserID], [RegisterTime], [Status], [CancellationReason], [CreatedDate], [UpdatedDate]) VALUES (4, 5, 4, CAST(N'2026-01-02T07:36:16.197' AS DateTime), 0, NULL, CAST(N'2026-01-02T07:36:16.197' AS DateTime), CAST(N'2026-01-02T07:36:16.197' AS DateTime))
INSERT [dbo].[EventRegistrations] ([RegistrationID], [EventID], [UserID], [RegisterTime], [Status], [CancellationReason], [CreatedDate], [UpdatedDate]) VALUES (5, 6, 4, CAST(N'2026-01-04T02:17:11.717' AS DateTime), 0, NULL, CAST(N'2026-01-04T02:17:11.717' AS DateTime), CAST(N'2026-01-04T02:17:11.717' AS DateTime))
INSERT [dbo].[EventRegistrations] ([RegistrationID], [EventID], [UserID], [RegisterTime], [Status], [CancellationReason], [CreatedDate], [UpdatedDate]) VALUES (6, 7, 4, CAST(N'2026-01-04T03:27:51.350' AS DateTime), 0, NULL, CAST(N'2026-01-04T03:27:51.350' AS DateTime), CAST(N'2026-01-04T03:27:51.350' AS DateTime))
INSERT [dbo].[EventRegistrations] ([RegistrationID], [EventID], [UserID], [RegisterTime], [Status], [CancellationReason], [CreatedDate], [UpdatedDate]) VALUES (7, 8, 4, CAST(N'2026-01-04T03:27:54.917' AS DateTime), 0, NULL, CAST(N'2026-01-04T03:27:54.917' AS DateTime), CAST(N'2026-01-04T03:27:54.917' AS DateTime))
INSERT [dbo].[EventRegistrations] ([RegistrationID], [EventID], [UserID], [RegisterTime], [Status], [CancellationReason], [CreatedDate], [UpdatedDate]) VALUES (8, 9, 4, CAST(N'2026-01-04T03:27:58.477' AS DateTime), 0, NULL, CAST(N'2026-01-04T03:27:58.477' AS DateTime), CAST(N'2026-01-04T03:27:58.477' AS DateTime))
INSERT [dbo].[EventRegistrations] ([RegistrationID], [EventID], [UserID], [RegisterTime], [Status], [CancellationReason], [CreatedDate], [UpdatedDate]) VALUES (9, 10, 4, CAST(N'2026-01-04T03:28:03.297' AS DateTime), 0, NULL, CAST(N'2026-01-04T03:28:03.297' AS DateTime), CAST(N'2026-01-04T03:28:03.297' AS DateTime))
INSERT [dbo].[EventRegistrations] ([RegistrationID], [EventID], [UserID], [RegisterTime], [Status], [CancellationReason], [CreatedDate], [UpdatedDate]) VALUES (10, 7, 5, CAST(N'2026-01-04T03:29:32.743' AS DateTime), 0, NULL, CAST(N'2026-01-04T03:29:32.743' AS DateTime), CAST(N'2026-01-04T03:29:32.743' AS DateTime))
INSERT [dbo].[EventRegistrations] ([RegistrationID], [EventID], [UserID], [RegisterTime], [Status], [CancellationReason], [CreatedDate], [UpdatedDate]) VALUES (11, 8, 5, CAST(N'2026-01-04T03:29:40.230' AS DateTime), 0, NULL, CAST(N'2026-01-04T03:29:40.230' AS DateTime), CAST(N'2026-01-04T03:29:40.230' AS DateTime))
INSERT [dbo].[EventRegistrations] ([RegistrationID], [EventID], [UserID], [RegisterTime], [Status], [CancellationReason], [CreatedDate], [UpdatedDate]) VALUES (12, 9, 5, CAST(N'2026-01-04T03:29:43.083' AS DateTime), 0, NULL, CAST(N'2026-01-04T03:29:43.083' AS DateTime), CAST(N'2026-01-04T03:29:43.083' AS DateTime))
INSERT [dbo].[EventRegistrations] ([RegistrationID], [EventID], [UserID], [RegisterTime], [Status], [CancellationReason], [CreatedDate], [UpdatedDate]) VALUES (13, 10, 5, CAST(N'2026-01-04T03:29:45.940' AS DateTime), 0, NULL, CAST(N'2026-01-04T03:29:45.940' AS DateTime), CAST(N'2026-01-04T03:29:45.940' AS DateTime))
INSERT [dbo].[EventRegistrations] ([RegistrationID], [EventID], [UserID], [RegisterTime], [Status], [CancellationReason], [CreatedDate], [UpdatedDate]) VALUES (14, 1016, 4, CAST(N'2026-02-02T02:16:19.073' AS DateTime), 0, NULL, CAST(N'2026-02-02T02:16:19.073' AS DateTime), CAST(N'2026-02-02T02:16:19.073' AS DateTime))
INSERT [dbo].[EventRegistrations] ([RegistrationID], [EventID], [UserID], [RegisterTime], [Status], [CancellationReason], [CreatedDate], [UpdatedDate]) VALUES (15, 1018, 4, CAST(N'2026-02-02T02:25:48.177' AS DateTime), 0, NULL, CAST(N'2026-02-02T02:25:48.177' AS DateTime), CAST(N'2026-02-02T02:25:48.177' AS DateTime))
INSERT [dbo].[EventRegistrations] ([RegistrationID], [EventID], [UserID], [RegisterTime], [Status], [CancellationReason], [CreatedDate], [UpdatedDate]) VALUES (16, 1028, 4, CAST(N'2026-02-19T14:59:42.360' AS DateTime), 0, NULL, CAST(N'2026-02-19T14:59:42.360' AS DateTime), CAST(N'2026-02-19T14:59:42.360' AS DateTime))
INSERT [dbo].[EventRegistrations] ([RegistrationID], [EventID], [UserID], [RegisterTime], [Status], [CancellationReason], [CreatedDate], [UpdatedDate]) VALUES (17, 1029, 4, CAST(N'2026-02-19T18:35:52.667' AS DateTime), 1, NULL, CAST(N'2026-02-19T18:35:52.667' AS DateTime), CAST(N'2026-02-20T09:43:47.767' AS DateTime))
INSERT [dbo].[EventRegistrations] ([RegistrationID], [EventID], [UserID], [RegisterTime], [Status], [CancellationReason], [CreatedDate], [UpdatedDate]) VALUES (18, 1030, 4, CAST(N'2026-02-20T10:14:36.137' AS DateTime), 1, N'không có', CAST(N'2026-02-20T10:14:36.140' AS DateTime), CAST(N'2026-02-20T10:15:25.087' AS DateTime))
INSERT [dbo].[EventRegistrations] ([RegistrationID], [EventID], [UserID], [RegisterTime], [Status], [CancellationReason], [CreatedDate], [UpdatedDate]) VALUES (19, 1031, 4, CAST(N'2026-02-20T10:15:54.503' AS DateTime), 1, NULL, CAST(N'2026-02-20T10:15:54.503' AS DateTime), CAST(N'2026-02-20T10:19:34.780' AS DateTime))
INSERT [dbo].[EventRegistrations] ([RegistrationID], [EventID], [UserID], [RegisterTime], [Status], [CancellationReason], [CreatedDate], [UpdatedDate]) VALUES (20, 1033, 4, CAST(N'2026-02-21T09:18:19.517' AS DateTime), 1, NULL, CAST(N'2026-02-21T09:18:19.517' AS DateTime), CAST(N'2026-02-22T09:08:44.800' AS DateTime))
INSERT [dbo].[EventRegistrations] ([RegistrationID], [EventID], [UserID], [RegisterTime], [Status], [CancellationReason], [CreatedDate], [UpdatedDate]) VALUES (21, 1034, 4, CAST(N'2026-02-21T09:19:55.070' AS DateTime), 1, N'không', CAST(N'2026-02-21T09:19:55.070' AS DateTime), CAST(N'2026-02-21T09:27:45.097' AS DateTime))
INSERT [dbo].[EventRegistrations] ([RegistrationID], [EventID], [UserID], [RegisterTime], [Status], [CancellationReason], [CreatedDate], [UpdatedDate]) VALUES (22, 1036, 4, CAST(N'2026-02-25T19:31:02.930' AS DateTime), 1, N'không thích', CAST(N'2026-02-25T19:31:02.930' AS DateTime), CAST(N'2026-02-25T19:31:32.797' AS DateTime))
INSERT [dbo].[EventRegistrations] ([RegistrationID], [EventID], [UserID], [RegisterTime], [Status], [CancellationReason], [CreatedDate], [UpdatedDate]) VALUES (23, 1037, 4, CAST(N'2026-02-25T19:36:16.503' AS DateTime), 1, N'', CAST(N'2026-02-25T19:36:16.503' AS DateTime), CAST(N'2026-02-27T09:25:23.077' AS DateTime))
INSERT [dbo].[EventRegistrations] ([RegistrationID], [EventID], [UserID], [RegisterTime], [Status], [CancellationReason], [CreatedDate], [UpdatedDate]) VALUES (24, 2038, 4, CAST(N'2026-03-01T15:34:01.363' AS DateTime), 0, NULL, CAST(N'2026-03-01T15:34:01.363' AS DateTime), CAST(N'2026-03-01T15:34:01.363' AS DateTime))
SET IDENTITY_INSERT [dbo].[EventRegistrations] OFF
GO
SET IDENTITY_INSERT [dbo].[Events] ON 

INSERT [dbo].[Events] ([EventID], [EventName], [Description], [StartTime], [EndTime], [LocationName], [Latitude], [Longitude], [AllowRadius], [MaxParticipants], [CurrentParticipants], [CreatedBy], [EventTypeID], [InstituteID], [Status], [RegistrationDeadline], [CreatedDate], [UpdatedDate]) VALUES (1, N'Hội thảo Công nghệ AI 2025', N'Hội thảo về ứng dụng AI trong giáo dục', CAST(N'2025-12-30T08:00:00.000' AS DateTime), CAST(N'2025-12-30T17:00:00.000' AS DateTime), N'Hội trường B - Tòa nhà chính', CAST(10.762622 AS Decimal(10, 6)), CAST(106.660172 AS Decimal(10, 6)), 100, 200, 0, 3, 1, 1, 3, CAST(N'2025-12-29T23:59:59.000' AS DateTime), CAST(N'2025-12-27T14:26:31.203' AS DateTime), CAST(N'2026-01-24T03:54:30.163' AS DateTime))
INSERT [dbo].[Events] ([EventID], [EventName], [Description], [StartTime], [EndTime], [LocationName], [Latitude], [Longitude], [AllowRadius], [MaxParticipants], [CurrentParticipants], [CreatedBy], [EventTypeID], [InstituteID], [Status], [RegistrationDeadline], [CreatedDate], [UpdatedDate]) VALUES (2, N'Ngày hội Tình nguyện 2025', N'Hoạt động tình nguyện vì cộng đồng', CAST(N'2025-01-15T07:00:00.000' AS DateTime), CAST(N'2025-01-15T18:00:00.000' AS DateTime), N'Công viên Thành phố', CAST(10.775000 AS Decimal(10, 6)), CAST(106.700000 AS Decimal(10, 6)), 200, 500, 0, 3, 2, 1, 3, CAST(N'2025-01-10T23:59:59.000' AS DateTime), CAST(N'2025-12-28T07:51:11.060' AS DateTime), CAST(N'2025-12-28T08:41:27.457' AS DateTime))
INSERT [dbo].[Events] ([EventID], [EventName], [Description], [StartTime], [EndTime], [LocationName], [Latitude], [Longitude], [AllowRadius], [MaxParticipants], [CurrentParticipants], [CreatedBy], [EventTypeID], [InstituteID], [Status], [RegistrationDeadline], [CreatedDate], [UpdatedDate]) VALUES (3, N'Ngày hội Tình nguyện 2026', N'Hoạt động tình nguyện vì cộng đồng', CAST(N'2026-01-15T07:00:00.000' AS DateTime), CAST(N'2026-01-15T18:00:00.000' AS DateTime), N'Công viên Thành phố', CAST(10.775000 AS Decimal(10, 6)), CAST(106.700000 AS Decimal(10, 6)), 200, 500, 0, 3, 2, 1, 3, CAST(N'2026-01-14T23:59:59.000' AS DateTime), CAST(N'2025-12-28T08:42:09.920' AS DateTime), CAST(N'2026-02-02T01:49:27.507' AS DateTime))
INSERT [dbo].[Events] ([EventID], [EventName], [Description], [StartTime], [EndTime], [LocationName], [Latitude], [Longitude], [AllowRadius], [MaxParticipants], [CurrentParticipants], [CreatedBy], [EventTypeID], [InstituteID], [Status], [RegistrationDeadline], [CreatedDate], [UpdatedDate]) VALUES (4, N'Ngày hội Tình nguyện 2026', N'Hoạt động tình nguyện vì cộng đồng', CAST(N'2026-02-02T07:00:00.000' AS DateTime), CAST(N'2026-02-15T18:00:00.000' AS DateTime), N'Công viên Thành phố', CAST(10.775000 AS Decimal(10, 6)), CAST(106.700000 AS Decimal(10, 6)), 100, 500, 1, 3, 2, 1, 3, CAST(N'2026-02-01T23:59:59.000' AS DateTime), CAST(N'2026-01-01T02:06:35.927' AS DateTime), CAST(N'2026-02-16T19:33:03.163' AS DateTime))
INSERT [dbo].[Events] ([EventID], [EventName], [Description], [StartTime], [EndTime], [LocationName], [Latitude], [Longitude], [AllowRadius], [MaxParticipants], [CurrentParticipants], [CreatedBy], [EventTypeID], [InstituteID], [Status], [RegistrationDeadline], [CreatedDate], [UpdatedDate]) VALUES (5, N'Hội thảo Công nghệ AI 2026', N'Hội thảo về ứng dụng AI trong giáo dục', CAST(N'2026-01-02T15:00:00.000' AS DateTime), CAST(N'2026-01-31T18:00:00.000' AS DateTime), N'Hội trường A - Tòa nhà chính', CAST(10.775000 AS Decimal(10, 6)), CAST(106.700000 AS Decimal(10, 6)), 100, 500, 1, 3, 2, 1, 3, CAST(N'2026-01-02T14:59:59.000' AS DateTime), CAST(N'2026-01-02T07:33:55.200' AS DateTime), CAST(N'2026-02-02T01:49:27.507' AS DateTime))
INSERT [dbo].[Events] ([EventID], [EventName], [Description], [StartTime], [EndTime], [LocationName], [Latitude], [Longitude], [AllowRadius], [MaxParticipants], [CurrentParticipants], [CreatedBy], [EventTypeID], [InstituteID], [Status], [RegistrationDeadline], [CreatedDate], [UpdatedDate]) VALUES (6, N'Ngày hội Tình nguyện mùa Xuân 2026', N'Hoạt động tình nguyện vì cộng đồng', CAST(N'2026-01-04T02:20:00.000' AS DateTime), CAST(N'2026-01-25T11:00:00.000' AS DateTime), N'Công viên Thành phố', CAST(10.775000 AS Decimal(10, 6)), CAST(106.700000 AS Decimal(10, 6)), 200, 500, 1, 3, 2, 1, 3, CAST(N'2026-01-04T02:18:00.000' AS DateTime), CAST(N'2026-01-03T03:03:51.207' AS DateTime), CAST(N'2026-02-02T01:49:27.507' AS DateTime))
INSERT [dbo].[Events] ([EventID], [EventName], [Description], [StartTime], [EndTime], [LocationName], [Latitude], [Longitude], [AllowRadius], [MaxParticipants], [CurrentParticipants], [CreatedBy], [EventTypeID], [InstituteID], [Status], [RegistrationDeadline], [CreatedDate], [UpdatedDate]) VALUES (7, N'Ngày hội Hiến máu Nhân đạo 2025', N'Chương trình hiến máu tình nguyện vì sức khỏe cộng đồng', CAST(N'2026-01-04T05:30:00.000' AS DateTime), CAST(N'2026-01-30T16:59:59.000' AS DateTime), N'Hội trường A - Trường Đại học', CAST(10.776500 AS Decimal(10, 6)), CAST(106.695800 AS Decimal(10, 6)), 150, 300, 2, 3, 2, 1, 3, CAST(N'2026-01-04T05:00:00.000' AS DateTime), CAST(N'2026-01-04T03:25:14.357' AS DateTime), CAST(N'2026-02-02T01:49:27.507' AS DateTime))
INSERT [dbo].[Events] ([EventID], [EventName], [Description], [StartTime], [EndTime], [LocationName], [Latitude], [Longitude], [AllowRadius], [MaxParticipants], [CurrentParticipants], [CreatedBy], [EventTypeID], [InstituteID], [Status], [RegistrationDeadline], [CreatedDate], [UpdatedDate]) VALUES (8, N'Hội thảo Kỹ năng Giao tiếp & Làm việc nhóm', N'Trang bị kỹ năng mềm cần thiết cho sinh viên', CAST(N'2026-01-04T05:30:00.000' AS DateTime), CAST(N'2026-01-30T16:59:59.000' AS DateTime), N'Hội trường A - Trường Đại học', CAST(10.776500 AS Decimal(10, 6)), CAST(106.695800 AS Decimal(10, 6)), 150, 300, 2, 3, 2, 1, 3, CAST(N'2026-01-04T05:00:00.000' AS DateTime), CAST(N'2026-01-04T03:26:08.867' AS DateTime), CAST(N'2026-02-02T01:49:27.507' AS DateTime))
INSERT [dbo].[Events] ([EventID], [EventName], [Description], [StartTime], [EndTime], [LocationName], [Latitude], [Longitude], [AllowRadius], [MaxParticipants], [CurrentParticipants], [CreatedBy], [EventTypeID], [InstituteID], [Status], [RegistrationDeadline], [CreatedDate], [UpdatedDate]) VALUES (9, N'Chiến dịch Mùa hè xanh 2026', N'Hoạt động tình nguyện hè tại các địa phương khó khăn', CAST(N'2026-01-04T05:30:00.000' AS DateTime), CAST(N'2026-01-30T16:59:59.000' AS DateTime), N'Hội trường A - Trường Đại học', CAST(10.776500 AS Decimal(10, 6)), CAST(106.695800 AS Decimal(10, 6)), 150, 300, 2, 3, 2, 1, 3, CAST(N'2026-01-04T05:00:00.000' AS DateTime), CAST(N'2026-01-04T03:26:24.190' AS DateTime), CAST(N'2026-02-02T01:49:27.507' AS DateTime))
INSERT [dbo].[Events] ([EventID], [EventName], [Description], [StartTime], [EndTime], [LocationName], [Latitude], [Longitude], [AllowRadius], [MaxParticipants], [CurrentParticipants], [CreatedBy], [EventTypeID], [InstituteID], [Status], [RegistrationDeadline], [CreatedDate], [UpdatedDate]) VALUES (10, N'Ngày hội Sinh viên Sáng tạo 2026', N'Ngày hội giao lưu, sáng tạo và kết nối sinh viên', CAST(N'2026-01-04T05:30:00.000' AS DateTime), CAST(N'2026-01-30T16:59:59.000' AS DateTime), N'Hội trường A - Trường Đại học', CAST(10.776500 AS Decimal(10, 6)), CAST(106.695800 AS Decimal(10, 6)), 150, 300, 2, 3, 2, 1, 3, CAST(N'2026-01-04T05:00:00.000' AS DateTime), CAST(N'2026-01-04T03:26:50.137' AS DateTime), CAST(N'2026-02-02T01:49:27.507' AS DateTime))
INSERT [dbo].[Events] ([EventID], [EventName], [Description], [StartTime], [EndTime], [LocationName], [Latitude], [Longitude], [AllowRadius], [MaxParticipants], [CurrentParticipants], [CreatedBy], [EventTypeID], [InstituteID], [Status], [RegistrationDeadline], [CreatedDate], [UpdatedDate]) VALUES (11, N'Workshop nâng cao 2026', N'Chia sẻ kinh nghiệm thực tế', CAST(N'2026-01-27T22:59:20.580' AS DateTime), CAST(N'2026-02-03T05:00:20.580' AS DateTime), N'Hội trường A', CAST(11.010500 AS Decimal(10, 6)), CAST(106.678900 AS Decimal(10, 6)), 100, 100, 0, 2, 1, 2, 3, CAST(N'2026-01-27T03:52:00.000' AS DateTime), CAST(N'2026-01-24T03:51:13.743' AS DateTime), CAST(N'2026-02-03T07:26:58.683' AS DateTime))
INSERT [dbo].[Events] ([EventID], [EventName], [Description], [StartTime], [EndTime], [LocationName], [Latitude], [Longitude], [AllowRadius], [MaxParticipants], [CurrentParticipants], [CreatedBy], [EventTypeID], [InstituteID], [Status], [RegistrationDeadline], [CreatedDate], [UpdatedDate]) VALUES (12, N'Ngày hội Tình nguyện 2026', N'Hoạt động tình nguyện vì cộng đồng', CAST(N'2026-02-04T00:00:00.000' AS DateTime), CAST(N'2026-02-25T11:00:00.000' AS DateTime), N'Công viên Thành phố', CAST(10.775000 AS Decimal(10, 6)), CAST(106.700000 AS Decimal(10, 6)), 200, 500, 0, 2, 2, 1, 3, CAST(N'2026-01-03T16:59:59.000' AS DateTime), CAST(N'2026-01-24T04:02:23.730' AS DateTime), CAST(N'2026-02-25T14:26:26.037' AS DateTime))
INSERT [dbo].[Events] ([EventID], [EventName], [Description], [StartTime], [EndTime], [LocationName], [Latitude], [Longitude], [AllowRadius], [MaxParticipants], [CurrentParticipants], [CreatedBy], [EventTypeID], [InstituteID], [Status], [RegistrationDeadline], [CreatedDate], [UpdatedDate]) VALUES (1011, N'Tình nguyện mùa Xuân 2026', N'tình nguyện vì cộng đồng', CAST(N'2026-01-28T02:00:49.697' AS DateTime), CAST(N'2026-01-31T14:02:49.697' AS DateTime), N'Công viên Thành phố', CAST(10.775000 AS Decimal(10, 6)), CAST(106.700000 AS Decimal(10, 6)), 100, 100, 0, 2, 3, 2, 3, CAST(N'2026-01-27T02:06:00.000' AS DateTime), CAST(N'2026-01-24T14:06:26.783' AS DateTime), CAST(N'2026-02-02T01:49:27.507' AS DateTime))
INSERT [dbo].[Events] ([EventID], [EventName], [Description], [StartTime], [EndTime], [LocationName], [Latitude], [Longitude], [AllowRadius], [MaxParticipants], [CurrentParticipants], [CreatedBy], [EventTypeID], [InstituteID], [Status], [RegistrationDeadline], [CreatedDate], [UpdatedDate]) VALUES (1012, N'Tình nguyện mùa Hè 2026', N'Tình nguyện mùa Hè 2026', CAST(N'2026-01-29T01:00:00.000' AS DateTime), CAST(N'2026-01-29T11:00:00.000' AS DateTime), N'Công viên Thành phố', CAST(10.775000 AS Decimal(10, 6)), CAST(106.700000 AS Decimal(10, 6)), 100, 100, 0, 2, 1, 1, 3, CAST(N'2026-01-27T01:56:00.000' AS DateTime), CAST(N'2026-01-25T01:51:20.730' AS DateTime), CAST(N'2026-02-02T01:49:27.507' AS DateTime))
INSERT [dbo].[Events] ([EventID], [EventName], [Description], [StartTime], [EndTime], [LocationName], [Latitude], [Longitude], [AllowRadius], [MaxParticipants], [CurrentParticipants], [CreatedBy], [EventTypeID], [InstituteID], [Status], [RegistrationDeadline], [CreatedDate], [UpdatedDate]) VALUES (1013, N'Test Lifecycle', N'Lifecycle test', CAST(N'2026-02-02T02:00:00.000' AS DateTime), CAST(N'2026-02-02T02:07:00.000' AS DateTime), N'Hall A', CAST(90.000000 AS Decimal(10, 6)), CAST(180.000000 AS Decimal(10, 6)), 100, 200, 0, 2, 1, 1, 3, CAST(N'2026-02-02T00:00:00.000' AS DateTime), CAST(N'2026-02-02T01:55:15.120' AS DateTime), CAST(N'2026-02-02T02:07:29.737' AS DateTime))
INSERT [dbo].[Events] ([EventID], [EventName], [Description], [StartTime], [EndTime], [LocationName], [Latitude], [Longitude], [AllowRadius], [MaxParticipants], [CurrentParticipants], [CreatedBy], [EventTypeID], [InstituteID], [Status], [RegistrationDeadline], [CreatedDate], [UpdatedDate]) VALUES (1014, N'Test Lifecycle (Open)', N'Draft -> Open', CAST(N'2026-02-02T02:00:00.000' AS DateTime), CAST(N'2026-02-02T03:00:00.000' AS DateTime), N'Hall A', CAST(90.000000 AS Decimal(10, 6)), CAST(180.000000 AS Decimal(10, 6)), 100, 200, 0, 2, 1, 1, 4, CAST(N'2026-02-02T00:00:00.000' AS DateTime), CAST(N'2026-02-02T01:57:27.830' AS DateTime), CAST(N'2026-02-02T02:09:39.070' AS DateTime))
INSERT [dbo].[Events] ([EventID], [EventName], [Description], [StartTime], [EndTime], [LocationName], [Latitude], [Longitude], [AllowRadius], [MaxParticipants], [CurrentParticipants], [CreatedBy], [EventTypeID], [InstituteID], [Status], [RegistrationDeadline], [CreatedDate], [UpdatedDate]) VALUES (1015, N'Try Closed via Update', N'Should be blocked', CAST(N'2026-02-02T01:00:00.000' AS DateTime), CAST(N'2026-02-02T03:00:00.000' AS DateTime), N'Hall A', CAST(90.000000 AS Decimal(10, 6)), CAST(180.000000 AS Decimal(10, 6)), 100, 200, 0, 2, 1, 1, 3, CAST(N'2026-02-02T00:00:00.000' AS DateTime), CAST(N'2026-02-02T02:01:34.453' AS DateTime), CAST(N'2026-02-02T02:01:34.453' AS DateTime))
INSERT [dbo].[Events] ([EventID], [EventName], [Description], [StartTime], [EndTime], [LocationName], [Latitude], [Longitude], [AllowRadius], [MaxParticipants], [CurrentParticipants], [CreatedBy], [EventTypeID], [InstituteID], [Status], [RegistrationDeadline], [CreatedDate], [UpdatedDate]) VALUES (1016, N'test 1', N'test1', CAST(N'2026-02-02T02:30:00.000' AS DateTime), CAST(N'2026-02-02T03:00:00.000' AS DateTime), N'Hall A', CAST(90.000000 AS Decimal(10, 6)), CAST(180.000000 AS Decimal(10, 6)), 100, 200, 1, 2, 1, 1, 3, CAST(N'2026-02-02T02:00:00.000' AS DateTime), CAST(N'2026-02-02T02:16:02.677' AS DateTime), CAST(N'2026-02-02T07:59:05.970' AS DateTime))
INSERT [dbo].[Events] ([EventID], [EventName], [Description], [StartTime], [EndTime], [LocationName], [Latitude], [Longitude], [AllowRadius], [MaxParticipants], [CurrentParticipants], [CreatedBy], [EventTypeID], [InstituteID], [Status], [RegistrationDeadline], [CreatedDate], [UpdatedDate]) VALUES (1017, N'test 1', N'test1', CAST(N'2026-02-02T02:10:00.000' AS DateTime), CAST(N'2026-02-02T03:00:00.000' AS DateTime), N'Hall A', CAST(90.000000 AS Decimal(10, 6)), CAST(180.000000 AS Decimal(10, 6)), 100, 200, 0, 2, 1, 1, 3, CAST(N'2026-02-02T02:00:00.000' AS DateTime), CAST(N'2026-02-02T02:17:01.850' AS DateTime), CAST(N'2026-02-02T07:59:05.970' AS DateTime))
INSERT [dbo].[Events] ([EventID], [EventName], [Description], [StartTime], [EndTime], [LocationName], [Latitude], [Longitude], [AllowRadius], [MaxParticipants], [CurrentParticipants], [CreatedBy], [EventTypeID], [InstituteID], [Status], [RegistrationDeadline], [CreatedDate], [UpdatedDate]) VALUES (1018, N'test 2', N'test2', CAST(N'2026-02-02T02:30:00.000' AS DateTime), CAST(N'2026-02-02T03:00:00.000' AS DateTime), N'Hall A', CAST(90.000000 AS Decimal(10, 6)), CAST(180.000000 AS Decimal(10, 6)), 100, 200, 1, 2, 1, 1, 3, CAST(N'2026-02-02T02:27:00.000' AS DateTime), CAST(N'2026-02-02T02:25:34.820' AS DateTime), CAST(N'2026-02-02T07:59:05.970' AS DateTime))
INSERT [dbo].[Events] ([EventID], [EventName], [Description], [StartTime], [EndTime], [LocationName], [Latitude], [Longitude], [AllowRadius], [MaxParticipants], [CurrentParticipants], [CreatedBy], [EventTypeID], [InstituteID], [Status], [RegistrationDeadline], [CreatedDate], [UpdatedDate]) VALUES (1019, N't1', N'test', CAST(N'2026-02-06T10:25:00.000' AS DateTime), CAST(N'2026-02-07T12:25:00.000' AS DateTime), N'Hội trường A', CAST(90.000000 AS Decimal(10, 6)), CAST(50.000000 AS Decimal(10, 6)), 100, 100, 0, 2, 1, 1, 0, CAST(N'2026-02-05T10:26:00.000' AS DateTime), CAST(N'2026-02-04T10:26:27.030' AS DateTime), CAST(N'2026-02-04T10:26:27.030' AS DateTime))
INSERT [dbo].[Events] ([EventID], [EventName], [Description], [StartTime], [EndTime], [LocationName], [Latitude], [Longitude], [AllowRadius], [MaxParticipants], [CurrentParticipants], [CreatedBy], [EventTypeID], [InstituteID], [Status], [RegistrationDeadline], [CreatedDate], [UpdatedDate]) VALUES (1020, N't2', N't2', CAST(N'2026-02-06T10:28:00.000' AS DateTime), CAST(N'2026-02-14T12:28:00.000' AS DateTime), N'Hội trường A', CAST(90.000000 AS Decimal(10, 6)), CAST(50.000000 AS Decimal(10, 6)), 100, 100, 0, 2, 1, 1, 3, CAST(N'2026-02-05T10:28:00.000' AS DateTime), CAST(N'2026-02-04T10:28:39.367' AS DateTime), CAST(N'2026-02-16T19:33:03.163' AS DateTime))
INSERT [dbo].[Events] ([EventID], [EventName], [Description], [StartTime], [EndTime], [LocationName], [Latitude], [Longitude], [AllowRadius], [MaxParticipants], [CurrentParticipants], [CreatedBy], [EventTypeID], [InstituteID], [Status], [RegistrationDeadline], [CreatedDate], [UpdatedDate]) VALUES (1021, N't3', N't3', CAST(N'2026-02-14T10:46:00.000' AS DateTime), CAST(N'2026-02-28T12:46:00.000' AS DateTime), NULL, CAST(45.000000 AS Decimal(10, 6)), CAST(32.000000 AS Decimal(10, 6)), 100, 424, 0, 2, 1, 1, 3, CAST(N'2026-02-05T10:46:00.000' AS DateTime), CAST(N'2026-02-04T10:46:49.130' AS DateTime), CAST(N'2026-02-28T14:33:08.053' AS DateTime))
INSERT [dbo].[Events] ([EventID], [EventName], [Description], [StartTime], [EndTime], [LocationName], [Latitude], [Longitude], [AllowRadius], [MaxParticipants], [CurrentParticipants], [CreatedBy], [EventTypeID], [InstituteID], [Status], [RegistrationDeadline], [CreatedDate], [UpdatedDate]) VALUES (1022, N't4', NULL, CAST(N'2026-02-14T15:22:00.000' AS DateTime), CAST(N'2026-02-20T17:22:00.000' AS DateTime), NULL, CAST(45.000000 AS Decimal(10, 6)), CAST(32.000000 AS Decimal(10, 6)), 100, 424, 0, 2, 2, 1, 4, CAST(N'2026-02-06T15:22:00.000' AS DateTime), CAST(N'2026-02-04T15:22:40.590' AS DateTime), CAST(N'2026-02-08T09:20:17.787' AS DateTime))
INSERT [dbo].[Events] ([EventID], [EventName], [Description], [StartTime], [EndTime], [LocationName], [Latitude], [Longitude], [AllowRadius], [MaxParticipants], [CurrentParticipants], [CreatedBy], [EventTypeID], [InstituteID], [Status], [RegistrationDeadline], [CreatedDate], [UpdatedDate]) VALUES (1023, N't22', N'te22', CAST(N'2026-02-07T09:15:00.000' AS DateTime), CAST(N'2026-02-07T11:15:00.000' AS DateTime), NULL, NULL, NULL, 100, NULL, 0, 2, 1, NULL, 0, NULL, CAST(N'2026-02-06T09:16:48.150' AS DateTime), CAST(N'2026-02-06T09:16:48.150' AS DateTime))
INSERT [dbo].[Events] ([EventID], [EventName], [Description], [StartTime], [EndTime], [LocationName], [Latitude], [Longitude], [AllowRadius], [MaxParticipants], [CurrentParticipants], [CreatedBy], [EventTypeID], [InstituteID], [Status], [RegistrationDeadline], [CreatedDate], [UpdatedDate]) VALUES (1024, N'te33', NULL, CAST(N'2026-02-07T09:34:00.000' AS DateTime), CAST(N'2026-02-07T11:34:00.000' AS DateTime), NULL, NULL, NULL, 100, NULL, 0, 2, 1, NULL, 0, CAST(N'2026-02-06T09:34:00.000' AS DateTime), CAST(N'2026-02-06T09:34:53.473' AS DateTime), CAST(N'2026-02-06T09:34:53.473' AS DateTime))
INSERT [dbo].[Events] ([EventID], [EventName], [Description], [StartTime], [EndTime], [LocationName], [Latitude], [Longitude], [AllowRadius], [MaxParticipants], [CurrentParticipants], [CreatedBy], [EventTypeID], [InstituteID], [Status], [RegistrationDeadline], [CreatedDate], [UpdatedDate]) VALUES (1025, N'r22', NULL, CAST(N'2026-02-28T09:35:00.000' AS DateTime), CAST(N'2026-03-01T11:35:00.000' AS DateTime), NULL, CAST(32.000000 AS Decimal(10, 6)), CAST(11.999998 AS Decimal(10, 6)), 100, 11, 0, 2, 1, 1, 4, CAST(N'2026-02-08T09:35:00.000' AS DateTime), CAST(N'2026-02-06T09:35:52.270' AS DateTime), CAST(N'2026-02-08T09:20:24.653' AS DateTime))
INSERT [dbo].[Events] ([EventID], [EventName], [Description], [StartTime], [EndTime], [LocationName], [Latitude], [Longitude], [AllowRadius], [MaxParticipants], [CurrentParticipants], [CreatedBy], [EventTypeID], [InstituteID], [Status], [RegistrationDeadline], [CreatedDate], [UpdatedDate]) VALUES (1026, N'gps', NULL, CAST(N'2026-02-07T10:11:00.000' AS DateTime), CAST(N'2026-02-07T12:11:00.000' AS DateTime), N'Trường Đại học Thủ Dầu Một, Trần Văn Ơn, Phú Hòa 2, Phường Phú Lợi, Thành phố Hồ Chí Minh, 75107, Việt Nam', CAST(10.980333 AS Decimal(10, 6)), CAST(106.673802 AS Decimal(10, 6)), 100, NULL, 0, 2, 1, 1, 0, NULL, CAST(N'2026-02-06T10:14:10.667' AS DateTime), CAST(N'2026-02-06T10:14:10.667' AS DateTime))
INSERT [dbo].[Events] ([EventID], [EventName], [Description], [StartTime], [EndTime], [LocationName], [Latitude], [Longitude], [AllowRadius], [MaxParticipants], [CurrentParticipants], [CreatedBy], [EventTypeID], [InstituteID], [Status], [RegistrationDeadline], [CreatedDate], [UpdatedDate]) VALUES (1027, N'aaaa', NULL, CAST(N'2026-02-20T19:15:00.000' AS DateTime), CAST(N'2026-02-21T21:15:00.000' AS DateTime), NULL, NULL, NULL, 100, 111, 0, 3, 3, 1, 3, CAST(N'2026-02-17T19:15:00.000' AS DateTime), CAST(N'2026-02-12T19:15:58.847' AS DateTime), CAST(N'2026-02-22T09:00:12.523' AS DateTime))
INSERT [dbo].[Events] ([EventID], [EventName], [Description], [StartTime], [EndTime], [LocationName], [Latitude], [Longitude], [AllowRadius], [MaxParticipants], [CurrentParticipants], [CreatedBy], [EventTypeID], [InstituteID], [Status], [RegistrationDeadline], [CreatedDate], [UpdatedDate]) VALUES (1028, N'aaaa', NULL, CAST(N'2026-02-20T14:35:00.000' AS DateTime), CAST(N'2026-02-22T16:39:00.000' AS DateTime), N'Vĩnh An, Phường Tân Khánh, Thành phố Hồ Chí Minh, Việt Nam', CAST(11.016823 AS Decimal(10, 6)), CAST(106.713946 AS Decimal(10, 6)), 100, 111, 1, 2, 1, NULL, 3, CAST(N'2026-02-20T12:39:00.000' AS DateTime), CAST(N'2026-02-18T14:40:33.817' AS DateTime), CAST(N'2026-02-23T08:55:54.797' AS DateTime))
INSERT [dbo].[Events] ([EventID], [EventName], [Description], [StartTime], [EndTime], [LocationName], [Latitude], [Longitude], [AllowRadius], [MaxParticipants], [CurrentParticipants], [CreatedBy], [EventTypeID], [InstituteID], [Status], [RegistrationDeadline], [CreatedDate], [UpdatedDate]) VALUES (1029, N'string', N'string', CAST(N'2026-02-22T07:34:01.307' AS DateTime), CAST(N'2026-02-23T07:34:01.307' AS DateTime), N'string', CAST(90.000000 AS Decimal(10, 6)), CAST(180.000000 AS Decimal(10, 6)), 100, 100, 0, 2, 1, 1, 3, CAST(N'2026-02-21T07:34:01.307' AS DateTime), CAST(N'2026-02-19T14:35:02.597' AS DateTime), CAST(N'2026-02-23T08:55:54.797' AS DateTime))
INSERT [dbo].[Events] ([EventID], [EventName], [Description], [StartTime], [EndTime], [LocationName], [Latitude], [Longitude], [AllowRadius], [MaxParticipants], [CurrentParticipants], [CreatedBy], [EventTypeID], [InstituteID], [Status], [RegistrationDeadline], [CreatedDate], [UpdatedDate]) VALUES (1030, N't1', N'string', CAST(N'2026-02-23T11:37:14.987' AS DateTime), CAST(N'2026-02-24T11:37:14.987' AS DateTime), N'string', CAST(90.000000 AS Decimal(10, 6)), CAST(180.000000 AS Decimal(10, 6)), 10000, 2147483647, 0, 2, 1, 1, 3, CAST(N'2026-02-22T11:37:14.987' AS DateTime), CAST(N'2026-02-19T18:37:38.783' AS DateTime), CAST(N'2026-02-25T14:26:26.037' AS DateTime))
INSERT [dbo].[Events] ([EventID], [EventName], [Description], [StartTime], [EndTime], [LocationName], [Latitude], [Longitude], [AllowRadius], [MaxParticipants], [CurrentParticipants], [CreatedBy], [EventTypeID], [InstituteID], [Status], [RegistrationDeadline], [CreatedDate], [UpdatedDate]) VALUES (1031, N't2', N'string', CAST(N'2026-02-23T11:37:14.987' AS DateTime), CAST(N'2026-02-24T11:37:14.987' AS DateTime), N'string', CAST(90.000000 AS Decimal(10, 6)), CAST(180.000000 AS Decimal(10, 6)), 10000, 2147483647, 0, 2, 1, 1, 3, CAST(N'2026-02-22T11:37:14.987' AS DateTime), CAST(N'2026-02-19T18:37:47.977' AS DateTime), CAST(N'2026-02-25T14:26:26.037' AS DateTime))
INSERT [dbo].[Events] ([EventID], [EventName], [Description], [StartTime], [EndTime], [LocationName], [Latitude], [Longitude], [AllowRadius], [MaxParticipants], [CurrentParticipants], [CreatedBy], [EventTypeID], [InstituteID], [Status], [RegistrationDeadline], [CreatedDate], [UpdatedDate]) VALUES (1032, N't3', N'string', CAST(N'2026-02-23T11:37:14.987' AS DateTime), CAST(N'2026-02-24T11:37:14.987' AS DateTime), N'string', CAST(90.000000 AS Decimal(10, 6)), CAST(180.000000 AS Decimal(10, 6)), 10000, 2147483647, 0, 2, 1, 1, 3, CAST(N'2026-02-22T11:37:14.987' AS DateTime), CAST(N'2026-02-19T18:37:57.627' AS DateTime), CAST(N'2026-02-25T14:26:26.037' AS DateTime))
INSERT [dbo].[Events] ([EventID], [EventName], [Description], [StartTime], [EndTime], [LocationName], [Latitude], [Longitude], [AllowRadius], [MaxParticipants], [CurrentParticipants], [CreatedBy], [EventTypeID], [InstituteID], [Status], [RegistrationDeadline], [CreatedDate], [UpdatedDate]) VALUES (1033, N'a1', NULL, CAST(N'2026-02-21T09:30:00.000' AS DateTime), CAST(N'2026-02-22T11:15:00.000' AS DateTime), N'Nha Nghi Mini, Trần Tử Bình, Phú Cường 4, Phường Thủ Dầu Một, Thành phố Hồ Chí Minh, 75106, Việt Nam', CAST(10.976111 AS Decimal(10, 6)), CAST(106.655987 AS Decimal(10, 6)), 100, 1211, 0, 2, 4, NULL, 3, CAST(N'2026-02-21T09:25:00.000' AS DateTime), CAST(N'2026-02-21T09:17:37.523' AS DateTime), CAST(N'2026-02-22T14:29:08.630' AS DateTime))
INSERT [dbo].[Events] ([EventID], [EventName], [Description], [StartTime], [EndTime], [LocationName], [Latitude], [Longitude], [AllowRadius], [MaxParticipants], [CurrentParticipants], [CreatedBy], [EventTypeID], [InstituteID], [Status], [RegistrationDeadline], [CreatedDate], [UpdatedDate]) VALUES (1034, N'a2', NULL, CAST(N'2026-02-21T09:30:00.000' AS DateTime), CAST(N'2026-02-22T11:19:00.000' AS DateTime), N'Ngô Quyền, Phú Cường 6, Phường Thủ Dầu Một, Thành phố Hồ Chí Minh, 75106, Việt Nam', CAST(10.982583 AS Decimal(10, 6)), CAST(106.653947 AS Decimal(10, 6)), 100, 111, 0, 2, 4, NULL, 3, CAST(N'2026-02-21T09:20:00.000' AS DateTime), CAST(N'2026-02-21T09:19:41.527' AS DateTime), CAST(N'2026-02-22T14:29:08.630' AS DateTime))
INSERT [dbo].[Events] ([EventID], [EventName], [Description], [StartTime], [EndTime], [LocationName], [Latitude], [Longitude], [AllowRadius], [MaxParticipants], [CurrentParticipants], [CreatedBy], [EventTypeID], [InstituteID], [Status], [RegistrationDeadline], [CreatedDate], [UpdatedDate]) VALUES (1035, N'a3', NULL, CAST(N'2026-02-23T09:22:00.000' AS DateTime), CAST(N'2026-02-24T11:22:00.000' AS DateTime), N'Hẻm 162 Phan Đăng Lưu, Phường Đức Nhuận, Thành phố Thủ Đức, Thành phố Hồ Chí Minh, 72212, Việt Nam', CAST(10.801687 AS Decimal(10, 6)), CAST(106.681775 AS Decimal(10, 6)), 100, NULL, 0, 2, 3, NULL, 3, CAST(N'2026-02-22T09:22:00.000' AS DateTime), CAST(N'2026-02-21T09:23:13.767' AS DateTime), CAST(N'2026-02-25T14:26:26.037' AS DateTime))
INSERT [dbo].[Events] ([EventID], [EventName], [Description], [StartTime], [EndTime], [LocationName], [Latitude], [Longitude], [AllowRadius], [MaxParticipants], [CurrentParticipants], [CreatedBy], [EventTypeID], [InstituteID], [Status], [RegistrationDeadline], [CreatedDate], [UpdatedDate]) VALUES (1036, N'q', N'qqqqq', CAST(N'2026-02-26T07:29:00.000' AS DateTime), CAST(N'2026-03-01T21:29:00.000' AS DateTime), N'Hẻm 148 Nguyễn Lâm, Khu phố 19, Phường Gia Định, Thành phố Thủ Đức, Thành phố Hồ Chí Minh, 72210, Việt Nam', CAST(10.798167 AS Decimal(10, 6)), CAST(106.692124 AS Decimal(10, 6)), 100, 11, 0, 2, 1, NULL, 3, CAST(N'2026-02-25T23:41:00.000' AS DateTime), CAST(N'2026-02-25T19:30:30.227' AS DateTime), CAST(N'2026-03-02T14:29:40.357' AS DateTime))
INSERT [dbo].[Events] ([EventID], [EventName], [Description], [StartTime], [EndTime], [LocationName], [Latitude], [Longitude], [AllowRadius], [MaxParticipants], [CurrentParticipants], [CreatedBy], [EventTypeID], [InstituteID], [Status], [RegistrationDeadline], [CreatedDate], [UpdatedDate]) VALUES (1037, N'qq1', NULL, CAST(N'2026-02-26T07:35:00.000' AS DateTime), CAST(N'2026-02-28T21:35:00.000' AS DateTime), N'Khu phố 22, Phường Nhiêu Lộc, Thành phố Thủ Đức, Thành phố Hồ Chí Minh, 72117, Việt Nam', CAST(10.786734 AS Decimal(10, 6)), CAST(106.666456 AS Decimal(10, 6)), 100, 11, 0, 2, 4, NULL, 3, CAST(N'2026-02-25T23:35:00.000' AS DateTime), CAST(N'2026-02-25T19:35:35.907' AS DateTime), CAST(N'2026-03-01T15:04:03.053' AS DateTime))
INSERT [dbo].[Events] ([EventID], [EventName], [Description], [StartTime], [EndTime], [LocationName], [Latitude], [Longitude], [AllowRadius], [MaxParticipants], [CurrentParticipants], [CreatedBy], [EventTypeID], [InstituteID], [Status], [RegistrationDeadline], [CreatedDate], [UpdatedDate]) VALUES (1038, N'444', NULL, CAST(N'2026-03-02T09:02:00.000' AS DateTime), CAST(N'2026-03-06T11:02:00.000' AS DateTime), N'Hẻm 230 Pasteur, Khu phố 5, Phường Xuân Hòa, Thành phố Thủ Đức, Thành phố Hồ Chí Minh, 72200, Việt Nam', CAST(10.785048 AS Decimal(10, 6)), CAST(106.691527 AS Decimal(10, 6)), 100, 100, 0, 2, 2, NULL, 3, CAST(N'2026-03-01T09:02:00.000' AS DateTime), CAST(N'2026-02-28T09:02:29.077' AS DateTime), CAST(N'2026-03-06T18:56:58.977' AS DateTime))
INSERT [dbo].[Events] ([EventID], [EventName], [Description], [StartTime], [EndTime], [LocationName], [Latitude], [Longitude], [AllowRadius], [MaxParticipants], [CurrentParticipants], [CreatedBy], [EventTypeID], [InstituteID], [Status], [RegistrationDeadline], [CreatedDate], [UpdatedDate]) VALUES (2038, N'cb', NULL, CAST(N'2026-03-03T14:46:00.000' AS DateTime), CAST(N'2026-03-07T16:46:00.000' AS DateTime), N'Trương Định, Khu phố 7, Phường Bến Thành, Thành phố Thủ Đức, Thành phố Hồ Chí Minh, 71009, Việt Nam', CAST(10.775436 AS Decimal(10, 6)), CAST(106.692558 AS Decimal(10, 6)), 100, 123, 1, 3, 1, 1, 3, CAST(N'2026-03-02T14:46:00.000' AS DateTime), CAST(N'2026-02-28T14:47:04.630' AS DateTime), CAST(N'2026-03-07T19:50:04.537' AS DateTime))
SET IDENTITY_INSERT [dbo].[Events] OFF
GO
SET IDENTITY_INSERT [dbo].[EventType] ON 

INSERT [dbo].[EventType] ([TypeID], [TypeName], [Description], [CreatedDate]) VALUES (1, N'Hội thảo', N'Các buổi hội thảo chuyên môn', CAST(N'2025-12-27T14:26:26.133' AS DateTime))
INSERT [dbo].[EventType] ([TypeID], [TypeName], [Description], [CreatedDate]) VALUES (2, N'Tình nguyện', N'Hoạt động tình nguyện', CAST(N'2025-12-27T14:26:26.133' AS DateTime))
INSERT [dbo].[EventType] ([TypeID], [TypeName], [Description], [CreatedDate]) VALUES (3, N'Thể thao', N'Các hoạt động thể thao', CAST(N'2025-12-27T14:26:26.133' AS DateTime))
INSERT [dbo].[EventType] ([TypeID], [TypeName], [Description], [CreatedDate]) VALUES (4, N'Văn hóa', N'Sự kiện văn hóa nghệ thuật', CAST(N'2025-12-27T14:26:26.133' AS DateTime))
INSERT [dbo].[EventType] ([TypeID], [TypeName], [Description], [CreatedDate]) VALUES (5, N'test', N'tesst', CAST(N'2026-02-04T20:23:23.263' AS DateTime))
SET IDENTITY_INSERT [dbo].[EventType] OFF
GO
SET IDENTITY_INSERT [dbo].[Institutes] ON 

INSERT [dbo].[Institutes] ([InstituteID], [InstituteName], [Description], [ContactEmail], [Status], [CreatedDate], [UpdatedDate]) VALUES (1, N'Viện Công Nghệ Số', N'Viện đào tạo chuyên ngành CNTT', N'cntt@uniyouth.edu.vn', 1, CAST(N'2025-12-22T15:45:18.837' AS DateTime), CAST(N'2025-12-22T15:45:18.837' AS DateTime))
INSERT [dbo].[Institutes] ([InstituteID], [InstituteName], [Description], [ContactEmail], [Status], [CreatedDate], [UpdatedDate]) VALUES (2, N'Viện Kinh tế', N'Viện đào tạo chuyên ngành Kinh tế', N'ktqd@uniyouth.edu.vn', 1, CAST(N'2025-12-22T15:45:18.843' AS DateTime), CAST(N'2025-12-22T15:45:18.843' AS DateTime))
SET IDENTITY_INSERT [dbo].[Institutes] OFF
GO
SET IDENTITY_INSERT [dbo].[LocationPresets] ON 

INSERT [dbo].[LocationPresets] ([LocationPresetID], [Name], [Address], [Latitude], [Longitude], [RadiusMeters], [InstituteID], [UnitID], [IsActive], [CreatedBy], [CreatedDate], [UpdatedDate]) VALUES (1, N'home', N'Chánh Long, Phường Bình Dương, Thành phố Hồ Chí Minh, Việt Nam', CAST(11.065890 AS Decimal(10, 6)), CAST(106.702950 AS Decimal(10, 6)), 100, 1, NULL, 1, 2, CAST(N'2026-02-10T18:57:09.843' AS DateTime), CAST(N'2026-02-10T18:57:09.843' AS DateTime))
INSERT [dbo].[LocationPresets] ([LocationPresetID], [Name], [Address], [Latitude], [Longitude], [RadiusMeters], [InstituteID], [UnitID], [IsActive], [CreatedBy], [CreatedDate], [UpdatedDate]) VALUES (2, N'aaaaaaa', N'Thành phố Hồ Chí Minh, Việt Nam', CAST(11.065597 AS Decimal(10, 6)), CAST(106.703096 AS Decimal(10, 6)), NULL, NULL, 1, 1, 3, CAST(N'2026-02-12T15:37:24.810' AS DateTime), CAST(N'2026-02-12T15:37:24.810' AS DateTime))
SET IDENTITY_INSERT [dbo].[LocationPresets] OFF
GO
SET IDENTITY_INSERT [dbo].[NotificationDeliveryLog] ON 

INSERT [dbo].[NotificationDeliveryLog] ([DeliveryLogID], [OutboxID], [NotificationID], [UserID], [Channel], [AttemptNumber], [IsSuccess], [ErrorMessage], [CreatedDate]) VALUES (1, 1, 1026, 4, 1, 1, 1, NULL, CAST(N'2026-02-27T09:25:25.767' AS DateTime))
INSERT [dbo].[NotificationDeliveryLog] ([DeliveryLogID], [OutboxID], [NotificationID], [UserID], [Channel], [AttemptNumber], [IsSuccess], [ErrorMessage], [CreatedDate]) VALUES (2, 2, 1026, 4, 2, 1, 1, NULL, CAST(N'2026-02-27T09:25:25.880' AS DateTime))
INSERT [dbo].[NotificationDeliveryLog] ([DeliveryLogID], [OutboxID], [NotificationID], [UserID], [Channel], [AttemptNumber], [IsSuccess], [ErrorMessage], [CreatedDate]) VALUES (3, 3, 1027, 2, 1, 1, 1, NULL, CAST(N'2026-02-28T09:02:33.540' AS DateTime))
INSERT [dbo].[NotificationDeliveryLog] ([DeliveryLogID], [OutboxID], [NotificationID], [UserID], [Channel], [AttemptNumber], [IsSuccess], [ErrorMessage], [CreatedDate]) VALUES (4, 4, 1028, 2, 1, 1, 1, NULL, CAST(N'2026-02-28T09:04:39.017' AS DateTime))
INSERT [dbo].[NotificationDeliveryLog] ([DeliveryLogID], [OutboxID], [NotificationID], [UserID], [Channel], [AttemptNumber], [IsSuccess], [ErrorMessage], [CreatedDate]) VALUES (5, 5, 1029, 2, 1, 1, 1, NULL, CAST(N'2026-02-28T09:19:26.807' AS DateTime))
INSERT [dbo].[NotificationDeliveryLog] ([DeliveryLogID], [OutboxID], [NotificationID], [UserID], [Channel], [AttemptNumber], [IsSuccess], [ErrorMessage], [CreatedDate]) VALUES (6, 6, 1030, 2, 1, 1, 1, NULL, CAST(N'2026-02-28T09:24:12.990' AS DateTime))
INSERT [dbo].[NotificationDeliveryLog] ([DeliveryLogID], [OutboxID], [NotificationID], [UserID], [Channel], [AttemptNumber], [IsSuccess], [ErrorMessage], [CreatedDate]) VALUES (1003, 1003, 2027, 2, 1, 1, 1, NULL, CAST(N'2026-02-28T14:38:10.267' AS DateTime))
INSERT [dbo].[NotificationDeliveryLog] ([DeliveryLogID], [OutboxID], [NotificationID], [UserID], [Channel], [AttemptNumber], [IsSuccess], [ErrorMessage], [CreatedDate]) VALUES (1004, 1004, 2028, 2, 1, 1, 1, NULL, CAST(N'2026-02-28T14:41:55.963' AS DateTime))
INSERT [dbo].[NotificationDeliveryLog] ([DeliveryLogID], [OutboxID], [NotificationID], [UserID], [Channel], [AttemptNumber], [IsSuccess], [ErrorMessage], [CreatedDate]) VALUES (1005, 1005, 2029, 3, 1, 1, 1, NULL, CAST(N'2026-02-28T14:47:06.813' AS DateTime))
INSERT [dbo].[NotificationDeliveryLog] ([DeliveryLogID], [OutboxID], [NotificationID], [UserID], [Channel], [AttemptNumber], [IsSuccess], [ErrorMessage], [CreatedDate]) VALUES (1006, 1006, 2030, 4, 1, 1, 1, NULL, CAST(N'2026-03-01T15:34:06.147' AS DateTime))
INSERT [dbo].[NotificationDeliveryLog] ([DeliveryLogID], [OutboxID], [NotificationID], [UserID], [Channel], [AttemptNumber], [IsSuccess], [ErrorMessage], [CreatedDate]) VALUES (1007, 1007, 2030, 4, 2, 1, 1, NULL, CAST(N'2026-03-01T15:34:06.273' AS DateTime))
SET IDENTITY_INSERT [dbo].[NotificationDeliveryLog] OFF
GO
SET IDENTITY_INSERT [dbo].[NotificationOutbox] ON 

INSERT [dbo].[NotificationOutbox] ([OutboxID], [NotificationID], [UserID], [Channel], [Status], [AttemptCount], [MaxAttempts], [NextAttemptAt], [LastAttemptAt], [ProcessedAt], [LastError], [CreatedDate], [UpdatedDate]) VALUES (1, 1026, 4, 1, 2, 1, 5, CAST(N'2026-02-27T09:25:23.210' AS DateTime), CAST(N'2026-02-27T09:25:25.667' AS DateTime), CAST(N'2026-02-27T09:25:25.767' AS DateTime), NULL, CAST(N'2026-02-27T09:25:23.210' AS DateTime), CAST(N'2026-02-27T09:25:25.767' AS DateTime))
INSERT [dbo].[NotificationOutbox] ([OutboxID], [NotificationID], [UserID], [Channel], [Status], [AttemptCount], [MaxAttempts], [NextAttemptAt], [LastAttemptAt], [ProcessedAt], [LastError], [CreatedDate], [UpdatedDate]) VALUES (2, 1026, 4, 2, 2, 1, 5, CAST(N'2026-02-27T09:25:23.210' AS DateTime), CAST(N'2026-02-27T09:25:25.797' AS DateTime), CAST(N'2026-02-27T09:25:25.880' AS DateTime), NULL, CAST(N'2026-02-27T09:25:23.210' AS DateTime), CAST(N'2026-02-27T09:25:25.880' AS DateTime))
INSERT [dbo].[NotificationOutbox] ([OutboxID], [NotificationID], [UserID], [Channel], [Status], [AttemptCount], [MaxAttempts], [NextAttemptAt], [LastAttemptAt], [ProcessedAt], [LastError], [CreatedDate], [UpdatedDate]) VALUES (3, 1027, 2, 1, 2, 1, 5, CAST(N'2026-02-28T09:02:29.233' AS DateTime), CAST(N'2026-02-28T09:02:33.380' AS DateTime), CAST(N'2026-02-28T09:02:33.540' AS DateTime), NULL, CAST(N'2026-02-28T09:02:29.233' AS DateTime), CAST(N'2026-02-28T09:02:33.540' AS DateTime))
INSERT [dbo].[NotificationOutbox] ([OutboxID], [NotificationID], [UserID], [Channel], [Status], [AttemptCount], [MaxAttempts], [NextAttemptAt], [LastAttemptAt], [ProcessedAt], [LastError], [CreatedDate], [UpdatedDate]) VALUES (4, 1028, 2, 1, 2, 1, 5, CAST(N'2026-02-28T09:04:37.423' AS DateTime), CAST(N'2026-02-28T09:04:38.950' AS DateTime), CAST(N'2026-02-28T09:04:39.017' AS DateTime), NULL, CAST(N'2026-02-28T09:04:37.423' AS DateTime), CAST(N'2026-02-28T09:04:39.017' AS DateTime))
INSERT [dbo].[NotificationOutbox] ([OutboxID], [NotificationID], [UserID], [Channel], [Status], [AttemptCount], [MaxAttempts], [NextAttemptAt], [LastAttemptAt], [ProcessedAt], [LastError], [CreatedDate], [UpdatedDate]) VALUES (5, 1029, 2, 1, 2, 1, 5, CAST(N'2026-02-28T09:19:22.867' AS DateTime), CAST(N'2026-02-28T09:19:26.587' AS DateTime), CAST(N'2026-02-28T09:19:26.807' AS DateTime), NULL, CAST(N'2026-02-28T09:19:22.867' AS DateTime), CAST(N'2026-02-28T09:19:26.807' AS DateTime))
INSERT [dbo].[NotificationOutbox] ([OutboxID], [NotificationID], [UserID], [Channel], [Status], [AttemptCount], [MaxAttempts], [NextAttemptAt], [LastAttemptAt], [ProcessedAt], [LastError], [CreatedDate], [UpdatedDate]) VALUES (6, 1030, 2, 1, 2, 1, 5, CAST(N'2026-02-28T09:24:12.283' AS DateTime), CAST(N'2026-02-28T09:24:12.980' AS DateTime), CAST(N'2026-02-28T09:24:12.990' AS DateTime), NULL, CAST(N'2026-02-28T09:24:12.283' AS DateTime), CAST(N'2026-02-28T09:24:12.990' AS DateTime))
INSERT [dbo].[NotificationOutbox] ([OutboxID], [NotificationID], [UserID], [Channel], [Status], [AttemptCount], [MaxAttempts], [NextAttemptAt], [LastAttemptAt], [ProcessedAt], [LastError], [CreatedDate], [UpdatedDate]) VALUES (1003, 2027, 2, 1, 2, 1, 5, CAST(N'2026-02-28T14:38:07.513' AS DateTime), CAST(N'2026-02-28T14:38:10.117' AS DateTime), CAST(N'2026-02-28T14:38:10.267' AS DateTime), NULL, CAST(N'2026-02-28T14:38:07.513' AS DateTime), CAST(N'2026-02-28T14:38:10.267' AS DateTime))
INSERT [dbo].[NotificationOutbox] ([OutboxID], [NotificationID], [UserID], [Channel], [Status], [AttemptCount], [MaxAttempts], [NextAttemptAt], [LastAttemptAt], [ProcessedAt], [LastError], [CreatedDate], [UpdatedDate]) VALUES (1004, 2028, 2, 1, 2, 1, 5, CAST(N'2026-02-28T14:41:53.240' AS DateTime), CAST(N'2026-02-28T14:41:55.957' AS DateTime), CAST(N'2026-02-28T14:41:55.963' AS DateTime), NULL, CAST(N'2026-02-28T14:41:53.240' AS DateTime), CAST(N'2026-02-28T14:41:55.963' AS DateTime))
INSERT [dbo].[NotificationOutbox] ([OutboxID], [NotificationID], [UserID], [Channel], [Status], [AttemptCount], [MaxAttempts], [NextAttemptAt], [LastAttemptAt], [ProcessedAt], [LastError], [CreatedDate], [UpdatedDate]) VALUES (1005, 2029, 3, 1, 2, 1, 5, CAST(N'2026-02-28T14:47:04.673' AS DateTime), CAST(N'2026-02-28T14:47:06.803' AS DateTime), CAST(N'2026-02-28T14:47:06.813' AS DateTime), NULL, CAST(N'2026-02-28T14:47:04.673' AS DateTime), CAST(N'2026-02-28T14:47:06.813' AS DateTime))
INSERT [dbo].[NotificationOutbox] ([OutboxID], [NotificationID], [UserID], [Channel], [Status], [AttemptCount], [MaxAttempts], [NextAttemptAt], [LastAttemptAt], [ProcessedAt], [LastError], [CreatedDate], [UpdatedDate]) VALUES (1006, 2030, 4, 1, 2, 1, 5, CAST(N'2026-03-01T15:34:01.530' AS DateTime), CAST(N'2026-03-01T15:34:06.060' AS DateTime), CAST(N'2026-03-01T15:34:06.147' AS DateTime), NULL, CAST(N'2026-03-01T15:34:01.530' AS DateTime), CAST(N'2026-03-01T15:34:06.147' AS DateTime))
INSERT [dbo].[NotificationOutbox] ([OutboxID], [NotificationID], [UserID], [Channel], [Status], [AttemptCount], [MaxAttempts], [NextAttemptAt], [LastAttemptAt], [ProcessedAt], [LastError], [CreatedDate], [UpdatedDate]) VALUES (1007, 2030, 4, 2, 2, 1, 5, CAST(N'2026-03-01T15:34:01.530' AS DateTime), CAST(N'2026-03-01T15:34:06.173' AS DateTime), CAST(N'2026-03-01T15:34:06.273' AS DateTime), NULL, CAST(N'2026-03-01T15:34:01.530' AS DateTime), CAST(N'2026-03-01T15:34:06.273' AS DateTime))
SET IDENTITY_INSERT [dbo].[NotificationOutbox] OFF
GO
SET IDENTITY_INSERT [dbo].[Notifications] ON 

INSERT [dbo].[Notifications] ([NotificationID], [UserID], [EventID], [Title], [Content], [NotificationTypeID], [Priority], [IsRead], [ReadDate], [ActionUrl], [CreatedDate], [ExpiryDate], [DedupKey], [Audience], [TargetRole]) VALUES (1, 4, 9, N'Điểm danh thành công', N'Bạn đã điểm danh sự kiện "Chiến dịch Mùa hè xanh 2026" thành công. Bạn được cộng 10 điểm rèn luyện.', 2, 0, 1, CAST(N'2026-01-07T02:32:01.497' AS DateTime), N'/events/9', CAST(N'2026-01-07T02:30:50.227' AS DateTime), NULL, NULL, NULL, NULL)
INSERT [dbo].[Notifications] ([NotificationID], [UserID], [EventID], [Title], [Content], [NotificationTypeID], [Priority], [IsRead], [ReadDate], [ActionUrl], [CreatedDate], [ExpiryDate], [DedupKey], [Audience], [TargetRole]) VALUES (2, 4, 10, N'Điểm danh thành công', N'Bạn đã điểm danh sự kiện "Ngày hội Sinh viên Sáng tạo 2026" thành công. Bạn được cộng 10 điểm rèn luyện.', 2, 0, 1, CAST(N'2026-01-09T02:00:51.933' AS DateTime), N'/events/10', CAST(N'2026-01-09T02:00:14.783' AS DateTime), NULL, NULL, NULL, NULL)
INSERT [dbo].[Notifications] ([NotificationID], [UserID], [EventID], [Title], [Content], [NotificationTypeID], [Priority], [IsRead], [ReadDate], [ActionUrl], [CreatedDate], [ExpiryDate], [DedupKey], [Audience], [TargetRole]) VALUES (1002, 4, 1016, N'Đăng ký sự kiện thành công', N'Bạn đã đăng ký tham gia sự kiện "test 1" thành công. Vui lòng theo dõi thông tin và điểm danh đúng giờ.', 1, 0, 1, CAST(N'2026-02-21T19:18:20.383' AS DateTime), N'/events/1016', CAST(N'2026-02-02T02:16:19.190' AS DateTime), NULL, NULL, NULL, NULL)
INSERT [dbo].[Notifications] ([NotificationID], [UserID], [EventID], [Title], [Content], [NotificationTypeID], [Priority], [IsRead], [ReadDate], [ActionUrl], [CreatedDate], [ExpiryDate], [DedupKey], [Audience], [TargetRole]) VALUES (1003, 4, 1016, N'Thông báo cập nhật sự kiện', N'Sự kiện "test 1" đã có thay đổi: Thời gian sự kiện đã được thay đổi. Trạng thái sự kiện đã thay đổi sang Đang diễn ra', 3, 1, 1, CAST(N'2026-02-21T19:18:20.383' AS DateTime), N'/events/1016', CAST(N'2026-02-02T02:18:42.820' AS DateTime), NULL, NULL, NULL, NULL)
INSERT [dbo].[Notifications] ([NotificationID], [UserID], [EventID], [Title], [Content], [NotificationTypeID], [Priority], [IsRead], [ReadDate], [ActionUrl], [CreatedDate], [ExpiryDate], [DedupKey], [Audience], [TargetRole]) VALUES (1004, 4, 1016, N'Điểm danh thành công', N'Bạn đã điểm danh sự kiện "test 1" thành công.', 2, 0, 1, CAST(N'2026-02-21T19:18:20.383' AS DateTime), N'/events/1016', CAST(N'2026-02-02T02:23:42.453' AS DateTime), NULL, NULL, NULL, NULL)
INSERT [dbo].[Notifications] ([NotificationID], [UserID], [EventID], [Title], [Content], [NotificationTypeID], [Priority], [IsRead], [ReadDate], [ActionUrl], [CreatedDate], [ExpiryDate], [DedupKey], [Audience], [TargetRole]) VALUES (1005, 4, 1018, N'Đăng ký sự kiện thành công', N'Bạn đã đăng ký tham gia sự kiện "test 2" thành công. Vui lòng theo dõi thông tin và điểm danh đúng giờ.', 1, 0, 1, CAST(N'2026-02-21T19:18:20.383' AS DateTime), N'/events/1018', CAST(N'2026-02-02T02:25:48.217' AS DateTime), NULL, NULL, NULL, NULL)
INSERT [dbo].[Notifications] ([NotificationID], [UserID], [EventID], [Title], [Content], [NotificationTypeID], [Priority], [IsRead], [ReadDate], [ActionUrl], [CreatedDate], [ExpiryDate], [DedupKey], [Audience], [TargetRole]) VALUES (1006, 4, 1018, N'Điểm danh không hợp lệ', N'Điểm danh sự kiện "test 2" không hợp lệ. Lý do: Vị trí quá xa (8895594m). Phạm vi cho phép: 100m', 2, 1, 1, CAST(N'2026-02-21T19:18:20.383' AS DateTime), N'/events/1018', CAST(N'2026-02-02T02:31:02.643' AS DateTime), NULL, NULL, NULL, NULL)
INSERT [dbo].[Notifications] ([NotificationID], [UserID], [EventID], [Title], [Content], [NotificationTypeID], [Priority], [IsRead], [ReadDate], [ActionUrl], [CreatedDate], [ExpiryDate], [DedupKey], [Audience], [TargetRole]) VALUES (1007, 4, 1028, N'Đăng ký sự kiện thành công', N'Bạn đã đăng ký tham gia sự kiện "aaaa" thành công. Vui lòng theo dõi thông tin và điểm danh đúng giờ.', 1, 0, 1, CAST(N'2026-02-21T19:18:20.383' AS DateTime), N'/events/1028', CAST(N'2026-02-19T14:59:42.543' AS DateTime), NULL, NULL, NULL, NULL)
INSERT [dbo].[Notifications] ([NotificationID], [UserID], [EventID], [Title], [Content], [NotificationTypeID], [Priority], [IsRead], [ReadDate], [ActionUrl], [CreatedDate], [ExpiryDate], [DedupKey], [Audience], [TargetRole]) VALUES (1008, 4, 1029, N'Đăng ký sự kiện thành công', N'Bạn đã đăng ký tham gia sự kiện "string" thành công. Vui lòng theo dõi thông tin và điểm danh đúng giờ.', 1, 0, 1, CAST(N'2026-02-21T19:18:20.383' AS DateTime), N'/events/1029', CAST(N'2026-02-19T18:35:52.850' AS DateTime), NULL, NULL, NULL, NULL)
INSERT [dbo].[Notifications] ([NotificationID], [UserID], [EventID], [Title], [Content], [NotificationTypeID], [Priority], [IsRead], [ReadDate], [ActionUrl], [CreatedDate], [ExpiryDate], [DedupKey], [Audience], [TargetRole]) VALUES (1009, 4, 1029, N'Hủy đăng ký sự kiện', N'Bạn đã hủy đăng ký tham gia sự kiện "string".', 1, 0, 1, CAST(N'2026-02-21T19:18:20.383' AS DateTime), N'/events/1029', CAST(N'2026-02-20T09:43:47.837' AS DateTime), NULL, NULL, NULL, NULL)
INSERT [dbo].[Notifications] ([NotificationID], [UserID], [EventID], [Title], [Content], [NotificationTypeID], [Priority], [IsRead], [ReadDate], [ActionUrl], [CreatedDate], [ExpiryDate], [DedupKey], [Audience], [TargetRole]) VALUES (1010, 4, 1030, N'Đăng ký sự kiện thành công', N'Bạn đã đăng ký tham gia sự kiện "t1" thành công. Vui lòng theo dõi thông tin và điểm danh đúng giờ.', 1, 0, 1, CAST(N'2026-02-21T19:18:20.383' AS DateTime), N'/events/1030', CAST(N'2026-02-20T10:14:36.297' AS DateTime), NULL, NULL, NULL, NULL)
INSERT [dbo].[Notifications] ([NotificationID], [UserID], [EventID], [Title], [Content], [NotificationTypeID], [Priority], [IsRead], [ReadDate], [ActionUrl], [CreatedDate], [ExpiryDate], [DedupKey], [Audience], [TargetRole]) VALUES (1011, 4, 1030, N'Hủy đăng ký sự kiện', N'Bạn đã hủy đăng ký tham gia sự kiện "t1". Lý do: không có', 1, 0, 1, CAST(N'2026-02-21T19:18:20.383' AS DateTime), N'/events/1030', CAST(N'2026-02-20T10:15:25.153' AS DateTime), NULL, NULL, NULL, NULL)
INSERT [dbo].[Notifications] ([NotificationID], [UserID], [EventID], [Title], [Content], [NotificationTypeID], [Priority], [IsRead], [ReadDate], [ActionUrl], [CreatedDate], [ExpiryDate], [DedupKey], [Audience], [TargetRole]) VALUES (1012, 4, 1031, N'Đăng ký sự kiện thành công', N'Bạn đã đăng ký tham gia sự kiện "t2" thành công. Vui lòng theo dõi thông tin và điểm danh đúng giờ.', 1, 0, 1, CAST(N'2026-02-21T19:18:20.383' AS DateTime), N'/events/1031', CAST(N'2026-02-20T10:15:54.540' AS DateTime), NULL, NULL, NULL, NULL)
INSERT [dbo].[Notifications] ([NotificationID], [UserID], [EventID], [Title], [Content], [NotificationTypeID], [Priority], [IsRead], [ReadDate], [ActionUrl], [CreatedDate], [ExpiryDate], [DedupKey], [Audience], [TargetRole]) VALUES (1013, 4, 1031, N'Hủy đăng ký sự kiện', N'Bạn đã hủy đăng ký tham gia sự kiện "t2".', 1, 0, 1, CAST(N'2026-02-21T19:18:20.383' AS DateTime), N'/events/1031', CAST(N'2026-02-20T10:19:34.807' AS DateTime), NULL, NULL, NULL, NULL)
INSERT [dbo].[Notifications] ([NotificationID], [UserID], [EventID], [Title], [Content], [NotificationTypeID], [Priority], [IsRead], [ReadDate], [ActionUrl], [CreatedDate], [ExpiryDate], [DedupKey], [Audience], [TargetRole]) VALUES (1014, 4, 1028, N'Thông báo cập nhật sự kiện', N'Sự kiện "aaaa" đã có thay đổi: Thời gian sự kiện đã được thay đổi', 3, 1, 1, CAST(N'2026-02-21T19:18:20.383' AS DateTime), N'/events/1028', CAST(N'2026-02-20T14:34:19.540' AS DateTime), NULL, NULL, NULL, NULL)
INSERT [dbo].[Notifications] ([NotificationID], [UserID], [EventID], [Title], [Content], [NotificationTypeID], [Priority], [IsRead], [ReadDate], [ActionUrl], [CreatedDate], [ExpiryDate], [DedupKey], [Audience], [TargetRole]) VALUES (1015, 4, 1028, N'Thông báo cập nhật sự kiện', N'Sự kiện "aaaa" đã có thay đổi: Thời gian sự kiện đã được thay đổi', 3, 1, 1, CAST(N'2026-02-21T19:18:20.383' AS DateTime), N'/events/1028', CAST(N'2026-02-20T14:34:43.813' AS DateTime), NULL, NULL, NULL, NULL)
INSERT [dbo].[Notifications] ([NotificationID], [UserID], [EventID], [Title], [Content], [NotificationTypeID], [Priority], [IsRead], [ReadDate], [ActionUrl], [CreatedDate], [ExpiryDate], [DedupKey], [Audience], [TargetRole]) VALUES (1016, 4, 1028, N'Điểm danh thành công', N'Bạn đã điểm danh sự kiện "aaaa" thành công.', 2, 0, 1, CAST(N'2026-02-21T19:18:20.383' AS DateTime), N'/events/1028', CAST(N'2026-02-20T14:38:29.260' AS DateTime), NULL, NULL, NULL, NULL)
INSERT [dbo].[Notifications] ([NotificationID], [UserID], [EventID], [Title], [Content], [NotificationTypeID], [Priority], [IsRead], [ReadDate], [ActionUrl], [CreatedDate], [ExpiryDate], [DedupKey], [Audience], [TargetRole]) VALUES (1017, 4, 1033, N'Đăng ký sự kiện thành công', N'Bạn đã đăng ký tham gia sự kiện "a1" thành công. Vui lòng theo dõi thông tin và điểm danh đúng giờ.', 1, 0, 1, CAST(N'2026-02-21T19:18:20.383' AS DateTime), N'/events/1033', CAST(N'2026-02-21T09:18:19.577' AS DateTime), NULL, NULL, NULL, NULL)
INSERT [dbo].[Notifications] ([NotificationID], [UserID], [EventID], [Title], [Content], [NotificationTypeID], [Priority], [IsRead], [ReadDate], [ActionUrl], [CreatedDate], [ExpiryDate], [DedupKey], [Audience], [TargetRole]) VALUES (1018, 4, 1034, N'Đăng ký sự kiện thành công', N'Bạn đã đăng ký tham gia sự kiện "a2" thành công. Vui lòng theo dõi thông tin và điểm danh đúng giờ.', 1, 0, 1, CAST(N'2026-02-21T19:18:20.383' AS DateTime), N'/events/1034', CAST(N'2026-02-21T09:19:55.117' AS DateTime), NULL, NULL, NULL, NULL)
INSERT [dbo].[Notifications] ([NotificationID], [UserID], [EventID], [Title], [Content], [NotificationTypeID], [Priority], [IsRead], [ReadDate], [ActionUrl], [CreatedDate], [ExpiryDate], [DedupKey], [Audience], [TargetRole]) VALUES (1019, 4, 1033, N'Thông báo cập nhật sự kiện', N'Sự kiện "a1" đã có thay đổi: Địa điểm tổ chức đã được cập nhật', 3, 1, 1, CAST(N'2026-02-21T19:18:20.383' AS DateTime), N'/events/1033', CAST(N'2026-02-21T09:22:03.573' AS DateTime), NULL, NULL, NULL, NULL)
INSERT [dbo].[Notifications] ([NotificationID], [UserID], [EventID], [Title], [Content], [NotificationTypeID], [Priority], [IsRead], [ReadDate], [ActionUrl], [CreatedDate], [ExpiryDate], [DedupKey], [Audience], [TargetRole]) VALUES (1020, 4, 1034, N'Thông báo cập nhật sự kiện', N'Sự kiện "a2" đã có thay đổi: Địa điểm tổ chức đã được cập nhật', 3, 1, 1, CAST(N'2026-02-21T19:18:20.383' AS DateTime), N'/events/1034', CAST(N'2026-02-21T09:22:26.023' AS DateTime), NULL, NULL, NULL, NULL)
INSERT [dbo].[Notifications] ([NotificationID], [UserID], [EventID], [Title], [Content], [NotificationTypeID], [Priority], [IsRead], [ReadDate], [ActionUrl], [CreatedDate], [ExpiryDate], [DedupKey], [Audience], [TargetRole]) VALUES (1021, 4, 1034, N'Hủy đăng ký sự kiện', N'Bạn đã hủy đăng ký tham gia sự kiện "a2". Lý do: không', 1, 0, 1, CAST(N'2026-02-21T19:18:17.683' AS DateTime), N'/events/1034', CAST(N'2026-02-21T09:27:45.127' AS DateTime), NULL, NULL, NULL, NULL)
INSERT [dbo].[Notifications] ([NotificationID], [UserID], [EventID], [Title], [Content], [NotificationTypeID], [Priority], [IsRead], [ReadDate], [ActionUrl], [CreatedDate], [ExpiryDate], [DedupKey], [Audience], [TargetRole]) VALUES (1022, 4, 1033, N'Hủy đăng ký sự kiện', N'Bạn đã hủy đăng ký tham gia sự kiện "a1".', 1, 0, 1, CAST(N'2026-02-23T09:21:53.227' AS DateTime), N'/events/1033', CAST(N'2026-02-22T09:08:44.993' AS DateTime), NULL, NULL, NULL, NULL)
INSERT [dbo].[Notifications] ([NotificationID], [UserID], [EventID], [Title], [Content], [NotificationTypeID], [Priority], [IsRead], [ReadDate], [ActionUrl], [CreatedDate], [ExpiryDate], [DedupKey], [Audience], [TargetRole]) VALUES (1023, 4, 1036, N'Đăng ký sự kiện thành công', N'Bạn đã đăng ký tham gia sự kiện "q" thành công. Vui lòng theo dõi thông tin và điểm danh đúng giờ.', 1, 0, 1, CAST(N'2026-03-01T15:33:42.510' AS DateTime), N'/events/1036', CAST(N'2026-02-25T19:31:03.027' AS DateTime), NULL, NULL, NULL, NULL)
INSERT [dbo].[Notifications] ([NotificationID], [UserID], [EventID], [Title], [Content], [NotificationTypeID], [Priority], [IsRead], [ReadDate], [ActionUrl], [CreatedDate], [ExpiryDate], [DedupKey], [Audience], [TargetRole]) VALUES (1024, 4, 1036, N'Hủy đăng ký sự kiện', N'Bạn đã hủy đăng ký tham gia sự kiện "q". Lý do: không thích', 1, 0, 1, CAST(N'2026-02-25T19:34:05.677' AS DateTime), N'/events/1036', CAST(N'2026-02-25T19:31:32.840' AS DateTime), NULL, NULL, NULL, NULL)
INSERT [dbo].[Notifications] ([NotificationID], [UserID], [EventID], [Title], [Content], [NotificationTypeID], [Priority], [IsRead], [ReadDate], [ActionUrl], [CreatedDate], [ExpiryDate], [DedupKey], [Audience], [TargetRole]) VALUES (1025, 4, 1037, N'Đăng ký sự kiện thành công', N'Bạn đã đăng ký tham gia sự kiện "qq1" thành công. Vui lòng theo dõi thông tin và điểm danh đúng giờ.', 1, 0, 1, CAST(N'2026-02-27T09:25:05.013' AS DateTime), N'/events/1037', CAST(N'2026-02-25T19:36:16.530' AS DateTime), NULL, NULL, NULL, NULL)
INSERT [dbo].[Notifications] ([NotificationID], [UserID], [EventID], [Title], [Content], [NotificationTypeID], [Priority], [IsRead], [ReadDate], [ActionUrl], [CreatedDate], [ExpiryDate], [DedupKey], [Audience], [TargetRole]) VALUES (1026, 4, 1037, N'Hủy đăng ký sự kiện', N'Bạn đã hủy đăng ký tham gia sự kiện "qq1".', 1, 0, 1, CAST(N'2026-03-01T15:33:37.037' AS DateTime), N'/events/1037', CAST(N'2026-02-27T09:25:23.210' AS DateTime), CAST(N'2026-05-28T09:25:23.210' AS DateTime), N'event-registration-cancel:216889C1DE3068E3730FF7D51AC7FF54B1601841E1BDECE69008AF7F7043FE5C', N'MobileMember', NULL)
INSERT [dbo].[Notifications] ([NotificationID], [UserID], [EventID], [Title], [Content], [NotificationTypeID], [Priority], [IsRead], [ReadDate], [ActionUrl], [CreatedDate], [ExpiryDate], [DedupKey], [Audience], [TargetRole]) VALUES (1027, 2, 1038, N'Thao tác sự kiện thành công', N'Bạn đã tạo mới sự kiện "444" thành công.', 7, 0, 1, CAST(N'2026-02-28T09:13:18.130' AS DateTime), N'/events/1038', CAST(N'2026-02-28T09:02:29.233' AS DateTime), CAST(N'2026-03-30T09:02:29.233' AS DateTime), N'actor-event-action:168A12043929EC4D1F7D56185161FA6DB54119B57BC3787AE47142A62B6B2211', N'Admin', N'Admin')
INSERT [dbo].[Notifications] ([NotificationID], [UserID], [EventID], [Title], [Content], [NotificationTypeID], [Priority], [IsRead], [ReadDate], [ActionUrl], [CreatedDate], [ExpiryDate], [DedupKey], [Audience], [TargetRole]) VALUES (1028, 2, 1038, N'Thao tác sự kiện thành công', N'Bạn đã cập nhật sự kiện "444" thành công. Chi tiết: Cập nhật thông tin sự kiện', 7, 0, 1, CAST(N'2026-02-28T09:13:14.540' AS DateTime), N'/events/1038', CAST(N'2026-02-28T09:04:37.423' AS DateTime), CAST(N'2026-03-30T09:04:37.423' AS DateTime), N'actor-event-action:C04B2FF5CCB541369B7A4BB8783A460AD38931AAAC5B39B6728C5A86374D8C12', N'Admin', N'Admin')
INSERT [dbo].[Notifications] ([NotificationID], [UserID], [EventID], [Title], [Content], [NotificationTypeID], [Priority], [IsRead], [ReadDate], [ActionUrl], [CreatedDate], [ExpiryDate], [DedupKey], [Audience], [TargetRole]) VALUES (1029, 2, 1038, N'Thao tác sự kiện thành công', N'Bạn đã cập nhật sự kiện "444" thành công. Chi tiết: Cập nhật thông tin sự kiện', 7, 0, 1, CAST(N'2026-02-28T09:24:20.750' AS DateTime), N'/events/1038', CAST(N'2026-02-28T09:19:22.867' AS DateTime), CAST(N'2026-03-30T09:19:22.867' AS DateTime), N'actor-event-action:E4062B516F38A644298523A584F518FA1E4E66E0BF380743E200E249BD52B32B', N'Admin', N'Admin')
INSERT [dbo].[Notifications] ([NotificationID], [UserID], [EventID], [Title], [Content], [NotificationTypeID], [Priority], [IsRead], [ReadDate], [ActionUrl], [CreatedDate], [ExpiryDate], [DedupKey], [Audience], [TargetRole]) VALUES (1030, 2, 1037, N'Thao tác sự kiện thành công', N'Bạn đã cập nhật sự kiện "qq1" thành công. Chi tiết: Cập nhật thông tin sự kiện', 7, 0, 1, CAST(N'2026-02-28T09:24:20.750' AS DateTime), N'/events/1037', CAST(N'2026-02-28T09:24:12.283' AS DateTime), CAST(N'2026-03-30T09:24:12.283' AS DateTime), N'actor-event-action:EF4CAF8E5E50B124FD37B9076E7A458A6C7D3F806F7F3F337171FCCE80D0E4C3', N'Admin', N'Admin')
INSERT [dbo].[Notifications] ([NotificationID], [UserID], [EventID], [Title], [Content], [NotificationTypeID], [Priority], [IsRead], [ReadDate], [ActionUrl], [CreatedDate], [ExpiryDate], [DedupKey], [Audience], [TargetRole]) VALUES (2027, 2, 1038, N'Thao tác sự kiện thành công', N'Bạn đã cập nhật sự kiện "444" thành công. Chi tiết: Cập nhật thông tin sự kiện', 7, 0, 1, CAST(N'2026-02-28T14:38:21.853' AS DateTime), N'/events/1038', CAST(N'2026-02-28T14:38:07.510' AS DateTime), CAST(N'2026-03-30T14:38:07.510' AS DateTime), N'actor-event-action:25FD681D2AC36C318C7A3EADDFD67D2A5EDEFD74AE7D73F12342321DF263779E', N'Admin', N'Admin')
INSERT [dbo].[Notifications] ([NotificationID], [UserID], [EventID], [Title], [Content], [NotificationTypeID], [Priority], [IsRead], [ReadDate], [ActionUrl], [CreatedDate], [ExpiryDate], [DedupKey], [Audience], [TargetRole]) VALUES (2028, 2, 1037, N'Thao tác sự kiện thành công', N'Bạn đã cập nhật sự kiện "qq1" thành công. Chi tiết: Cập nhật thông tin sự kiện', 7, 0, 1, CAST(N'2026-02-28T14:42:19.743' AS DateTime), N'/events/1037', CAST(N'2026-02-28T14:41:53.240' AS DateTime), CAST(N'2026-03-30T14:41:53.240' AS DateTime), N'actor-event-action:ECCDEE9D3E8CC05F50FAD54F018493BB2CAD1303AF8975B7D1D30020914E1D2C', N'Admin', N'Admin')
INSERT [dbo].[Notifications] ([NotificationID], [UserID], [EventID], [Title], [Content], [NotificationTypeID], [Priority], [IsRead], [ReadDate], [ActionUrl], [CreatedDate], [ExpiryDate], [DedupKey], [Audience], [TargetRole]) VALUES (2029, 3, 2038, N'Thao tác sự kiện thành công', N'Bạn đã tạo mới sự kiện "cb" thành công.', 7, 0, 0, NULL, N'/events/2038', CAST(N'2026-02-28T14:47:04.673' AS DateTime), CAST(N'2026-03-30T14:47:04.673' AS DateTime), N'actor-event-action:F5066098D627BA2F0997F5DBE7793625A98C3DB0747260CF41B4010901494246', N'WebOfficer', N'CanBo')
INSERT [dbo].[Notifications] ([NotificationID], [UserID], [EventID], [Title], [Content], [NotificationTypeID], [Priority], [IsRead], [ReadDate], [ActionUrl], [CreatedDate], [ExpiryDate], [DedupKey], [Audience], [TargetRole]) VALUES (2030, 4, 2038, N'Đăng ký sự kiện thành công', N'Bạn đã đăng ký tham gia sự kiện "cb" thành công. Vui lòng theo dõi thông tin và điểm danh đúng giờ.', 1, 0, 1, CAST(N'2026-03-02T14:36:03.413' AS DateTime), N'/events/2038', CAST(N'2026-03-01T15:34:01.530' AS DateTime), CAST(N'2026-05-30T15:34:01.530' AS DateTime), N'event-registration-success:BDD8E91E629668B1449A45A0C443BD9FFBD0F9DBF005447BF12646A9AB58FF2B', N'MobileMember', NULL)
SET IDENTITY_INSERT [dbo].[Notifications] OFF
GO
SET IDENTITY_INSERT [dbo].[NotificationType] ON 

INSERT [dbo].[NotificationType] ([TypeID], [TypeName], [Template], [CreatedDate], [Locale], [TemplateVersion]) VALUES (1, N'EventRegistration', N'Bạn đã đăng ký tham gia sự kiện "{EventName}" thành công.', CAST(N'2026-01-07T09:01:39.150' AS DateTime), N'vi-VN', 1)
INSERT [dbo].[NotificationType] ([TypeID], [TypeName], [Template], [CreatedDate], [Locale], [TemplateVersion]) VALUES (2, N'Attendance', N'Điểm danh sự kiện "{EventName}": {Status}. Điểm rèn luyện: {Points}.', CAST(N'2026-01-07T09:01:39.157' AS DateTime), N'vi-VN', 1)
INSERT [dbo].[NotificationType] ([TypeID], [TypeName], [Template], [CreatedDate], [Locale], [TemplateVersion]) VALUES (3, N'EventUpdate', N'Sự kiện "{EventName}" đã có thay đổi: {UpdateMessage}', CAST(N'2026-01-07T09:01:39.160' AS DateTime), N'vi-VN', 1)
INSERT [dbo].[NotificationType] ([TypeID], [TypeName], [Template], [CreatedDate], [Locale], [TemplateVersion]) VALUES (4, N'EventCancellation', N'Sự kiện "{EventName}" đã bị hủy. Lý do: {Reason}', CAST(N'2026-01-07T09:01:39.160' AS DateTime), N'vi-VN', 1)
INSERT [dbo].[NotificationType] ([TypeID], [TypeName], [Template], [CreatedDate], [Locale], [TemplateVersion]) VALUES (5, N'EventReminder', N'Nhắc nhở: Sự kiện "{EventName}" sẽ diễn ra vào {StartTime}.', CAST(N'2026-01-07T09:01:39.160' AS DateTime), N'vi-VN', 1)
INSERT [dbo].[NotificationType] ([TypeID], [TypeName], [Template], [CreatedDate], [Locale], [TemplateVersion]) VALUES (6, N'ManualPoints', N'Bạn được {Action} {Points} điểm rèn luyện. Lý do: {Reason}', CAST(N'2026-01-07T09:01:39.160' AS DateTime), N'vi-VN', 1)
INSERT [dbo].[NotificationType] ([TypeID], [TypeName], [Template], [CreatedDate], [Locale], [TemplateVersion]) VALUES (7, N'System', N'{Message}', CAST(N'2026-01-07T09:01:39.160' AS DateTime), N'vi-VN', 1)
SET IDENTITY_INSERT [dbo].[NotificationType] OFF
GO
SET IDENTITY_INSERT [dbo].[PasswordResetOtps] ON 

INSERT [dbo].[PasswordResetOtps] ([OtpID], [UserID], [OtpHash], [Purpose], [ExpiresAt], [AttemptCount], [MaxAttempts], [ResendCount], [MaxResends], [IsUsed], [VerifiedAt], [UsedAt], [RevokedAt], [CreatedDate], [LastSentAt], [RequestIp], [RequestUserAgent]) VALUES (1, 1002, N'sDYTgzn6OtPPUd4GsY97gHgrvEVM87hKEeOa7ufoYdY', N'PasswordReset', CAST(N'2026-03-07T19:56:10.057' AS DateTime), 0, 5, 0, 3, 0, NULL, NULL, NULL, CAST(N'2026-03-07T19:51:10.057' AS DateTime), CAST(N'2026-03-07T19:51:10.057' AS DateTime), NULL, NULL)
INSERT [dbo].[PasswordResetOtps] ([OtpID], [UserID], [OtpHash], [Purpose], [ExpiresAt], [AttemptCount], [MaxAttempts], [ResendCount], [MaxResends], [IsUsed], [VerifiedAt], [UsedAt], [RevokedAt], [CreatedDate], [LastSentAt], [RequestIp], [RequestUserAgent]) VALUES (2, 2, N'OMCD2WMoEWMnwPNCT9_7RCgAj0msQLME8GosYIWzrFM', N'PasswordReset', CAST(N'2026-03-07T20:04:09.230' AS DateTime), 0, 5, 0, 3, 1, NULL, NULL, CAST(N'2026-03-07T20:00:56.263' AS DateTime), CAST(N'2026-03-07T19:59:09.230' AS DateTime), CAST(N'2026-03-07T19:59:09.230' AS DateTime), NULL, NULL)
INSERT [dbo].[PasswordResetOtps] ([OtpID], [UserID], [OtpHash], [Purpose], [ExpiresAt], [AttemptCount], [MaxAttempts], [ResendCount], [MaxResends], [IsUsed], [VerifiedAt], [UsedAt], [RevokedAt], [CreatedDate], [LastSentAt], [RequestIp], [RequestUserAgent]) VALUES (3, 2, N'bgsG58PaW6j1bmhf_hh16we78SpX0jY2w6WRXcufC_s', N'PasswordReset', CAST(N'2026-03-07T20:05:56.263' AS DateTime), 0, 5, 0, 3, 1, CAST(N'2026-03-07T20:02:15.293' AS DateTime), NULL, CAST(N'2026-03-07T20:08:05.907' AS DateTime), CAST(N'2026-03-07T20:00:56.263' AS DateTime), CAST(N'2026-03-07T20:00:56.263' AS DateTime), NULL, NULL)
INSERT [dbo].[PasswordResetOtps] ([OtpID], [UserID], [OtpHash], [Purpose], [ExpiresAt], [AttemptCount], [MaxAttempts], [ResendCount], [MaxResends], [IsUsed], [VerifiedAt], [UsedAt], [RevokedAt], [CreatedDate], [LastSentAt], [RequestIp], [RequestUserAgent]) VALUES (4, 2, N'Ka2whjl7lHmEj76LOlPDEGnPEYOb4QkHzl3Aysxi38k', N'PasswordReset', CAST(N'2026-03-07T20:12:31.810' AS DateTime), 0, 5, 0, 3, 1, CAST(N'2026-03-07T20:07:54.717' AS DateTime), CAST(N'2026-03-07T20:08:05.907' AS DateTime), NULL, CAST(N'2026-03-07T20:07:31.810' AS DateTime), CAST(N'2026-03-07T20:07:31.810' AS DateTime), NULL, NULL)
INSERT [dbo].[PasswordResetOtps] ([OtpID], [UserID], [OtpHash], [Purpose], [ExpiresAt], [AttemptCount], [MaxAttempts], [ResendCount], [MaxResends], [IsUsed], [VerifiedAt], [UsedAt], [RevokedAt], [CreatedDate], [LastSentAt], [RequestIp], [RequestUserAgent]) VALUES (5, 2, N'1XB2by1p5njTTO_-6yLfRwCF62VB4f34QuGvguFZf74', N'PasswordReset', CAST(N'2026-03-08T15:49:28.267' AS DateTime), 0, 5, 0, 3, 1, CAST(N'2026-03-08T15:44:47.363' AS DateTime), CAST(N'2026-03-08T15:45:19.233' AS DateTime), NULL, CAST(N'2026-03-08T15:44:28.267' AS DateTime), CAST(N'2026-03-08T15:44:28.267' AS DateTime), NULL, NULL)
INSERT [dbo].[PasswordResetOtps] ([OtpID], [UserID], [OtpHash], [Purpose], [ExpiresAt], [AttemptCount], [MaxAttempts], [ResendCount], [MaxResends], [IsUsed], [VerifiedAt], [UsedAt], [RevokedAt], [CreatedDate], [LastSentAt], [RequestIp], [RequestUserAgent]) VALUES (6, 4, N'7RroLGGrLh_8oz4N38-ujlcmHPSA0jobl4mWPRXSkE0', N'PasswordReset', CAST(N'2026-03-09T15:37:03.943' AS DateTime), 0, 5, 0, 3, 1, CAST(N'2026-03-09T15:32:34.303' AS DateTime), CAST(N'2026-03-09T15:33:11.240' AS DateTime), NULL, CAST(N'2026-03-09T15:32:03.943' AS DateTime), CAST(N'2026-03-09T15:32:03.943' AS DateTime), NULL, NULL)
INSERT [dbo].[PasswordResetOtps] ([OtpID], [UserID], [OtpHash], [Purpose], [ExpiresAt], [AttemptCount], [MaxAttempts], [ResendCount], [MaxResends], [IsUsed], [VerifiedAt], [UsedAt], [RevokedAt], [CreatedDate], [LastSentAt], [RequestIp], [RequestUserAgent]) VALUES (7, 4, N'FK9F9jqCN1MDFDxqOAmnmDnk5v1YXTHLYNs5WZk6V9w', N'PasswordReset', CAST(N'2026-03-09T15:52:19.267' AS DateTime), 0, 5, 0, 3, 1, CAST(N'2026-03-09T15:47:54.063' AS DateTime), CAST(N'2026-03-09T15:48:36.023' AS DateTime), NULL, CAST(N'2026-03-09T15:47:19.267' AS DateTime), CAST(N'2026-03-09T15:47:19.267' AS DateTime), NULL, NULL)
SET IDENTITY_INSERT [dbo].[PasswordResetOtps] OFF
GO
SET IDENTITY_INSERT [dbo].[PasswordResetSessions] ON 

INSERT [dbo].[PasswordResetSessions] ([ResetSessionID], [UserID], [OtpID], [SessionTokenHash], [ExpiresAt], [IsUsed], [CreatedDate], [UsedAt]) VALUES (1, 2, 3, N'ZIKZnkuAV0oLhW2fgC7Cs3yfpoB_FQ_SLaigLpdFg-Y', CAST(N'2026-03-07T20:07:15.330' AS DateTime), 1, CAST(N'2026-03-07T20:02:15.330' AS DateTime), CAST(N'2026-03-07T20:08:05.907' AS DateTime))
INSERT [dbo].[PasswordResetSessions] ([ResetSessionID], [UserID], [OtpID], [SessionTokenHash], [ExpiresAt], [IsUsed], [CreatedDate], [UsedAt]) VALUES (2, 2, 4, N'ulu42zAp8EsKbbu75alBuP5ZqLYn3v_1tyYwt7Zwbeg', CAST(N'2026-03-07T20:12:54.747' AS DateTime), 1, CAST(N'2026-03-07T20:07:54.747' AS DateTime), CAST(N'2026-03-07T20:08:05.907' AS DateTime))
INSERT [dbo].[PasswordResetSessions] ([ResetSessionID], [UserID], [OtpID], [SessionTokenHash], [ExpiresAt], [IsUsed], [CreatedDate], [UsedAt]) VALUES (3, 2, 5, N'a6R-TUq0U3H5GYH1uVtWOr-qZ3F_WB__0dXNb8N-5Gg', CAST(N'2026-03-08T15:49:47.390' AS DateTime), 1, CAST(N'2026-03-08T15:44:47.390' AS DateTime), CAST(N'2026-03-08T15:45:19.233' AS DateTime))
INSERT [dbo].[PasswordResetSessions] ([ResetSessionID], [UserID], [OtpID], [SessionTokenHash], [ExpiresAt], [IsUsed], [CreatedDate], [UsedAt]) VALUES (4, 4, 6, N'KKiORm0gcHmdFCVHGzuAJZj5n0jiKrVel3KPeh83YBk', CAST(N'2026-03-09T15:37:34.333' AS DateTime), 1, CAST(N'2026-03-09T15:32:34.333' AS DateTime), CAST(N'2026-03-09T15:33:11.240' AS DateTime))
INSERT [dbo].[PasswordResetSessions] ([ResetSessionID], [UserID], [OtpID], [SessionTokenHash], [ExpiresAt], [IsUsed], [CreatedDate], [UsedAt]) VALUES (5, 4, 7, N'LE-ibcpasVTkVVXRIKpjkFzsTLtOD80wiu2sfFNyXIk', CAST(N'2026-03-09T15:52:54.083' AS DateTime), 1, CAST(N'2026-03-09T15:47:54.083' AS DateTime), CAST(N'2026-03-09T15:48:36.023' AS DateTime))
SET IDENTITY_INSERT [dbo].[PasswordResetSessions] OFF
GO
SET IDENTITY_INSERT [dbo].[PasswordResetTokens] ON 

INSERT [dbo].[PasswordResetTokens] ([Id], [UserID], [Token], [ExpiredAt], [IsUsed], [CreatedDate]) VALUES (1, 2, N'n24HRLxxLnTN_axN0EtEDXKJYFBhw2Hq2FK2MW-h_Lw', CAST(N'2026-02-07T15:04:19.357' AS DateTime), 1, CAST(N'2026-02-07T14:49:19.357' AS DateTime))
INSERT [dbo].[PasswordResetTokens] ([Id], [UserID], [Token], [ExpiredAt], [IsUsed], [CreatedDate]) VALUES (2, 2, N'7bjXPtVvWrG1nA7H7-A9BY4YCQu77WTW8eZI1IViaLk', CAST(N'2026-02-07T15:09:55.740' AS DateTime), 0, CAST(N'2026-02-07T14:54:55.740' AS DateTime))
INSERT [dbo].[PasswordResetTokens] ([Id], [UserID], [Token], [ExpiredAt], [IsUsed], [CreatedDate]) VALUES (3, 2, N'ccA-QTP_813t7rxOzQWmbH1NtXu6fPCEKVqu06mzPY4', CAST(N'2026-02-08T09:52:48.540' AS DateTime), 1, CAST(N'2026-02-08T09:37:48.540' AS DateTime))
INSERT [dbo].[PasswordResetTokens] ([Id], [UserID], [Token], [ExpiredAt], [IsUsed], [CreatedDate]) VALUES (4, 2, N'hI_S-4WHP-SP-j1cr99irVW8ZAD_WOVWB-qYqGyNOpM', CAST(N'2026-02-08T10:04:38.770' AS DateTime), 1, CAST(N'2026-02-08T09:49:38.770' AS DateTime))
INSERT [dbo].[PasswordResetTokens] ([Id], [UserID], [Token], [ExpiredAt], [IsUsed], [CreatedDate]) VALUES (5, 2, N'JbQw2Z4rulCBAgUmRcBDJkEiJfDFr1sLY9XEJUMj8EQ', CAST(N'2026-02-08T10:09:20.637' AS DateTime), 0, CAST(N'2026-02-08T09:54:20.637' AS DateTime))
INSERT [dbo].[PasswordResetTokens] ([Id], [UserID], [Token], [ExpiredAt], [IsUsed], [CreatedDate]) VALUES (6, 2, N'Lz0cRpEuRHdP0iGLm8N2x_lEpvMtYVDvMjIbkEGwQDQ', CAST(N'2026-02-08T10:43:14.287' AS DateTime), 0, CAST(N'2026-02-08T10:28:14.287' AS DateTime))
INSERT [dbo].[PasswordResetTokens] ([Id], [UserID], [Token], [ExpiredAt], [IsUsed], [CreatedDate]) VALUES (7, 1002, N'zvm0bMAf50WE1HyxtBPWqQN5qYyeAH0D7kKgT2qFQeA', CAST(N'2026-02-08T15:41:51.393' AS DateTime), 0, CAST(N'2026-02-08T15:26:51.393' AS DateTime))
SET IDENTITY_INSERT [dbo].[PasswordResetTokens] OFF
GO
SET IDENTITY_INSERT [dbo].[Roles] ON 

INSERT [dbo].[Roles] ([RoleID], [RoleName], [CreatedDate]) VALUES (5, N'Admin', CAST(N'2025-12-22T15:45:18.810' AS DateTime))
INSERT [dbo].[Roles] ([RoleID], [RoleName], [CreatedDate]) VALUES (6, N'CanBo', CAST(N'2025-12-22T15:45:18.810' AS DateTime))
INSERT [dbo].[Roles] ([RoleID], [RoleName], [CreatedDate]) VALUES (7, N'DoanVien', CAST(N'2025-12-22T15:45:18.810' AS DateTime))
INSERT [dbo].[Roles] ([RoleID], [RoleName], [CreatedDate]) VALUES (8, N'HoiVien', CAST(N'2025-12-22T15:45:18.810' AS DateTime))
SET IDENTITY_INSERT [dbo].[Roles] OFF
GO
SET IDENTITY_INSERT [dbo].[Units] ON 

INSERT [dbo].[Units] ([UnitID], [UnitName], [UnitType], [InstituteID], [ParentUnitID], [Description], [Status], [CreatedDate], [UpdatedDate]) VALUES (1, N'Chi Đoàn Viện Công Nghệ Số', N'ChiDoan', 1, NULL, N'Chi đoàn sinh viên Viện Công Nghệ Số', 1, CAST(N'2025-12-22T15:45:18.867' AS DateTime), CAST(N'2025-12-22T15:45:18.867' AS DateTime))
INSERT [dbo].[Units] ([UnitID], [UnitName], [UnitType], [InstituteID], [ParentUnitID], [Description], [Status], [CreatedDate], [UpdatedDate]) VALUES (2, N'Chi Hội Viện Công Nghệ Số', N'ChiHoi', 1, NULL, N'Chi hội sinh viên Viện Công Nghệ Số', 1, CAST(N'2025-12-22T15:45:18.873' AS DateTime), CAST(N'2025-12-22T15:45:18.873' AS DateTime))
SET IDENTITY_INSERT [dbo].[Units] OFF
GO
SET IDENTITY_INSERT [dbo].[UserDeviceTokens] ON 

INSERT [dbo].[UserDeviceTokens] ([UserDeviceTokenID], [UserID], [Platform], [Token], [DeviceId], [IsActive], [LastSeenAt], [CreatedDate], [UpdatedDate]) VALUES (1, 4, N'Fcm', N'install_1771400098710000', NULL, 1, CAST(N'2026-02-18T14:42:07.697' AS DateTime), CAST(N'2026-02-18T14:34:58.847' AS DateTime), CAST(N'2026-02-18T14:42:07.697' AS DateTime))
INSERT [dbo].[UserDeviceTokens] ([UserDeviceTokenID], [UserID], [Platform], [Token], [DeviceId], [IsActive], [LastSeenAt], [CreatedDate], [UpdatedDate]) VALUES (2, 4, N'Fcm', N'install_1771555406995000', NULL, 1, CAST(N'2026-02-20T09:43:27.087' AS DateTime), CAST(N'2026-02-20T09:43:27.087' AS DateTime), CAST(N'2026-02-20T09:43:27.087' AS DateTime))
INSERT [dbo].[UserDeviceTokens] ([UserDeviceTokenID], [UserID], [Platform], [Token], [DeviceId], [IsActive], [LastSeenAt], [CreatedDate], [UpdatedDate]) VALUES (3, 4, N'Fcm', N'install_1771557047425000', NULL, 1, CAST(N'2026-02-20T10:10:47.627' AS DateTime), CAST(N'2026-02-20T10:10:47.627' AS DateTime), CAST(N'2026-02-20T10:10:47.627' AS DateTime))
INSERT [dbo].[UserDeviceTokens] ([UserDeviceTokenID], [UserID], [Platform], [Token], [DeviceId], [IsActive], [LastSeenAt], [CreatedDate], [UpdatedDate]) VALUES (4, 4, N'Fcm', N'install_1771557550765000', NULL, 1, CAST(N'2026-02-20T10:19:10.827' AS DateTime), CAST(N'2026-02-20T10:19:10.827' AS DateTime), CAST(N'2026-02-20T10:19:10.827' AS DateTime))
INSERT [dbo].[UserDeviceTokens] ([UserDeviceTokenID], [UserID], [Platform], [Token], [DeviceId], [IsActive], [LastSeenAt], [CreatedDate], [UpdatedDate]) VALUES (5, 4, N'Fcm', N'install_1771558250742000', NULL, 1, CAST(N'2026-02-20T10:30:50.777' AS DateTime), CAST(N'2026-02-20T10:30:50.777' AS DateTime), CAST(N'2026-02-20T10:30:50.777' AS DateTime))
INSERT [dbo].[UserDeviceTokens] ([UserDeviceTokenID], [UserID], [Platform], [Token], [DeviceId], [IsActive], [LastSeenAt], [CreatedDate], [UpdatedDate]) VALUES (6, 4, N'Fcm', N'install_1771558617817000', NULL, 1, CAST(N'2026-02-20T10:38:38.143' AS DateTime), CAST(N'2026-02-20T10:36:57.867' AS DateTime), CAST(N'2026-02-20T10:38:38.143' AS DateTime))
INSERT [dbo].[UserDeviceTokens] ([UserDeviceTokenID], [UserID], [Platform], [Token], [DeviceId], [IsActive], [LastSeenAt], [CreatedDate], [UpdatedDate]) VALUES (7, 4, N'Fcm', N'install_1771639666219000', NULL, 1, CAST(N'2026-02-21T09:07:46.547' AS DateTime), CAST(N'2026-02-21T09:07:46.547' AS DateTime), CAST(N'2026-02-21T09:07:46.547' AS DateTime))
INSERT [dbo].[UserDeviceTokens] ([UserDeviceTokenID], [UserID], [Platform], [Token], [DeviceId], [IsActive], [LastSeenAt], [CreatedDate], [UpdatedDate]) VALUES (8, 4, N'Fcm', N'install_1771640767048000', NULL, 1, CAST(N'2026-02-21T09:26:07.147' AS DateTime), CAST(N'2026-02-21T09:26:07.147' AS DateTime), CAST(N'2026-02-21T09:26:07.147' AS DateTime))
INSERT [dbo].[UserDeviceTokens] ([UserDeviceTokenID], [UserID], [Platform], [Token], [DeviceId], [IsActive], [LastSeenAt], [CreatedDate], [UpdatedDate]) VALUES (9, 4, N'Fcm', N'install_1771641152467000', NULL, 1, CAST(N'2026-02-21T09:32:32.497' AS DateTime), CAST(N'2026-02-21T09:32:32.497' AS DateTime), CAST(N'2026-02-21T09:32:32.497' AS DateTime))
INSERT [dbo].[UserDeviceTokens] ([UserDeviceTokenID], [UserID], [Platform], [Token], [DeviceId], [IsActive], [LastSeenAt], [CreatedDate], [UpdatedDate]) VALUES (10, 4, N'Fcm', N'install_1771641699523000', NULL, 1, CAST(N'2026-02-21T09:41:39.577' AS DateTime), CAST(N'2026-02-21T09:41:39.577' AS DateTime), CAST(N'2026-02-21T09:41:39.577' AS DateTime))
INSERT [dbo].[UserDeviceTokens] ([UserDeviceTokenID], [UserID], [Platform], [Token], [DeviceId], [IsActive], [LastSeenAt], [CreatedDate], [UpdatedDate]) VALUES (11, 4, N'Fcm', N'install_1771643005149000', NULL, 1, CAST(N'2026-02-21T10:03:25.237' AS DateTime), CAST(N'2026-02-21T10:03:25.237' AS DateTime), CAST(N'2026-02-21T10:03:25.237' AS DateTime))
INSERT [dbo].[UserDeviceTokens] ([UserDeviceTokenID], [UserID], [Platform], [Token], [DeviceId], [IsActive], [LastSeenAt], [CreatedDate], [UpdatedDate]) VALUES (12, 4, N'Fcm', N'install_1771676215538000', NULL, 1, CAST(N'2026-02-21T19:16:55.750' AS DateTime), CAST(N'2026-02-21T19:16:55.750' AS DateTime), CAST(N'2026-02-21T19:16:55.750' AS DateTime))
INSERT [dbo].[UserDeviceTokens] ([UserDeviceTokenID], [UserID], [Platform], [Token], [DeviceId], [IsActive], [LastSeenAt], [CreatedDate], [UpdatedDate]) VALUES (13, 4, N'Fcm', N'install_1771677134283000', NULL, 1, CAST(N'2026-02-21T19:32:14.320' AS DateTime), CAST(N'2026-02-21T19:32:14.320' AS DateTime), CAST(N'2026-02-21T19:32:14.320' AS DateTime))
INSERT [dbo].[UserDeviceTokens] ([UserDeviceTokenID], [UserID], [Platform], [Token], [DeviceId], [IsActive], [LastSeenAt], [CreatedDate], [UpdatedDate]) VALUES (14, 4, N'Fcm', N'install_1771677596830000', NULL, 1, CAST(N'2026-02-21T19:39:56.863' AS DateTime), CAST(N'2026-02-21T19:39:56.863' AS DateTime), CAST(N'2026-02-21T19:39:56.863' AS DateTime))
INSERT [dbo].[UserDeviceTokens] ([UserDeviceTokenID], [UserID], [Platform], [Token], [DeviceId], [IsActive], [LastSeenAt], [CreatedDate], [UpdatedDate]) VALUES (15, 4, N'Fcm', N'install_1771677707318000', NULL, 1, CAST(N'2026-02-21T19:41:47.350' AS DateTime), CAST(N'2026-02-21T19:41:47.350' AS DateTime), CAST(N'2026-02-21T19:41:47.350' AS DateTime))
INSERT [dbo].[UserDeviceTokens] ([UserDeviceTokenID], [UserID], [Platform], [Token], [DeviceId], [IsActive], [LastSeenAt], [CreatedDate], [UpdatedDate]) VALUES (16, 4, N'Fcm', N'install_1771678168736000', NULL, 1, CAST(N'2026-02-21T19:49:28.793' AS DateTime), CAST(N'2026-02-21T19:49:28.793' AS DateTime), CAST(N'2026-02-21T19:49:28.793' AS DateTime))
INSERT [dbo].[UserDeviceTokens] ([UserDeviceTokenID], [UserID], [Platform], [Token], [DeviceId], [IsActive], [LastSeenAt], [CreatedDate], [UpdatedDate]) VALUES (17, 4, N'Fcm', N'install_1771725765712000', NULL, 1, CAST(N'2026-02-22T09:02:45.877' AS DateTime), CAST(N'2026-02-22T09:02:45.877' AS DateTime), CAST(N'2026-02-22T09:02:45.877' AS DateTime))
INSERT [dbo].[UserDeviceTokens] ([UserDeviceTokenID], [UserID], [Platform], [Token], [DeviceId], [IsActive], [LastSeenAt], [CreatedDate], [UpdatedDate]) VALUES (18, 4, N'Fcm', N'install_1771811994424000', NULL, 1, CAST(N'2026-02-23T08:59:54.703' AS DateTime), CAST(N'2026-02-23T08:59:54.703' AS DateTime), CAST(N'2026-02-23T08:59:54.703' AS DateTime))
INSERT [dbo].[UserDeviceTokens] ([UserDeviceTokenID], [UserID], [Platform], [Token], [DeviceId], [IsActive], [LastSeenAt], [CreatedDate], [UpdatedDate]) VALUES (19, 4, N'Fcm', N'install_1771812316801000', NULL, 1, CAST(N'2026-02-23T09:05:16.863' AS DateTime), CAST(N'2026-02-23T09:05:16.863' AS DateTime), CAST(N'2026-02-23T09:05:16.863' AS DateTime))
INSERT [dbo].[UserDeviceTokens] ([UserDeviceTokenID], [UserID], [Platform], [Token], [DeviceId], [IsActive], [LastSeenAt], [CreatedDate], [UpdatedDate]) VALUES (20, 4, N'Fcm', N'install_1771813289621000', NULL, 1, CAST(N'2026-02-23T09:21:29.697' AS DateTime), CAST(N'2026-02-23T09:21:29.697' AS DateTime), CAST(N'2026-02-23T09:21:29.697' AS DateTime))
INSERT [dbo].[UserDeviceTokens] ([UserDeviceTokenID], [UserID], [Platform], [Token], [DeviceId], [IsActive], [LastSeenAt], [CreatedDate], [UpdatedDate]) VALUES (21, 4, N'Fcm', N'install_1771814856434000', NULL, 1, CAST(N'2026-02-23T09:47:36.490' AS DateTime), CAST(N'2026-02-23T09:47:36.490' AS DateTime), CAST(N'2026-02-23T09:47:36.490' AS DateTime))
INSERT [dbo].[UserDeviceTokens] ([UserDeviceTokenID], [UserID], [Platform], [Token], [DeviceId], [IsActive], [LastSeenAt], [CreatedDate], [UpdatedDate]) VALUES (22, 4, N'Fcm', N'install_1771815452222000', NULL, 1, CAST(N'2026-02-23T09:57:32.343' AS DateTime), CAST(N'2026-02-23T09:57:32.343' AS DateTime), CAST(N'2026-02-23T09:57:32.343' AS DateTime))
INSERT [dbo].[UserDeviceTokens] ([UserDeviceTokenID], [UserID], [Platform], [Token], [DeviceId], [IsActive], [LastSeenAt], [CreatedDate], [UpdatedDate]) VALUES (23, 4, N'Fcm', N'install_1771815689317000', NULL, 1, CAST(N'2026-02-23T10:01:29.353' AS DateTime), CAST(N'2026-02-23T10:01:29.353' AS DateTime), CAST(N'2026-02-23T10:01:29.353' AS DateTime))
INSERT [dbo].[UserDeviceTokens] ([UserDeviceTokenID], [UserID], [Platform], [Token], [DeviceId], [IsActive], [LastSeenAt], [CreatedDate], [UpdatedDate]) VALUES (24, 4, N'Fcm', N'install_1771816505677000', NULL, 1, CAST(N'2026-02-23T10:15:05.747' AS DateTime), CAST(N'2026-02-23T10:15:05.747' AS DateTime), CAST(N'2026-02-23T10:15:05.747' AS DateTime))
INSERT [dbo].[UserDeviceTokens] ([UserDeviceTokenID], [UserID], [Platform], [Token], [DeviceId], [IsActive], [LastSeenAt], [CreatedDate], [UpdatedDate]) VALUES (25, 4, N'Fcm', N'install_1772005060380000', NULL, 1, CAST(N'2026-02-25T14:37:40.480' AS DateTime), CAST(N'2026-02-25T14:37:40.480' AS DateTime), CAST(N'2026-02-25T14:37:40.480' AS DateTime))
INSERT [dbo].[UserDeviceTokens] ([UserDeviceTokenID], [UserID], [Platform], [Token], [DeviceId], [IsActive], [LastSeenAt], [CreatedDate], [UpdatedDate]) VALUES (26, 4, N'Fcm', N'install_1772009356653000', NULL, 1, CAST(N'2026-02-25T15:49:16.780' AS DateTime), CAST(N'2026-02-25T15:49:16.780' AS DateTime), CAST(N'2026-02-25T15:49:16.780' AS DateTime))
INSERT [dbo].[UserDeviceTokens] ([UserDeviceTokenID], [UserID], [Platform], [Token], [DeviceId], [IsActive], [LastSeenAt], [CreatedDate], [UpdatedDate]) VALUES (27, 4, N'Fcm', N'install_1772022365423208', NULL, 1, CAST(N'2026-02-25T19:28:32.263' AS DateTime), CAST(N'2026-02-25T19:26:06.037' AS DateTime), CAST(N'2026-02-25T19:28:32.263' AS DateTime))
INSERT [dbo].[UserDeviceTokens] ([UserDeviceTokenID], [UserID], [Platform], [Token], [DeviceId], [IsActive], [LastSeenAt], [CreatedDate], [UpdatedDate]) VALUES (28, 4, N'Fcm', N'install_1772159685572526', NULL, 1, CAST(N'2026-02-27T09:34:46.110' AS DateTime), CAST(N'2026-02-27T09:34:46.110' AS DateTime), CAST(N'2026-02-27T09:34:46.110' AS DateTime))
INSERT [dbo].[UserDeviceTokens] ([UserDeviceTokenID], [UserID], [Platform], [Token], [DeviceId], [IsActive], [LastSeenAt], [CreatedDate], [UpdatedDate]) VALUES (29, 4, N'Fcm', N'install_1772281052051000', NULL, 1, CAST(N'2026-02-28T19:17:32.197' AS DateTime), CAST(N'2026-02-28T19:17:32.197' AS DateTime), CAST(N'2026-02-28T19:17:32.197' AS DateTime))
INSERT [dbo].[UserDeviceTokens] ([UserDeviceTokenID], [UserID], [Platform], [Token], [DeviceId], [IsActive], [LastSeenAt], [CreatedDate], [UpdatedDate]) VALUES (30, 4, N'Fcm', N'install_1772281805454000', NULL, 1, CAST(N'2026-02-28T19:30:05.503' AS DateTime), CAST(N'2026-02-28T19:30:05.503' AS DateTime), CAST(N'2026-02-28T19:30:05.503' AS DateTime))
INSERT [dbo].[UserDeviceTokens] ([UserDeviceTokenID], [UserID], [Platform], [Token], [DeviceId], [IsActive], [LastSeenAt], [CreatedDate], [UpdatedDate]) VALUES (31, 4, N'Fcm', N'fr-ae-yPTWmdkzjMTrlmE2:APA91bFT4vfwxqB-612nIHFHe7T9msNAIaKVXPdx-foOHXmq80N-7ksfyk4M2ECQnPmP87Kh0p9qPLkSrSFPb_ebrBFLDdKbOyx3BGO9nMD962JTEEfDJ3g', NULL, 1, CAST(N'2026-03-05T14:19:33.940' AS DateTime), CAST(N'2026-03-04T19:15:46.233' AS DateTime), CAST(N'2026-03-05T14:19:33.940' AS DateTime))
INSERT [dbo].[UserDeviceTokens] ([UserDeviceTokenID], [UserID], [Platform], [Token], [DeviceId], [IsActive], [LastSeenAt], [CreatedDate], [UpdatedDate]) VALUES (32, 4, N'Fcm', N'cE_wxPb3TaWEX9jdr7dAmP:APA91bENZ1tRqLDfiumO3x5-tOs-3Im6Bo6ba4P_ZUs1IRaTEVAy8hQ38g8ie4RWXWKVw_wzPARh-QTOo46cMjxhImoMh0w0spBT1umHJ9QMoBv8dw75Hb8', NULL, 1, CAST(N'2026-03-11T20:34:58.747' AS DateTime), CAST(N'2026-03-06T19:05:42.077' AS DateTime), CAST(N'2026-03-11T20:34:58.747' AS DateTime))
SET IDENTITY_INSERT [dbo].[UserDeviceTokens] OFF
GO
SET IDENTITY_INSERT [dbo].[UserRoles] ON 

INSERT [dbo].[UserRoles] ([UserRoleID], [UserID], [RoleID], [AssignDate]) VALUES (2, 2, 5, CAST(N'2025-12-22T15:45:18.947' AS DateTime))
INSERT [dbo].[UserRoles] ([UserRoleID], [UserID], [RoleID], [AssignDate]) VALUES (3, 3, 6, CAST(N'2025-12-22T15:45:18.950' AS DateTime))
INSERT [dbo].[UserRoles] ([UserRoleID], [UserID], [RoleID], [AssignDate]) VALUES (4, 4, 7, CAST(N'2025-12-22T15:45:18.950' AS DateTime))
INSERT [dbo].[UserRoles] ([UserRoleID], [UserID], [RoleID], [AssignDate]) VALUES (5, 5, 8, CAST(N'2025-12-22T15:45:18.953' AS DateTime))
INSERT [dbo].[UserRoles] ([UserRoleID], [UserID], [RoleID], [AssignDate]) VALUES (1002, 1002, 7, CAST(N'2026-02-08T15:26:51.317' AS DateTime))
SET IDENTITY_INSERT [dbo].[UserRoles] OFF
GO
SET IDENTITY_INSERT [dbo].[Users] ON 

INSERT [dbo].[Users] ([UserID], [Code], [FullName], [Email], [Phone], [PasswordHash], [AvatarUrl], [Gender], [DateOfBirth], [Address], [Status], [LastLoginDate], [CreatedDate], [UpdatedDate]) VALUES (2, N'ADMIN001', N'Nguyễn Văn Admin', N'daothidiemtrinh05@gmail.com', N'0123456789', N'$2a$11$kAXuEVUxea6grfmmedYM/uj5vwYvcrB0lzHyY35sIZLgliDIScxZS', N'/uploads/avatars/avatar_2.jpg', 1, CAST(N'2000-12-26' AS Date), NULL, 1, CAST(N'2026-03-08T15:45:33.787' AS DateTime), CAST(N'2025-12-22T15:45:18.893' AS DateTime), CAST(N'2026-03-08T15:45:33.787' AS DateTime))
INSERT [dbo].[Users] ([UserID], [Code], [FullName], [Email], [Phone], [PasswordHash], [AvatarUrl], [Gender], [DateOfBirth], [Address], [Status], [LastLoginDate], [CreatedDate], [UpdatedDate]) VALUES (3, N'CB001', N'Trần Thị Cán Bộ', N'canbo@uniyouth.edu.vn', N'0902345678', N'$2a$11$lY3PSHe8JUtMx3DpuzBZI.xj2tN7j5/pp2fdlOolIvVNvMrYH9Nem', N'/uploads/avatars/avatar_3.jpg', 0, NULL, NULL, 1, CAST(N'2026-02-28T14:45:06.370' AS DateTime), CAST(N'2025-12-22T15:45:18.893' AS DateTime), CAST(N'2026-02-28T14:45:06.370' AS DateTime))
INSERT [dbo].[Users] ([UserID], [Code], [FullName], [Email], [Phone], [PasswordHash], [AvatarUrl], [Gender], [DateOfBirth], [Address], [Status], [LastLoginDate], [CreatedDate], [UpdatedDate]) VALUES (4, N'SV2001', N'Lê Văn Đoàn Viên', N'student@example.com', N'0903456789', N'$2a$11$Lj/92GIygMpq8oInmQqH1ej.IlVpSYed/vmjivT40i02fyY37EBcu', N'http://192.168.1.13:5160/uploads/avatars/avatar_4.jpg', 0, CAST(N'1991-02-02' AS Date), NULL, 1, CAST(N'2026-03-12T21:54:24.927' AS DateTime), CAST(N'2025-12-22T15:45:18.893' AS DateTime), CAST(N'2026-03-12T21:54:24.927' AS DateTime))
INSERT [dbo].[Users] ([UserID], [Code], [FullName], [Email], [Phone], [PasswordHash], [AvatarUrl], [Gender], [DateOfBirth], [Address], [Status], [LastLoginDate], [CreatedDate], [UpdatedDate]) VALUES (5, N'SV1901', N'Phạm Thị Hội Viên', N'hoivien@uniyouth.edu.vn', N'0904567890', N'$2a$11$lY3PSHe8JUtMx3DpuzBZI.xj2tN7j5/pp2fdlOolIvVNvMrYH9Nem', NULL, 0, NULL, NULL, 1, CAST(N'2026-01-07T02:28:23.473' AS DateTime), CAST(N'2025-12-22T15:45:18.897' AS DateTime), CAST(N'2026-01-07T02:28:23.473' AS DateTime))
INSERT [dbo].[Users] ([UserID], [Code], [FullName], [Email], [Phone], [PasswordHash], [AvatarUrl], [Gender], [DateOfBirth], [Address], [Status], [LastLoginDate], [CreatedDate], [UpdatedDate]) VALUES (1002, N'sv1', N'sv1', N'user@example.com', N'123456', N'$2a$11$/dzXxF1odg9udhnicQk/qOQfAmHTQ/cWLEsFqj81OOBDJFSHtU40y', NULL, 1, CAST(N'2005-02-08' AS Date), N'1234', 0, NULL, CAST(N'2026-02-08T15:26:51.177' AS DateTime), CAST(N'2026-02-08T15:41:34.313' AS DateTime))
SET IDENTITY_INSERT [dbo].[Users] OFF
GO
SET IDENTITY_INSERT [dbo].[UserUnits] ON 

INSERT [dbo].[UserUnits] ([UserUnitID], [UserID], [UnitID], [JoinDate], [Position], [Status], [CreatedDate], [UpdatedDate]) VALUES (1, 3, 1, CAST(N'2025-12-22' AS Date), N'Bí thư', 1, CAST(N'2025-12-22T15:45:18.997' AS DateTime), CAST(N'2025-12-22T15:45:18.997' AS DateTime))
INSERT [dbo].[UserUnits] ([UserUnitID], [UserID], [UnitID], [JoinDate], [Position], [Status], [CreatedDate], [UpdatedDate]) VALUES (2, 4, 1, CAST(N'2025-12-22' AS Date), N'Đoàn viên', 1, CAST(N'2025-12-22T15:45:19.007' AS DateTime), CAST(N'2026-03-11T20:38:00.390' AS DateTime))
INSERT [dbo].[UserUnits] ([UserUnitID], [UserID], [UnitID], [JoinDate], [Position], [Status], [CreatedDate], [UpdatedDate]) VALUES (3, 5, 2, CAST(N'2025-12-22' AS Date), N'Hội viên', 1, CAST(N'2025-12-22T15:45:19.010' AS DateTime), CAST(N'2025-12-22T15:45:19.010' AS DateTime))
INSERT [dbo].[UserUnits] ([UserUnitID], [UserID], [UnitID], [JoinDate], [Position], [Status], [CreatedDate], [UpdatedDate]) VALUES (1002, 1002, 1, CAST(N'2020-02-08' AS Date), N'Đoàn viên', 0, CAST(N'2026-02-08T15:26:51.277' AS DateTime), CAST(N'2026-02-08T15:41:34.313' AS DateTime))
INSERT [dbo].[UserUnits] ([UserUnitID], [UserID], [UnitID], [JoinDate], [Position], [Status], [CreatedDate], [UpdatedDate]) VALUES (1003, 1002, 1, CAST(N'2025-02-08' AS Date), N'Đoàn viên', 1, CAST(N'2026-02-08T15:41:34.313' AS DateTime), CAST(N'2026-02-08T15:41:34.313' AS DateTime))
SET IDENTITY_INSERT [dbo].[UserUnits] OFF
GO
/****** Object:  Index [IX_ActivityPoints_EventID]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_ActivityPoints_EventID] ON [dbo].[ActivityPoints]
(
	[EventID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_ActivityPoints_UserID]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_ActivityPoints_UserID] ON [dbo].[ActivityPoints]
(
	[UserID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [UQ_ActivityPoints_Attendance_EventID_UserID]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [UQ_ActivityPoints_Attendance_EventID_UserID] ON [dbo].[ActivityPoints]
(
	[EventID] ASC,
	[UserID] ASC
)
WHERE ([PointType]=N'Attendance')
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [UQ__Attendan__A83C44BBDD097F01]    Script Date: 3/13/2026 6:20:28 AM ******/
ALTER TABLE [dbo].[Attendances] ADD UNIQUE NONCLUSTERED 
(
	[EventID] ASC,
	[UserID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Attendances_CheckInTime]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_Attendances_CheckInTime] ON [dbo].[Attendances]
(
	[CheckInTime] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Attendances_EventID]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_Attendances_EventID] ON [dbo].[Attendances]
(
	[EventID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Attendances_IsValid]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_Attendances_IsValid] ON [dbo].[Attendances]
(
	[IsValid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Attendances_UserID]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_Attendances_UserID] ON [dbo].[Attendances]
(
	[UserID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_AuditLogs_CreatedDate]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_AuditLogs_CreatedDate] ON [dbo].[AuditLogs]
(
	[CreatedDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_AuditLogs_TableName]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_AuditLogs_TableName] ON [dbo].[AuditLogs]
(
	[TableName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_AuditLogs_UserID]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_AuditLogs_UserID] ON [dbo].[AuditLogs]
(
	[UserID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_EventImages_EventID]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_EventImages_EventID] ON [dbo].[EventImages]
(
	[EventID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_EventImages_EventID_ImageType_DisplayOrder]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_EventImages_EventID_ImageType_DisplayOrder] ON [dbo].[EventImages]
(
	[EventID] ASC,
	[ImageType] ASC,
	[DisplayOrder] ASC
)
INCLUDE([ImageUrl]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UQ_EventPoints_EventID_RoleType]    Script Date: 3/13/2026 6:20:28 AM ******/
ALTER TABLE [dbo].[EventPoints] ADD  CONSTRAINT [UQ_EventPoints_EventID_RoleType] UNIQUE NONCLUSTERED 
(
	[EventID] ASC,
	[RoleType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_EventPoints_EventID]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_EventPoints_EventID] ON [dbo].[EventPoints]
(
	[EventID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UX_EventPoints_Event_Role]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [UX_EventPoints_Event_Role] ON [dbo].[EventPoints]
(
	[EventID] ASC,
	[RoleType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UQ__EventQRC__7CC967E53D20027C]    Script Date: 3/13/2026 6:20:28 AM ******/
ALTER TABLE [dbo].[EventQRCodes] ADD UNIQUE NONCLUSTERED 
(
	[QRToken] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_EventQRCodes_CreatedDate]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_EventQRCodes_CreatedDate] ON [dbo].[EventQRCodes]
(
	[CreatedDate] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_EventQRCodes_EventID]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_EventQRCodes_EventID] ON [dbo].[EventQRCodes]
(
	[EventID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_EventQRCodes_IsActive_EventID]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_EventQRCodes_IsActive_EventID] ON [dbo].[EventQRCodes]
(
	[IsActive] ASC,
	[EventID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_EventQRCodes_QRToken]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_EventQRCodes_QRToken] ON [dbo].[EventQRCodes]
(
	[QRToken] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [UQ_EventQRCodes_Active_EventID]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [UQ_EventQRCodes_Active_EventID] ON [dbo].[EventQRCodes]
(
	[EventID] ASC
)
WHERE ([IsActive]=(1))
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [UQ__EventReg__A83C44BB5DC3F252]    Script Date: 3/13/2026 6:20:28 AM ******/
ALTER TABLE [dbo].[EventRegistrations] ADD UNIQUE NONCLUSTERED 
(
	[EventID] ASC,
	[UserID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_EventRegistrations_EventID]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_EventRegistrations_EventID] ON [dbo].[EventRegistrations]
(
	[EventID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_EventRegistrations_Status]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_EventRegistrations_Status] ON [dbo].[EventRegistrations]
(
	[Status] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_EventRegistrations_UserID]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_EventRegistrations_UserID] ON [dbo].[EventRegistrations]
(
	[UserID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Events_CreatedBy]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_Events_CreatedBy] ON [dbo].[Events]
(
	[CreatedBy] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Events_InstituteID]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_Events_InstituteID] ON [dbo].[Events]
(
	[InstituteID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Events_Status_StartTime]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_Events_Status_StartTime] ON [dbo].[Events]
(
	[Status] ASC,
	[StartTime] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UQ__EventTyp__D4E7DFA8C708CE46]    Script Date: 3/13/2026 6:20:28 AM ******/
ALTER TABLE [dbo].[EventType] ADD UNIQUE NONCLUSTERED 
(
	[TypeName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_FaceProfiles_UserID_IsActive]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_FaceProfiles_UserID_IsActive] ON [dbo].[FaceProfiles]
(
	[UserID] ASC,
	[IsActive] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_FaceRecognitionLogs_AttendanceID]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_FaceRecognitionLogs_AttendanceID] ON [dbo].[FaceRecognitionLogs]
(
	[AttendanceID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_FaceRecognitionLogs_IsMatched]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_FaceRecognitionLogs_IsMatched] ON [dbo].[FaceRecognitionLogs]
(
	[IsMatched] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_LocationPresets_InstituteID]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_LocationPresets_InstituteID] ON [dbo].[LocationPresets]
(
	[InstituteID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_LocationPresets_IsActive]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_LocationPresets_IsActive] ON [dbo].[LocationPresets]
(
	[IsActive] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_LocationPresets_Name]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_LocationPresets_Name] ON [dbo].[LocationPresets]
(
	[Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_LocationPresets_UnitID]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_LocationPresets_UnitID] ON [dbo].[LocationPresets]
(
	[UnitID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_NotificationArchive_ArchivedDate]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_NotificationArchive_ArchivedDate] ON [dbo].[NotificationArchive]
(
	[ArchivedDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_NotificationArchive_CreatedDate]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_NotificationArchive_CreatedDate] ON [dbo].[NotificationArchive]
(
	[CreatedDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_NotificationArchive_UserID]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_NotificationArchive_UserID] ON [dbo].[NotificationArchive]
(
	[UserID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_NotificationDeliveryLog_CreatedDate]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_NotificationDeliveryLog_CreatedDate] ON [dbo].[NotificationDeliveryLog]
(
	[CreatedDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_NotificationDeliveryLog_NotificationID]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_NotificationDeliveryLog_NotificationID] ON [dbo].[NotificationDeliveryLog]
(
	[NotificationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_NotificationDeliveryLog_OutboxID]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_NotificationDeliveryLog_OutboxID] ON [dbo].[NotificationDeliveryLog]
(
	[OutboxID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_NotificationOutbox_NotificationID]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_NotificationOutbox_NotificationID] ON [dbo].[NotificationOutbox]
(
	[NotificationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_NotificationOutbox_Status_NextAttemptAt]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_NotificationOutbox_Status_NextAttemptAt] ON [dbo].[NotificationOutbox]
(
	[Status] ASC,
	[NextAttemptAt] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_NotificationOutbox_UserID]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_NotificationOutbox_UserID] ON [dbo].[NotificationOutbox]
(
	[UserID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [UX_NotificationOutbox_Notification_Channel]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [UX_NotificationOutbox_Notification_Channel] ON [dbo].[NotificationOutbox]
(
	[NotificationID] ASC,
	[Channel] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Notifications_CreatedDate]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_Notifications_CreatedDate] ON [dbo].[Notifications]
(
	[CreatedDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Notifications_UserID_IsRead]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_Notifications_UserID_IsRead] ON [dbo].[Notifications]
(
	[UserID] ASC,
	[IsRead] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UX_Notifications_DedupKey_NotNull]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [UX_Notifications_DedupKey_NotNull] ON [dbo].[Notifications]
(
	[DedupKey] ASC
)
WHERE ([DedupKey] IS NOT NULL)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UQ__Notifica__D4E7DFA84C058C88]    Script Date: 3/13/2026 6:20:28 AM ******/
ALTER TABLE [dbo].[NotificationType] ADD UNIQUE NONCLUSTERED 
(
	[TypeName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_PasswordResetOtps_ExpiresAt]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_PasswordResetOtps_ExpiresAt] ON [dbo].[PasswordResetOtps]
(
	[ExpiresAt] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_PasswordResetOtps_UserID_IsUsed_ExpiresAt]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_PasswordResetOtps_UserID_IsUsed_ExpiresAt] ON [dbo].[PasswordResetOtps]
(
	[UserID] ASC,
	[IsUsed] ASC,
	[ExpiresAt] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_PasswordResetOtps_UserID_Purpose_CreatedDate]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_PasswordResetOtps_UserID_Purpose_CreatedDate] ON [dbo].[PasswordResetOtps]
(
	[UserID] ASC,
	[Purpose] ASC,
	[CreatedDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_PasswordResetSessions_OtpID_IsUsed]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_PasswordResetSessions_OtpID_IsUsed] ON [dbo].[PasswordResetSessions]
(
	[OtpID] ASC,
	[IsUsed] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_PasswordResetSessions_UserID_ExpiresAt_IsUsed]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_PasswordResetSessions_UserID_ExpiresAt_IsUsed] ON [dbo].[PasswordResetSessions]
(
	[UserID] ASC,
	[ExpiresAt] ASC,
	[IsUsed] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UQ_PasswordResetSessions_SessionTokenHash]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [UQ_PasswordResetSessions_SessionTokenHash] ON [dbo].[PasswordResetSessions]
(
	[SessionTokenHash] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_PasswordResetTokens_UserID]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_PasswordResetTokens_UserID] ON [dbo].[PasswordResetTokens]
(
	[UserID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UX_PasswordResetTokens_Token]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [UX_PasswordResetTokens_Token] ON [dbo].[PasswordResetTokens]
(
	[Token] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UQ__Roles__8A2B6160CE2EF755]    Script Date: 3/13/2026 6:20:28 AM ******/
ALTER TABLE [dbo].[Roles] ADD UNIQUE NONCLUSTERED 
(
	[RoleName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UQ__SystemSe__01E719AD4C0D81A2]    Script Date: 3/13/2026 6:20:28 AM ******/
ALTER TABLE [dbo].[SystemSettings] ADD UNIQUE NONCLUSTERED 
(
	[SettingKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Units_InstituteID]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_Units_InstituteID] ON [dbo].[Units]
(
	[InstituteID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_UserDeviceTokens_UserID_IsActive]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_UserDeviceTokens_UserID_IsActive] ON [dbo].[UserDeviceTokens]
(
	[UserID] ASC,
	[IsActive] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UQ_UserDeviceTokens_Platform_Token]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [UQ_UserDeviceTokens_Platform_Token] ON [dbo].[UserDeviceTokens]
(
	[Platform] ASC,
	[Token] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_UserNotificationPreferences_NotificationTypeID]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_UserNotificationPreferences_NotificationTypeID] ON [dbo].[UserNotificationPreferences]
(
	[NotificationTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_UserNotificationPreferences_UserID]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_UserNotificationPreferences_UserID] ON [dbo].[UserNotificationPreferences]
(
	[UserID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [UQ_UserNotificationPreferences_UserID_NotificationTypeID]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [UQ_UserNotificationPreferences_UserID_NotificationTypeID] ON [dbo].[UserNotificationPreferences]
(
	[UserID] ASC,
	[NotificationTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [UQ__UserRole__AF27604EA7094FF2]    Script Date: 3/13/2026 6:20:28 AM ******/
ALTER TABLE [dbo].[UserRoles] ADD UNIQUE NONCLUSTERED 
(
	[UserID] ASC,
	[RoleID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_UserRoles_RoleID]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_UserRoles_RoleID] ON [dbo].[UserRoles]
(
	[RoleID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_UserRoles_UserID]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_UserRoles_UserID] ON [dbo].[UserRoles]
(
	[UserID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UQ__Users__1FC88604054AAE80]    Script Date: 3/13/2026 6:20:28 AM ******/
ALTER TABLE [dbo].[Users] ADD UNIQUE NONCLUSTERED 
(
	[Code] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UQ__Users__A9D105346B81BCAA]    Script Date: 3/13/2026 6:20:28 AM ******/
ALTER TABLE [dbo].[Users] ADD UNIQUE NONCLUSTERED 
(
	[Email] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_Users_Email]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_Users_Email] ON [dbo].[Users]
(
	[Email] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Users_Status]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_Users_Status] ON [dbo].[Users]
(
	[Status] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_Users_Code]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_Users_Code] ON [dbo].[Users]
(
	[Code] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_UserUnits_UnitID]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_UserUnits_UnitID] ON [dbo].[UserUnits]
(
	[UnitID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_UserUnits_UserID]    Script Date: 3/13/2026 6:20:28 AM ******/
CREATE NONCLUSTERED INDEX [IX_UserUnits_UserID] ON [dbo].[UserUnits]
(
	[UserID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ActivityPoints] ADD  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[Attendances] ADD  DEFAULT ('QR') FOR [CheckInMethod]
GO
ALTER TABLE [dbo].[Attendances] ADD  DEFAULT (getdate()) FOR [CheckInTime]
GO
ALTER TABLE [dbo].[Attendances] ADD  DEFAULT ((0)) FOR [FaceVerified]
GO
ALTER TABLE [dbo].[Attendances] ADD  DEFAULT ((1)) FOR [IsValid]
GO
ALTER TABLE [dbo].[Attendances] ADD  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[AuditLogs] ADD  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[EventImages] ADD  DEFAULT ((0)) FOR [DisplayOrder]
GO
ALTER TABLE [dbo].[EventImages] ADD  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[EventPoints] ADD  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[EventQRCodes] ADD  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[EventQRCodes] ADD  DEFAULT ((0)) FOR [CurrentScans]
GO
ALTER TABLE [dbo].[EventQRCodes] ADD  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[EventQRCodes] ADD  DEFAULT (getdate()) FOR [UpdatedDate]
GO
ALTER TABLE [dbo].[EventRegistrations] ADD  DEFAULT (getdate()) FOR [RegisterTime]
GO
ALTER TABLE [dbo].[EventRegistrations] ADD  DEFAULT ((0)) FOR [Status]
GO
ALTER TABLE [dbo].[EventRegistrations] ADD  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[EventRegistrations] ADD  DEFAULT (getdate()) FOR [UpdatedDate]
GO
ALTER TABLE [dbo].[Events] ADD  DEFAULT ((100)) FOR [AllowRadius]
GO
ALTER TABLE [dbo].[Events] ADD  DEFAULT ((0)) FOR [CurrentParticipants]
GO
ALTER TABLE [dbo].[Events] ADD  DEFAULT ((0)) FOR [Status]
GO
ALTER TABLE [dbo].[Events] ADD  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[Events] ADD  DEFAULT (getdate()) FOR [UpdatedDate]
GO
ALTER TABLE [dbo].[EventType] ADD  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[FaceProfiles] ADD  DEFAULT ('ArcFace') FOR [Algorithm]
GO
ALTER TABLE [dbo].[FaceProfiles] ADD  DEFAULT ('1.0') FOR [Version]
GO
ALTER TABLE [dbo].[FaceProfiles] ADD  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[FaceProfiles] ADD  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[FaceProfiles] ADD  DEFAULT (getdate()) FOR [UpdatedDate]
GO
ALTER TABLE [dbo].[FaceRecognitionLogs] ADD  DEFAULT ((0.7)) FOR [Threshold]
GO
ALTER TABLE [dbo].[FaceRecognitionLogs] ADD  DEFAULT ((0)) FOR [IsMatched]
GO
ALTER TABLE [dbo].[FaceRecognitionLogs] ADD  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[Institutes] ADD  DEFAULT ((1)) FOR [Status]
GO
ALTER TABLE [dbo].[Institutes] ADD  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[Institutes] ADD  DEFAULT (getdate()) FOR [UpdatedDate]
GO
ALTER TABLE [dbo].[LocationPresets] ADD  CONSTRAINT [DF_LocationPresets_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[LocationPresets] ADD  CONSTRAINT [DF_LocationPresets_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[LocationPresets] ADD  CONSTRAINT [DF_LocationPresets_UpdatedDate]  DEFAULT (getdate()) FOR [UpdatedDate]
GO
ALTER TABLE [dbo].[NotificationArchive] ADD  CONSTRAINT [DF_NotificationArchive_ArchivedDate]  DEFAULT (getdate()) FOR [ArchivedDate]
GO
ALTER TABLE [dbo].[NotificationDeliveryLog] ADD  CONSTRAINT [DF_NotificationDeliveryLog_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[NotificationOutbox] ADD  CONSTRAINT [DF_NotificationOutbox_Status]  DEFAULT ((0)) FOR [Status]
GO
ALTER TABLE [dbo].[NotificationOutbox] ADD  CONSTRAINT [DF_NotificationOutbox_AttemptCount]  DEFAULT ((0)) FOR [AttemptCount]
GO
ALTER TABLE [dbo].[NotificationOutbox] ADD  CONSTRAINT [DF_NotificationOutbox_MaxAttempts]  DEFAULT ((5)) FOR [MaxAttempts]
GO
ALTER TABLE [dbo].[NotificationOutbox] ADD  CONSTRAINT [DF_NotificationOutbox_NextAttemptAt]  DEFAULT (getdate()) FOR [NextAttemptAt]
GO
ALTER TABLE [dbo].[NotificationOutbox] ADD  CONSTRAINT [DF_NotificationOutbox_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[NotificationOutbox] ADD  CONSTRAINT [DF_NotificationOutbox_UpdatedDate]  DEFAULT (getdate()) FOR [UpdatedDate]
GO
ALTER TABLE [dbo].[Notifications] ADD  DEFAULT ((0)) FOR [Priority]
GO
ALTER TABLE [dbo].[Notifications] ADD  DEFAULT ((0)) FOR [IsRead]
GO
ALTER TABLE [dbo].[Notifications] ADD  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[NotificationType] ADD  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[PasswordResetOtps] ADD  CONSTRAINT [DF_PasswordResetOtps_AttemptCount]  DEFAULT ((0)) FOR [AttemptCount]
GO
ALTER TABLE [dbo].[PasswordResetOtps] ADD  CONSTRAINT [DF_PasswordResetOtps_MaxAttempts]  DEFAULT ((5)) FOR [MaxAttempts]
GO
ALTER TABLE [dbo].[PasswordResetOtps] ADD  CONSTRAINT [DF_PasswordResetOtps_ResendCount]  DEFAULT ((0)) FOR [ResendCount]
GO
ALTER TABLE [dbo].[PasswordResetOtps] ADD  CONSTRAINT [DF_PasswordResetOtps_MaxResends]  DEFAULT ((3)) FOR [MaxResends]
GO
ALTER TABLE [dbo].[PasswordResetOtps] ADD  CONSTRAINT [DF_PasswordResetOtps_IsUsed]  DEFAULT ((0)) FOR [IsUsed]
GO
ALTER TABLE [dbo].[PasswordResetOtps] ADD  CONSTRAINT [DF_PasswordResetOtps_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[PasswordResetOtps] ADD  CONSTRAINT [DF_PasswordResetOtps_LastSentAt]  DEFAULT (getdate()) FOR [LastSentAt]
GO
ALTER TABLE [dbo].[PasswordResetSessions] ADD  CONSTRAINT [DF_PasswordResetSessions_IsUsed]  DEFAULT ((0)) FOR [IsUsed]
GO
ALTER TABLE [dbo].[PasswordResetSessions] ADD  CONSTRAINT [DF_PasswordResetSessions_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[PasswordResetTokens] ADD  CONSTRAINT [DF_PasswordResetTokens_IsUsed]  DEFAULT ((0)) FOR [IsUsed]
GO
ALTER TABLE [dbo].[PasswordResetTokens] ADD  CONSTRAINT [DF_PasswordResetTokens_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[Roles] ADD  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[SystemSettings] ADD  DEFAULT ('string') FOR [DataType]
GO
ALTER TABLE [dbo].[SystemSettings] ADD  DEFAULT (getdate()) FOR [UpdatedDate]
GO
ALTER TABLE [dbo].[Units] ADD  DEFAULT ((1)) FOR [Status]
GO
ALTER TABLE [dbo].[Units] ADD  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[Units] ADD  DEFAULT (getdate()) FOR [UpdatedDate]
GO
ALTER TABLE [dbo].[UserDeviceTokens] ADD  CONSTRAINT [DF_UserDeviceTokens_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[UserDeviceTokens] ADD  CONSTRAINT [DF_UserDeviceTokens_LastSeenAt]  DEFAULT (getdate()) FOR [LastSeenAt]
GO
ALTER TABLE [dbo].[UserDeviceTokens] ADD  CONSTRAINT [DF_UserDeviceTokens_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[UserDeviceTokens] ADD  CONSTRAINT [DF_UserDeviceTokens_UpdatedDate]  DEFAULT (getdate()) FOR [UpdatedDate]
GO
ALTER TABLE [dbo].[UserNotificationPreferences] ADD  CONSTRAINT [DF_UserNotificationPreferences_IsInAppEnabled]  DEFAULT ((1)) FOR [IsInAppEnabled]
GO
ALTER TABLE [dbo].[UserNotificationPreferences] ADD  CONSTRAINT [DF_UserNotificationPreferences_IsRealtimeEnabled]  DEFAULT ((1)) FOR [IsRealtimeEnabled]
GO
ALTER TABLE [dbo].[UserNotificationPreferences] ADD  CONSTRAINT [DF_UserNotificationPreferences_IsPushEnabled]  DEFAULT ((1)) FOR [IsPushEnabled]
GO
ALTER TABLE [dbo].[UserNotificationPreferences] ADD  CONSTRAINT [DF_UserNotificationPreferences_IsMuted]  DEFAULT ((0)) FOR [IsMuted]
GO
ALTER TABLE [dbo].[UserNotificationPreferences] ADD  CONSTRAINT [DF_UserNotificationPreferences_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[UserNotificationPreferences] ADD  CONSTRAINT [DF_UserNotificationPreferences_UpdatedDate]  DEFAULT (getdate()) FOR [UpdatedDate]
GO
ALTER TABLE [dbo].[UserRoles] ADD  DEFAULT (getdate()) FOR [AssignDate]
GO
ALTER TABLE [dbo].[Users] ADD  DEFAULT ((1)) FOR [Status]
GO
ALTER TABLE [dbo].[Users] ADD  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[Users] ADD  DEFAULT (getdate()) FOR [UpdatedDate]
GO
ALTER TABLE [dbo].[UserUnits] ADD  DEFAULT ((1)) FOR [Status]
GO
ALTER TABLE [dbo].[UserUnits] ADD  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[UserUnits] ADD  DEFAULT (getdate()) FOR [UpdatedDate]
GO
ALTER TABLE [dbo].[ActivityPoints]  WITH CHECK ADD FOREIGN KEY([AwardedBy])
REFERENCES [dbo].[Users] ([UserID])
GO
ALTER TABLE [dbo].[ActivityPoints]  WITH CHECK ADD FOREIGN KEY([EventID])
REFERENCES [dbo].[Events] ([EventID])
GO
ALTER TABLE [dbo].[ActivityPoints]  WITH CHECK ADD FOREIGN KEY([EventPointID])
REFERENCES [dbo].[EventPoints] ([EventPointID])
GO
ALTER TABLE [dbo].[ActivityPoints]  WITH CHECK ADD FOREIGN KEY([UserID])
REFERENCES [dbo].[Users] ([UserID])
GO
ALTER TABLE [dbo].[Attendances]  WITH CHECK ADD FOREIGN KEY([EventID])
REFERENCES [dbo].[Events] ([EventID])
GO
ALTER TABLE [dbo].[Attendances]  WITH CHECK ADD FOREIGN KEY([UserID])
REFERENCES [dbo].[Users] ([UserID])
GO
ALTER TABLE [dbo].[Attendances]  WITH CHECK ADD FOREIGN KEY([QRID])
REFERENCES [dbo].[EventQRCodes] ([QRID])
GO
ALTER TABLE [dbo].[AuditLogs]  WITH CHECK ADD FOREIGN KEY([UserID])
REFERENCES [dbo].[Users] ([UserID])
GO
ALTER TABLE [dbo].[EventImages]  WITH CHECK ADD FOREIGN KEY([EventID])
REFERENCES [dbo].[Events] ([EventID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[EventPoints]  WITH CHECK ADD FOREIGN KEY([EventID])
REFERENCES [dbo].[Events] ([EventID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[EventQRCodes]  WITH CHECK ADD FOREIGN KEY([CreatedBy])
REFERENCES [dbo].[Users] ([UserID])
GO
ALTER TABLE [dbo].[EventQRCodes]  WITH CHECK ADD FOREIGN KEY([EventID])
REFERENCES [dbo].[Events] ([EventID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[EventRegistrations]  WITH CHECK ADD FOREIGN KEY([EventID])
REFERENCES [dbo].[Events] ([EventID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[EventRegistrations]  WITH CHECK ADD FOREIGN KEY([UserID])
REFERENCES [dbo].[Users] ([UserID])
GO
ALTER TABLE [dbo].[Events]  WITH CHECK ADD FOREIGN KEY([CreatedBy])
REFERENCES [dbo].[Users] ([UserID])
GO
ALTER TABLE [dbo].[Events]  WITH CHECK ADD FOREIGN KEY([EventTypeID])
REFERENCES [dbo].[EventType] ([TypeID])
GO
ALTER TABLE [dbo].[Events]  WITH CHECK ADD FOREIGN KEY([InstituteID])
REFERENCES [dbo].[Institutes] ([InstituteID])
GO
ALTER TABLE [dbo].[FaceProfiles]  WITH CHECK ADD FOREIGN KEY([UserID])
REFERENCES [dbo].[Users] ([UserID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[FaceRecognitionLogs]  WITH CHECK ADD FOREIGN KEY([AttendanceID])
REFERENCES [dbo].[Attendances] ([AttendanceID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[FaceRecognitionLogs]  WITH CHECK ADD FOREIGN KEY([FaceProfileID])
REFERENCES [dbo].[FaceProfiles] ([FaceProfileID])
GO
ALTER TABLE [dbo].[LocationPresets]  WITH CHECK ADD  CONSTRAINT [FK_LocationPresets_Institutes] FOREIGN KEY([InstituteID])
REFERENCES [dbo].[Institutes] ([InstituteID])
GO
ALTER TABLE [dbo].[LocationPresets] CHECK CONSTRAINT [FK_LocationPresets_Institutes]
GO
ALTER TABLE [dbo].[LocationPresets]  WITH CHECK ADD  CONSTRAINT [FK_LocationPresets_Units] FOREIGN KEY([UnitID])
REFERENCES [dbo].[Units] ([UnitID])
GO
ALTER TABLE [dbo].[LocationPresets] CHECK CONSTRAINT [FK_LocationPresets_Units]
GO
ALTER TABLE [dbo].[LocationPresets]  WITH CHECK ADD  CONSTRAINT [FK_LocationPresets_Users] FOREIGN KEY([CreatedBy])
REFERENCES [dbo].[Users] ([UserID])
GO
ALTER TABLE [dbo].[LocationPresets] CHECK CONSTRAINT [FK_LocationPresets_Users]
GO
ALTER TABLE [dbo].[NotificationDeliveryLog]  WITH CHECK ADD  CONSTRAINT [FK_NotificationDeliveryLog_Notification] FOREIGN KEY([NotificationID])
REFERENCES [dbo].[Notifications] ([NotificationID])
GO
ALTER TABLE [dbo].[NotificationDeliveryLog] CHECK CONSTRAINT [FK_NotificationDeliveryLog_Notification]
GO
ALTER TABLE [dbo].[NotificationDeliveryLog]  WITH CHECK ADD  CONSTRAINT [FK_NotificationDeliveryLog_Outbox] FOREIGN KEY([OutboxID])
REFERENCES [dbo].[NotificationOutbox] ([OutboxID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[NotificationDeliveryLog] CHECK CONSTRAINT [FK_NotificationDeliveryLog_Outbox]
GO
ALTER TABLE [dbo].[NotificationOutbox]  WITH CHECK ADD  CONSTRAINT [FK_NotificationOutbox_Notification] FOREIGN KEY([NotificationID])
REFERENCES [dbo].[Notifications] ([NotificationID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[NotificationOutbox] CHECK CONSTRAINT [FK_NotificationOutbox_Notification]
GO
ALTER TABLE [dbo].[NotificationOutbox]  WITH CHECK ADD  CONSTRAINT [FK_NotificationOutbox_User] FOREIGN KEY([UserID])
REFERENCES [dbo].[Users] ([UserID])
GO
ALTER TABLE [dbo].[NotificationOutbox] CHECK CONSTRAINT [FK_NotificationOutbox_User]
GO
ALTER TABLE [dbo].[Notifications]  WITH CHECK ADD FOREIGN KEY([EventID])
REFERENCES [dbo].[Events] ([EventID])
ON DELETE SET NULL
GO
ALTER TABLE [dbo].[Notifications]  WITH CHECK ADD FOREIGN KEY([NotificationTypeID])
REFERENCES [dbo].[NotificationType] ([TypeID])
GO
ALTER TABLE [dbo].[Notifications]  WITH CHECK ADD FOREIGN KEY([UserID])
REFERENCES [dbo].[Users] ([UserID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PasswordResetOtps]  WITH CHECK ADD  CONSTRAINT [FK_PasswordResetOtps_Users_UserID] FOREIGN KEY([UserID])
REFERENCES [dbo].[Users] ([UserID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PasswordResetOtps] CHECK CONSTRAINT [FK_PasswordResetOtps_Users_UserID]
GO
ALTER TABLE [dbo].[PasswordResetSessions]  WITH CHECK ADD  CONSTRAINT [FK_PasswordResetSessions_Users_UserID] FOREIGN KEY([UserID])
REFERENCES [dbo].[Users] ([UserID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PasswordResetSessions] CHECK CONSTRAINT [FK_PasswordResetSessions_Users_UserID]
GO
ALTER TABLE [dbo].[PasswordResetTokens]  WITH CHECK ADD  CONSTRAINT [FK_PasswordResetTokens_Users] FOREIGN KEY([UserID])
REFERENCES [dbo].[Users] ([UserID])
GO
ALTER TABLE [dbo].[PasswordResetTokens] CHECK CONSTRAINT [FK_PasswordResetTokens_Users]
GO
ALTER TABLE [dbo].[SystemSettings]  WITH CHECK ADD FOREIGN KEY([UpdatedBy])
REFERENCES [dbo].[Users] ([UserID])
GO
ALTER TABLE [dbo].[Units]  WITH CHECK ADD FOREIGN KEY([InstituteID])
REFERENCES [dbo].[Institutes] ([InstituteID])
GO
ALTER TABLE [dbo].[Units]  WITH CHECK ADD FOREIGN KEY([ParentUnitID])
REFERENCES [dbo].[Units] ([UnitID])
GO
ALTER TABLE [dbo].[UserDeviceTokens]  WITH CHECK ADD  CONSTRAINT [FK_UserDeviceTokens_Users_UserID] FOREIGN KEY([UserID])
REFERENCES [dbo].[Users] ([UserID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[UserDeviceTokens] CHECK CONSTRAINT [FK_UserDeviceTokens_Users_UserID]
GO
ALTER TABLE [dbo].[UserNotificationPreferences]  WITH CHECK ADD  CONSTRAINT [FK_UserNotificationPreferences_NotificationType] FOREIGN KEY([NotificationTypeID])
REFERENCES [dbo].[NotificationType] ([TypeID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[UserNotificationPreferences] CHECK CONSTRAINT [FK_UserNotificationPreferences_NotificationType]
GO
ALTER TABLE [dbo].[UserNotificationPreferences]  WITH CHECK ADD  CONSTRAINT [FK_UserNotificationPreferences_Users_UserID] FOREIGN KEY([UserID])
REFERENCES [dbo].[Users] ([UserID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[UserNotificationPreferences] CHECK CONSTRAINT [FK_UserNotificationPreferences_Users_UserID]
GO
ALTER TABLE [dbo].[UserRoles]  WITH CHECK ADD FOREIGN KEY([RoleID])
REFERENCES [dbo].[Roles] ([RoleID])
GO
ALTER TABLE [dbo].[UserRoles]  WITH CHECK ADD FOREIGN KEY([UserID])
REFERENCES [dbo].[Users] ([UserID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[UserUnits]  WITH CHECK ADD FOREIGN KEY([UnitID])
REFERENCES [dbo].[Units] ([UnitID])
GO
ALTER TABLE [dbo].[UserUnits]  WITH CHECK ADD FOREIGN KEY([UserID])
REFERENCES [dbo].[Users] ([UserID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[EventQRCodes]  WITH CHECK ADD CHECK  (([ValidUntil]>[ValidFrom]))
GO
ALTER TABLE [dbo].[Events]  WITH CHECK ADD CHECK  (([EndTime]>[StartTime]))
GO
ALTER TABLE [dbo].[Events]  WITH CHECK ADD CHECK  (([MaxParticipants] IS NULL OR [MaxParticipants]>(0)))
GO
ALTER TABLE [dbo].[UserNotificationPreferences]  WITH CHECK ADD  CONSTRAINT [CK_UserNotificationPreferences_QuietHoursPair] CHECK  (([QuietHoursStartMinute] IS NULL AND [QuietHoursEndMinute] IS NULL OR [QuietHoursStartMinute] IS NOT NULL AND [QuietHoursEndMinute] IS NOT NULL))
GO
ALTER TABLE [dbo].[UserNotificationPreferences] CHECK CONSTRAINT [CK_UserNotificationPreferences_QuietHoursPair]
GO
ALTER TABLE [dbo].[UserNotificationPreferences]  WITH CHECK ADD  CONSTRAINT [CK_UserNotificationPreferences_QuietHoursRange] CHECK  ((([QuietHoursStartMinute] IS NULL OR [QuietHoursStartMinute]>=(0) AND [QuietHoursStartMinute]<=(1439)) AND ([QuietHoursEndMinute] IS NULL OR [QuietHoursEndMinute]>=(0) AND [QuietHoursEndMinute]<=(1439))))
GO
ALTER TABLE [dbo].[UserNotificationPreferences] CHECK CONSTRAINT [CK_UserNotificationPreferences_QuietHoursRange]
GO
USE [master]
GO
ALTER DATABASE [UniYouth] SET  READ_WRITE 
GO


