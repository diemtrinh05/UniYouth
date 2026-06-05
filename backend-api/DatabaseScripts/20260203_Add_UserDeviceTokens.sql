IF OBJECT_ID(N'dbo.UserDeviceTokens', N'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[UserDeviceTokens]
    (
        [UserDeviceTokenID] INT IDENTITY(1,1) NOT NULL CONSTRAINT [PK_UserDeviceTokens] PRIMARY KEY,
        [UserID] INT NOT NULL,
        [Platform] NVARCHAR(20) NOT NULL,
        [Token] NVARCHAR(512) NOT NULL,
        [DeviceId] NVARCHAR(100) NULL,
        [IsActive] BIT NOT NULL CONSTRAINT [DF_UserDeviceTokens_IsActive] DEFAULT (1),
        [LastSeenAt] DATETIME NOT NULL CONSTRAINT [DF_UserDeviceTokens_LastSeenAt] DEFAULT (GETDATE()),
        [CreatedDate] DATETIME NOT NULL CONSTRAINT [DF_UserDeviceTokens_CreatedDate] DEFAULT (GETDATE()),
        [UpdatedDate] DATETIME NOT NULL CONSTRAINT [DF_UserDeviceTokens_UpdatedDate] DEFAULT (GETDATE())
    );

    ALTER TABLE [dbo].[UserDeviceTokens] WITH CHECK
        ADD CONSTRAINT [FK_UserDeviceTokens_Users_UserID]
        FOREIGN KEY([UserID]) REFERENCES [dbo].[Users]([UserID])
        ON DELETE CASCADE;
END

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'UQ_UserDeviceTokens_Platform_Token'
      AND object_id = OBJECT_ID(N'dbo.UserDeviceTokens')
)
BEGIN
    CREATE UNIQUE INDEX [UQ_UserDeviceTokens_Platform_Token]
        ON [dbo].[UserDeviceTokens] ([Platform], [Token]);
END

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_UserDeviceTokens_UserID_IsActive'
      AND object_id = OBJECT_ID(N'dbo.UserDeviceTokens')
)
BEGIN
    CREATE INDEX [IX_UserDeviceTokens_UserID_IsActive]
        ON [dbo].[UserDeviceTokens] ([UserID], [IsActive]);
END

