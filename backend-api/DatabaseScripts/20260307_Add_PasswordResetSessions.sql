IF OBJECT_ID(N'dbo.PasswordResetSessions', N'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[PasswordResetSessions]
    (
        [ResetSessionID] INT IDENTITY(1,1) NOT NULL CONSTRAINT [PK_PasswordResetSessions] PRIMARY KEY,
        [UserID] INT NOT NULL,
        [OtpID] INT NOT NULL,
        [SessionTokenHash] NVARCHAR(200) NOT NULL,
        [ExpiresAt] DATETIME NOT NULL,
        [IsUsed] BIT NOT NULL CONSTRAINT [DF_PasswordResetSessions_IsUsed] DEFAULT (0),
        [CreatedDate] DATETIME NOT NULL CONSTRAINT [DF_PasswordResetSessions_CreatedDate] DEFAULT (GETDATE()),
        [UsedAt] DATETIME NULL
    );

    ALTER TABLE [dbo].[PasswordResetSessions] WITH CHECK
        ADD CONSTRAINT [FK_PasswordResetSessions_Users_UserID]
        FOREIGN KEY([UserID]) REFERENCES [dbo].[Users]([UserID])
        ON DELETE CASCADE;

    ALTER TABLE [dbo].[PasswordResetSessions] WITH CHECK
        ADD CONSTRAINT [FK_PasswordResetSessions_PasswordResetOtps_OtpID]
        FOREIGN KEY([OtpID]) REFERENCES [dbo].[PasswordResetOtps]([OtpID])
        ON DELETE CASCADE;
END

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'UQ_PasswordResetSessions_SessionTokenHash'
      AND object_id = OBJECT_ID(N'dbo.PasswordResetSessions')
)
BEGIN
    CREATE UNIQUE INDEX [UQ_PasswordResetSessions_SessionTokenHash]
        ON [dbo].[PasswordResetSessions] ([SessionTokenHash]);
END

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_PasswordResetSessions_UserID_ExpiresAt_IsUsed'
      AND object_id = OBJECT_ID(N'dbo.PasswordResetSessions')
)
BEGIN
    CREATE INDEX [IX_PasswordResetSessions_UserID_ExpiresAt_IsUsed]
        ON [dbo].[PasswordResetSessions] ([UserID], [ExpiresAt], [IsUsed]);
END

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_PasswordResetSessions_OtpID_IsUsed'
      AND object_id = OBJECT_ID(N'dbo.PasswordResetSessions')
)
BEGIN
    CREATE INDEX [IX_PasswordResetSessions_OtpID_IsUsed]
        ON [dbo].[PasswordResetSessions] ([OtpID], [IsUsed]);
END
