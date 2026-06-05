IF COL_LENGTH(N'dbo.Attendances', N'FaceRetryCount') IS NULL
BEGIN
    ALTER TABLE dbo.Attendances
    ADD FaceRetryCount INT NOT NULL
        CONSTRAINT DF_Attendances_FaceRetryCount DEFAULT (0);
END
GO
