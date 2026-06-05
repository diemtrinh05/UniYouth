IF OBJECT_ID(N'dbo.RefreshTokens', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.RefreshTokens
    (
        RefreshTokenID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_RefreshTokens PRIMARY KEY,
        UserID INT NOT NULL,
        TokenHash VARCHAR(128) NOT NULL,
        ExpiresAt DATETIME NOT NULL,
        LastUsedAt DATETIME NULL,
        RevokedAt DATETIME NULL,
        ReplacedByTokenHash VARCHAR(128) NULL,
        CreatedByIp VARCHAR(64) NULL,
        CreatedByUserAgent NVARCHAR(512) NULL,
        RevokedByIp VARCHAR(64) NULL,
        RevokedByUserAgent NVARCHAR(512) NULL,
        RevokedReason NVARCHAR(255) NULL,
        CreatedDate DATETIME NOT NULL CONSTRAINT DF_RefreshTokens_CreatedDate DEFAULT (GETDATE()),
        UpdatedDate DATETIME NOT NULL CONSTRAINT DF_RefreshTokens_UpdatedDate DEFAULT (GETDATE())
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_RefreshTokens_TokenHash' AND object_id = OBJECT_ID(N'dbo.RefreshTokens'))
BEGIN
    CREATE UNIQUE INDEX UQ_RefreshTokens_TokenHash
        ON dbo.RefreshTokens(TokenHash);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_RefreshTokens_UserID_RevokedAt_ExpiresAt' AND object_id = OBJECT_ID(N'dbo.RefreshTokens'))
BEGIN
    CREATE INDEX IX_RefreshTokens_UserID_RevokedAt_ExpiresAt
        ON dbo.RefreshTokens(UserID, RevokedAt, ExpiresAt);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_RefreshTokens_Users_UserID')
BEGIN
    ALTER TABLE dbo.RefreshTokens
    ADD CONSTRAINT FK_RefreshTokens_Users_UserID
        FOREIGN KEY (UserID) REFERENCES dbo.Users(UserID) ON DELETE CASCADE;
END
GO
