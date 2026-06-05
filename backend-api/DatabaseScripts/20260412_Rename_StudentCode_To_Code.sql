/*
Rename Users.StudentCode -> Users.Code and align related indexes.
Run once per database.
*/
SET XACT_ABORT ON;
BEGIN TRAN;

IF COL_LENGTH('dbo.Users', 'StudentCode') IS NOT NULL AND COL_LENGTH('dbo.Users', 'Code') IS NULL
BEGIN
    EXEC sp_rename 'dbo.Users.StudentCode', 'Code', 'COLUMN';
END;

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Users_StudentCode' AND object_id = OBJECT_ID('dbo.Users'))
BEGIN
    EXEC sp_rename 'dbo.Users.IX_Users_StudentCode', 'IX_Users_Code', 'INDEX';
END;

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Users_Code' AND object_id = OBJECT_ID('dbo.Users'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Users_Code] ON [dbo].[Users]([Code] ASC);
END;

COMMIT TRAN;
