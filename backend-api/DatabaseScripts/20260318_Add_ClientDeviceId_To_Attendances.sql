IF COL_LENGTH('dbo.Attendances', 'ClientDeviceId') IS NULL
BEGIN
    ALTER TABLE dbo.Attendances
    ADD ClientDeviceId NVARCHAR(128) NULL;
END
