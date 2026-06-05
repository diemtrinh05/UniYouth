IF COL_LENGTH('dbo.FaceRecognitionLogs', 'VerificationStatus') IS NULL
BEGIN
    ALTER TABLE dbo.FaceRecognitionLogs
    ADD VerificationStatus NVARCHAR(30) NULL;
END;
GO

IF COL_LENGTH('dbo.FaceRecognitionLogs', 'Provider') IS NULL
BEGIN
    ALTER TABLE dbo.FaceRecognitionLogs
    ADD Provider NVARCHAR(50) NULL;
END;
GO

IF COL_LENGTH('dbo.FaceRecognitionLogs', 'Model') IS NULL
BEGIN
    ALTER TABLE dbo.FaceRecognitionLogs
    ADD Model NVARCHAR(50) NULL;
END;
GO

IF COL_LENGTH('dbo.FaceRecognitionLogs', 'ErrorCode') IS NULL
BEGIN
    ALTER TABLE dbo.FaceRecognitionLogs
    ADD ErrorCode NVARCHAR(50) NULL;
END;
GO

IF EXISTS
(
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.FaceRecognitionLogs')
      AND name = N'FaceProfileID'
      AND is_nullable = 0
)
BEGIN
    ALTER TABLE dbo.FaceRecognitionLogs
    ALTER COLUMN FaceProfileID INT NULL;
END;
GO

IF EXISTS
(
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.FaceRecognitionLogs')
      AND name = N'SimilarityScore'
      AND is_nullable = 0
)
BEGIN
    ALTER TABLE dbo.FaceRecognitionLogs
    ALTER COLUMN SimilarityScore FLOAT NULL;
END;
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'UX_FaceProfiles_UserID_Active'
      AND object_id = OBJECT_ID(N'dbo.FaceProfiles')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UX_FaceProfiles_UserID_Active
        ON dbo.FaceProfiles (UserID)
        WHERE IsActive = 1;
END;
GO
