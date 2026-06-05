/*
    Add PasswordResetTokens table for Forgot Password feature.
    Notes:
    - Token column is intended to store a HASH of the token (recommended), not the raw token.
    - Raw token is only sent to user via email.
*/

IF OBJECT_ID(N'dbo.PasswordResetTokens', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.PasswordResetTokens
    (
        Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_PasswordResetTokens PRIMARY KEY,
        UserID INT NOT NULL,
        Token NVARCHAR(200) NOT NULL,
        ExpiredAt DATETIME NOT NULL,
        IsUsed BIT NOT NULL CONSTRAINT DF_PasswordResetTokens_IsUsed DEFAULT (0),
        CreatedDate DATETIME NOT NULL CONSTRAINT DF_PasswordResetTokens_CreatedDate DEFAULT (GETDATE()),
        CONSTRAINT FK_PasswordResetTokens_Users FOREIGN KEY (UserID) REFERENCES dbo.Users(UserID)
    );

    CREATE UNIQUE INDEX UX_PasswordResetTokens_Token ON dbo.PasswordResetTokens(Token);
    CREATE INDEX IX_PasswordResetTokens_UserID ON dbo.PasswordResetTokens(UserID);
END
GO

