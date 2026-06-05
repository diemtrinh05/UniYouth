IF COL_LENGTH('dbo.Attendances', 'LivenessPassed') IS NULL
BEGIN
    ALTER TABLE dbo.Attendances
    ADD LivenessPassed BIT NULL;
END;
GO

IF COL_LENGTH('dbo.Attendances', 'LivenessScore') IS NULL
BEGIN
    ALTER TABLE dbo.Attendances
    ADD LivenessScore FLOAT NULL;
END;
GO

IF COL_LENGTH('dbo.Attendances', 'LivenessReason') IS NULL
BEGIN
    ALTER TABLE dbo.Attendances
    ADD LivenessReason NVARCHAR(255) NULL;
END;
GO
