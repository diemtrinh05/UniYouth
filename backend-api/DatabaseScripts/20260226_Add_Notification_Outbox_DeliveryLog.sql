IF OBJECT_ID(N'dbo.NotificationOutbox', N'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[NotificationOutbox]
    (
        [OutboxID] INT IDENTITY(1,1) NOT NULL,
        [NotificationID] INT NOT NULL,
        [UserID] INT NOT NULL,
        [Channel] TINYINT NOT NULL,
        [Status] TINYINT NOT NULL CONSTRAINT [DF_NotificationOutbox_Status] DEFAULT ((0)),
        [AttemptCount] INT NOT NULL CONSTRAINT [DF_NotificationOutbox_AttemptCount] DEFAULT ((0)),
        [MaxAttempts] INT NOT NULL CONSTRAINT [DF_NotificationOutbox_MaxAttempts] DEFAULT ((5)),
        [NextAttemptAt] DATETIME NOT NULL CONSTRAINT [DF_NotificationOutbox_NextAttemptAt] DEFAULT (GETDATE()),
        [LastAttemptAt] DATETIME NULL,
        [ProcessedAt] DATETIME NULL,
        [LastError] NVARCHAR(1000) NULL,
        [CreatedDate] DATETIME NOT NULL CONSTRAINT [DF_NotificationOutbox_CreatedDate] DEFAULT (GETDATE()),
        [UpdatedDate] DATETIME NOT NULL CONSTRAINT [DF_NotificationOutbox_UpdatedDate] DEFAULT (GETDATE()),
        CONSTRAINT [PK_NotificationOutbox] PRIMARY KEY CLUSTERED ([OutboxID] ASC),
        CONSTRAINT [FK_NotificationOutbox_Notification] FOREIGN KEY ([NotificationID]) REFERENCES [dbo].[Notifications]([NotificationID]) ON DELETE CASCADE,
        CONSTRAINT [FK_NotificationOutbox_User] FOREIGN KEY ([UserID]) REFERENCES [dbo].[Users]([UserID])
    );
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_NotificationOutbox_NotificationID'
      AND object_id = OBJECT_ID(N'dbo.NotificationOutbox')
)
BEGIN
    CREATE NONCLUSTERED INDEX [IX_NotificationOutbox_NotificationID]
        ON [dbo].[NotificationOutbox] ([NotificationID]);
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_NotificationOutbox_Status_NextAttemptAt'
      AND object_id = OBJECT_ID(N'dbo.NotificationOutbox')
)
BEGIN
    CREATE NONCLUSTERED INDEX [IX_NotificationOutbox_Status_NextAttemptAt]
        ON [dbo].[NotificationOutbox] ([Status], [NextAttemptAt]);
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_NotificationOutbox_UserID'
      AND object_id = OBJECT_ID(N'dbo.NotificationOutbox')
)
BEGIN
    CREATE NONCLUSTERED INDEX [IX_NotificationOutbox_UserID]
        ON [dbo].[NotificationOutbox] ([UserID]);
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'UX_NotificationOutbox_Notification_Channel'
      AND object_id = OBJECT_ID(N'dbo.NotificationOutbox')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX [UX_NotificationOutbox_Notification_Channel]
        ON [dbo].[NotificationOutbox] ([NotificationID], [Channel]);
END
GO

IF OBJECT_ID(N'dbo.NotificationDeliveryLog', N'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[NotificationDeliveryLog]
    (
        [DeliveryLogID] INT IDENTITY(1,1) NOT NULL,
        [OutboxID] INT NOT NULL,
        [NotificationID] INT NOT NULL,
        [UserID] INT NOT NULL,
        [Channel] TINYINT NOT NULL,
        [AttemptNumber] INT NOT NULL,
        [IsSuccess] BIT NOT NULL,
        [ErrorMessage] NVARCHAR(1000) NULL,
        [CreatedDate] DATETIME NOT NULL CONSTRAINT [DF_NotificationDeliveryLog_CreatedDate] DEFAULT (GETDATE()),
        CONSTRAINT [PK_NotificationDeliveryLog] PRIMARY KEY CLUSTERED ([DeliveryLogID] ASC),
        CONSTRAINT [FK_NotificationDeliveryLog_Outbox] FOREIGN KEY ([OutboxID]) REFERENCES [dbo].[NotificationOutbox]([OutboxID]) ON DELETE CASCADE,
        CONSTRAINT [FK_NotificationDeliveryLog_Notification] FOREIGN KEY ([NotificationID]) REFERENCES [dbo].[Notifications]([NotificationID])
    );
END
GO

IF OBJECT_ID(N'dbo.NotificationDeliveryLog', N'U') IS NOT NULL
BEGIN
    IF EXISTS (
        SELECT 1
        FROM sys.foreign_keys
        WHERE name = N'FK_NotificationDeliveryLog_Notification'
          AND parent_object_id = OBJECT_ID(N'dbo.NotificationDeliveryLog')
          AND delete_referential_action = 1 -- CASCADE
    )
    BEGIN
        ALTER TABLE [dbo].[NotificationDeliveryLog]
            DROP CONSTRAINT [FK_NotificationDeliveryLog_Notification];
    END

    IF NOT EXISTS (
        SELECT 1
        FROM sys.foreign_keys
        WHERE name = N'FK_NotificationDeliveryLog_Notification'
          AND parent_object_id = OBJECT_ID(N'dbo.NotificationDeliveryLog')
    )
    BEGIN
        ALTER TABLE [dbo].[NotificationDeliveryLog] WITH CHECK
            ADD CONSTRAINT [FK_NotificationDeliveryLog_Notification]
            FOREIGN KEY ([NotificationID]) REFERENCES [dbo].[Notifications]([NotificationID]);
    END
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_NotificationDeliveryLog_OutboxID'
      AND object_id = OBJECT_ID(N'dbo.NotificationDeliveryLog')
)
BEGIN
    CREATE NONCLUSTERED INDEX [IX_NotificationDeliveryLog_OutboxID]
        ON [dbo].[NotificationDeliveryLog] ([OutboxID]);
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_NotificationDeliveryLog_NotificationID'
      AND object_id = OBJECT_ID(N'dbo.NotificationDeliveryLog')
)
BEGIN
    CREATE NONCLUSTERED INDEX [IX_NotificationDeliveryLog_NotificationID]
        ON [dbo].[NotificationDeliveryLog] ([NotificationID]);
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_NotificationDeliveryLog_CreatedDate'
      AND object_id = OBJECT_ID(N'dbo.NotificationDeliveryLog')
)
BEGIN
    CREATE NONCLUSTERED INDEX [IX_NotificationDeliveryLog_CreatedDate]
        ON [dbo].[NotificationDeliveryLog] ([CreatedDate]);
END
GO
