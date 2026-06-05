IF OBJECT_ID(N'dbo.UserNotificationPreferences', N'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[UserNotificationPreferences]
    (
        [PreferenceID] INT IDENTITY(1,1) NOT NULL
            CONSTRAINT [PK_UserNotificationPreferences] PRIMARY KEY,
        [UserID] INT NOT NULL,
        [NotificationTypeID] INT NOT NULL,
        [IsInAppEnabled] BIT NOT NULL
            CONSTRAINT [DF_UserNotificationPreferences_IsInAppEnabled] DEFAULT ((1)),
        [IsRealtimeEnabled] BIT NOT NULL
            CONSTRAINT [DF_UserNotificationPreferences_IsRealtimeEnabled] DEFAULT ((1)),
        [IsPushEnabled] BIT NOT NULL
            CONSTRAINT [DF_UserNotificationPreferences_IsPushEnabled] DEFAULT ((1)),
        [IsMuted] BIT NOT NULL
            CONSTRAINT [DF_UserNotificationPreferences_IsMuted] DEFAULT ((0)),
        [QuietHoursStartMinute] SMALLINT NULL,
        [QuietHoursEndMinute] SMALLINT NULL,
        [CreatedDate] DATETIME NOT NULL
            CONSTRAINT [DF_UserNotificationPreferences_CreatedDate] DEFAULT (GETDATE()),
        [UpdatedDate] DATETIME NOT NULL
            CONSTRAINT [DF_UserNotificationPreferences_UpdatedDate] DEFAULT (GETDATE())
    );
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE name = N'FK_UserNotificationPreferences_Users_UserID'
      AND parent_object_id = OBJECT_ID(N'dbo.UserNotificationPreferences')
)
BEGIN
    ALTER TABLE [dbo].[UserNotificationPreferences] WITH CHECK
        ADD CONSTRAINT [FK_UserNotificationPreferences_Users_UserID]
        FOREIGN KEY ([UserID]) REFERENCES [dbo].[Users]([UserID])
        ON DELETE CASCADE;
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE name = N'FK_UserNotificationPreferences_NotificationType'
      AND parent_object_id = OBJECT_ID(N'dbo.UserNotificationPreferences')
)
BEGIN
    ALTER TABLE [dbo].[UserNotificationPreferences] WITH CHECK
        ADD CONSTRAINT [FK_UserNotificationPreferences_NotificationType]
        FOREIGN KEY ([NotificationTypeID]) REFERENCES [dbo].[NotificationType]([TypeID])
        ON DELETE CASCADE;
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'UQ_UserNotificationPreferences_UserID_NotificationTypeID'
      AND object_id = OBJECT_ID(N'dbo.UserNotificationPreferences')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_UserNotificationPreferences_UserID_NotificationTypeID]
        ON [dbo].[UserNotificationPreferences] ([UserID], [NotificationTypeID]);
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_UserNotificationPreferences_UserID'
      AND object_id = OBJECT_ID(N'dbo.UserNotificationPreferences')
)
BEGIN
    CREATE NONCLUSTERED INDEX [IX_UserNotificationPreferences_UserID]
        ON [dbo].[UserNotificationPreferences] ([UserID]);
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_UserNotificationPreferences_NotificationTypeID'
      AND object_id = OBJECT_ID(N'dbo.UserNotificationPreferences')
)
BEGIN
    CREATE NONCLUSTERED INDEX [IX_UserNotificationPreferences_NotificationTypeID]
        ON [dbo].[UserNotificationPreferences] ([NotificationTypeID]);
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.check_constraints
    WHERE name = N'CK_UserNotificationPreferences_QuietHoursPair'
      AND parent_object_id = OBJECT_ID(N'dbo.UserNotificationPreferences')
)
BEGIN
    ALTER TABLE [dbo].[UserNotificationPreferences]
        ADD CONSTRAINT [CK_UserNotificationPreferences_QuietHoursPair]
        CHECK (
            ([QuietHoursStartMinute] IS NULL AND [QuietHoursEndMinute] IS NULL)
            OR ([QuietHoursStartMinute] IS NOT NULL AND [QuietHoursEndMinute] IS NOT NULL)
        );
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.check_constraints
    WHERE name = N'CK_UserNotificationPreferences_QuietHoursRange'
      AND parent_object_id = OBJECT_ID(N'dbo.UserNotificationPreferences')
)
BEGIN
    ALTER TABLE [dbo].[UserNotificationPreferences]
        ADD CONSTRAINT [CK_UserNotificationPreferences_QuietHoursRange]
        CHECK (
            ([QuietHoursStartMinute] IS NULL OR [QuietHoursStartMinute] BETWEEN 0 AND 1439)
            AND ([QuietHoursEndMinute] IS NULL OR [QuietHoursEndMinute] BETWEEN 0 AND 1439)
        );
END
GO
