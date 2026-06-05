IF EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_Users_Code'
      AND object_id = OBJECT_ID(N'dbo.Users')
)
BEGIN
    DROP INDEX [IX_Users_Code] ON [dbo].[Users];
END;
GO

IF EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_Users_Email'
      AND object_id = OBJECT_ID(N'dbo.Users')
)
BEGIN
    DROP INDEX [IX_Users_Email] ON [dbo].[Users];
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_Users_FullName'
      AND object_id = OBJECT_ID(N'dbo.Users')
)
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Users_FullName]
        ON [dbo].[Users] ([FullName]);
END;
GO
