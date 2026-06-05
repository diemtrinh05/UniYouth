IF OBJECT_ID(N'dbo.PasswordResetOtps', N'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[PasswordResetOtps]
    (
        [OtpID] INT IDENTITY(1,1) NOT NULL CONSTRAINT [PK_PasswordResetOtps] PRIMARY KEY,
        [UserID] INT NOT NULL,
        [OtpHash] NVARCHAR(200) NOT NULL,
        [Purpose] NVARCHAR(50) NOT NULL,
        [ExpiresAt] DATETIME NOT NULL,
        [AttemptCount] INT NOT NULL CONSTRAINT [DF_PasswordResetOtps_AttemptCount] DEFAULT (0),
        [MaxAttempts] INT NOT NULL CONSTRAINT [DF_PasswordResetOtps_MaxAttempts] DEFAULT (5),
        [ResendCount] INT NOT NULL CONSTRAINT [DF_PasswordResetOtps_ResendCount] DEFAULT (0),
        [MaxResends] INT NOT NULL CONSTRAINT [DF_PasswordResetOtps_MaxResends] DEFAULT (3),
        [IsUsed] BIT NOT NULL CONSTRAINT [DF_PasswordResetOtps_IsUsed] DEFAULT (0),
        [VerifiedAt] DATETIME NULL,
        [UsedAt] DATETIME NULL,
        [RevokedAt] DATETIME NULL,
        [CreatedDate] DATETIME NOT NULL CONSTRAINT [DF_PasswordResetOtps_CreatedDate] DEFAULT (GETDATE()),
        [LastSentAt] DATETIME NOT NULL CONSTRAINT [DF_PasswordResetOtps_LastSentAt] DEFAULT (GETDATE()),
        [RequestIp] NVARCHAR(64) NULL,
        [RequestUserAgent] NVARCHAR(512) NULL
    );

    ALTER TABLE [dbo].[PasswordResetOtps] WITH CHECK
        ADD CONSTRAINT [FK_PasswordResetOtps_Users_UserID]
        FOREIGN KEY([UserID]) REFERENCES [dbo].[Users]([UserID])
        ON DELETE CASCADE;
END

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_PasswordResetOtps_UserID_Purpose_CreatedDate'
      AND object_id = OBJECT_ID(N'dbo.PasswordResetOtps')
)
BEGIN
    CREATE INDEX [IX_PasswordResetOtps_UserID_Purpose_CreatedDate]
        ON [dbo].[PasswordResetOtps] ([UserID], [Purpose], [CreatedDate]);
END

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_PasswordResetOtps_UserID_IsUsed_ExpiresAt'
      AND object_id = OBJECT_ID(N'dbo.PasswordResetOtps')
)
BEGIN
    CREATE INDEX [IX_PasswordResetOtps_UserID_IsUsed_ExpiresAt]
        ON [dbo].[PasswordResetOtps] ([UserID], [IsUsed], [ExpiresAt]);
END

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_PasswordResetOtps_ExpiresAt'
      AND object_id = OBJECT_ID(N'dbo.PasswordResetOtps')
)
BEGIN
    CREATE INDEX [IX_PasswordResetOtps_ExpiresAt]
        ON [dbo].[PasswordResetOtps] ([ExpiresAt]);
END
