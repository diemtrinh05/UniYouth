IF COL_LENGTH(N'dbo.Notifications', N'Audience') IS NULL
BEGIN
    ALTER TABLE [dbo].[Notifications]
        ADD [Audience] NVARCHAR(30) NULL;
END
GO

IF COL_LENGTH(N'dbo.Notifications', N'TargetRole') IS NULL
BEGIN
    ALTER TABLE [dbo].[Notifications]
        ADD [TargetRole] NVARCHAR(50) NULL;
END
GO
