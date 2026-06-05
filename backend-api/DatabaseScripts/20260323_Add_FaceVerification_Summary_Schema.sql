IF COL_LENGTH('dbo.Events', 'EnableFaceVerification') IS NULL
BEGIN
    ALTER TABLE dbo.Events
    ADD EnableFaceVerification BIT NOT NULL
        CONSTRAINT DF_Events_EnableFaceVerification DEFAULT (0);
END;
GO

IF COL_LENGTH('dbo.Attendances', 'FaceVerificationStatus') IS NULL
BEGIN
    ALTER TABLE dbo.Attendances
    ADD FaceVerificationStatus NVARCHAR(30) NULL;
END;
GO

IF COL_LENGTH('dbo.Attendances', 'FaceVerificationReason') IS NULL
BEGIN
    ALTER TABLE dbo.Attendances
    ADD FaceVerificationReason NVARCHAR(255) NULL;
END;
GO

IF COL_LENGTH('dbo.Attendances', 'FaceVerificationProvider') IS NULL
BEGIN
    ALTER TABLE dbo.Attendances
    ADD FaceVerificationProvider NVARCHAR(50) NULL;
END;
GO

IF COL_LENGTH('dbo.Attendances', 'FaceVerificationVersion') IS NULL
BEGIN
    ALTER TABLE dbo.Attendances
    ADD FaceVerificationVersion NVARCHAR(50) NULL;
END;
GO

IF COL_LENGTH('dbo.Attendances', 'RiskScore') IS NULL
BEGIN
    ALTER TABLE dbo.Attendances
    ADD RiskScore INT NULL;
END;
GO

IF COL_LENGTH('dbo.Attendances', 'RiskLevel') IS NULL
BEGIN
    ALTER TABLE dbo.Attendances
    ADD RiskLevel NVARCHAR(20) NULL;
END;
GO

IF COL_LENGTH('dbo.Attendances', 'RiskReasonsJson') IS NULL
BEGIN
    ALTER TABLE dbo.Attendances
    ADD RiskReasonsJson NVARCHAR(MAX) NULL;
END;
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_Attendances_EventID_RiskLevel_FaceVerificationStatus'
      AND object_id = OBJECT_ID(N'dbo.Attendances')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_Attendances_EventID_RiskLevel_FaceVerificationStatus
        ON dbo.Attendances (EventID, RiskLevel, FaceVerificationStatus);
END;
GO
