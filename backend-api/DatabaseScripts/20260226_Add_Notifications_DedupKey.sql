IF COL_LENGTH(N'dbo.Notifications', N'DedupKey') IS NULL
BEGIN
    ALTER TABLE [dbo].[Notifications]
        ADD [DedupKey] NVARCHAR(200) NULL;
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'UX_Notifications_DedupKey_NotNull'
      AND object_id = OBJECT_ID(N'dbo.Notifications')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX [UX_Notifications_DedupKey_NotNull]
        ON [dbo].[Notifications] ([DedupKey])
        WHERE [DedupKey] IS NOT NULL;
END
GO
