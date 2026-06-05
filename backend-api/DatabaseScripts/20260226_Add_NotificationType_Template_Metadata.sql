IF COL_LENGTH(N'dbo.NotificationType', N'Locale') IS NULL
BEGIN
    ALTER TABLE [dbo].[NotificationType]
        ADD [Locale] NVARCHAR(10) NULL;
END
GO

IF COL_LENGTH(N'dbo.NotificationType', N'TemplateVersion') IS NULL
BEGIN
    ALTER TABLE [dbo].[NotificationType]
        ADD [TemplateVersion] INT NULL;
END
GO

UPDATE [dbo].[NotificationType]
SET [Locale] = N'vi-VN'
WHERE [Locale] IS NULL;
GO

UPDATE [dbo].[NotificationType]
SET [TemplateVersion] = 1
WHERE [TemplateVersion] IS NULL;
GO
