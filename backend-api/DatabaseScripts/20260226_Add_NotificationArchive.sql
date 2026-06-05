IF OBJECT_ID(N'dbo.NotificationArchive', N'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[NotificationArchive]
    (
        [NotificationID] INT NOT NULL,
        [UserID] INT NOT NULL,
        [EventID] INT NULL,
        [Title] NVARCHAR(200) NOT NULL,
        [Content] NVARCHAR(MAX) NOT NULL,
        [NotificationTypeID] INT NOT NULL,
        [Priority] TINYINT NULL,
        [IsRead] BIT NULL,
        [ReadDate] DATETIME NULL,
        [ActionUrl] NVARCHAR(255) NULL,
        [DedupKey] NVARCHAR(200) NULL,
        [Audience] NVARCHAR(30) NULL,
        [TargetRole] NVARCHAR(50) NULL,
        [CreatedDate] DATETIME NULL,
        [ExpiryDate] DATETIME NULL,
        [ArchivedDate] DATETIME NOT NULL
            CONSTRAINT [DF_NotificationArchive_ArchivedDate] DEFAULT (GETDATE()),
        [ArchiveReason] NVARCHAR(255) NULL,
        CONSTRAINT [PK_NotificationArchive] PRIMARY KEY CLUSTERED ([NotificationID] ASC)
    );
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_NotificationArchive_UserID'
      AND object_id = OBJECT_ID(N'dbo.NotificationArchive')
)
BEGIN
    CREATE NONCLUSTERED INDEX [IX_NotificationArchive_UserID]
        ON [dbo].[NotificationArchive] ([UserID]);
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_NotificationArchive_CreatedDate'
      AND object_id = OBJECT_ID(N'dbo.NotificationArchive')
)
BEGIN
    CREATE NONCLUSTERED INDEX [IX_NotificationArchive_CreatedDate]
        ON [dbo].[NotificationArchive] ([CreatedDate]);
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_NotificationArchive_ArchivedDate'
      AND object_id = OBJECT_ID(N'dbo.NotificationArchive')
)
BEGIN
    CREATE NONCLUSTERED INDEX [IX_NotificationArchive_ArchivedDate]
        ON [dbo].[NotificationArchive] ([ArchivedDate]);
END
GO
