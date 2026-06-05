IF OBJECT_ID(N'dbo.Positions', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Positions
    (
        PositionID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Positions PRIMARY KEY,
        PositionCode NVARCHAR(50) NOT NULL,
        PositionName NVARCHAR(100) NOT NULL,
        UnitID INT NOT NULL,
        IsActive TINYINT NOT NULL CONSTRAINT DF_Positions_IsActive DEFAULT (1),
        SortOrder INT NOT NULL CONSTRAINT DF_Positions_SortOrder DEFAULT (0),
        CreatedDate DATETIME NOT NULL CONSTRAINT DF_Positions_CreatedDate DEFAULT (GETDATE()),
        UpdatedDate DATETIME NOT NULL CONSTRAINT DF_Positions_UpdatedDate DEFAULT (GETDATE()),
        CONSTRAINT FK_Positions_Units FOREIGN KEY (UnitID) REFERENCES dbo.Units(UnitID),
        CONSTRAINT UQ_Positions_PositionCode UNIQUE (PositionCode),
        CONSTRAINT UQ_Positions_UnitID_PositionName UNIQUE (UnitID, PositionName)
    );
END;
GO

IF COL_LENGTH('dbo.UserUnits', 'PositionID') IS NULL
BEGIN
    ALTER TABLE dbo.UserUnits
    ADD PositionID INT NULL;
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_UserUnits_Positions')
BEGIN
    ALTER TABLE dbo.UserUnits
    ADD CONSTRAINT FK_UserUnits_Positions
        FOREIGN KEY (PositionID) REFERENCES dbo.Positions(PositionID);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_UserUnits_PositionID' AND object_id = OBJECT_ID(N'dbo.UserUnits'))
BEGIN
    CREATE INDEX IX_UserUnits_PositionID ON dbo.UserUnits(PositionID);
END;
GO

DECLARE @ChiDoanUnitID INT =
(
    SELECT TOP 1 UnitID
    FROM dbo.Units
    WHERE UnitName = N'Chi Đoàn Viện Công Nghệ Số'
);

DECLARE @ChiHoiUnitID INT =
(
    SELECT TOP 1 UnitID
    FROM dbo.Units
    WHERE UnitName = N'Chi Hội Viện Công Nghệ Số'
);

IF @ChiDoanUnitID IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo.Positions WHERE PositionCode = N'BI_THU')
    BEGIN
        INSERT INTO dbo.Positions (PositionCode, PositionName, UnitID, SortOrder)
        VALUES (N'BI_THU', N'Bí thư', @ChiDoanUnitID, 10);
    END;

    IF NOT EXISTS (SELECT 1 FROM dbo.Positions WHERE PositionCode = N'DOAN_VIEN')
    BEGIN
        INSERT INTO dbo.Positions (PositionCode, PositionName, UnitID, SortOrder)
        VALUES (N'DOAN_VIEN', N'Đoàn viên', @ChiDoanUnitID, 20);
    END;
END;

IF @ChiHoiUnitID IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo.Positions WHERE PositionCode = N'HOI_VIEN')
    BEGIN
        INSERT INTO dbo.Positions (PositionCode, PositionName, UnitID, SortOrder)
        VALUES (N'HOI_VIEN', N'Hội viên', @ChiHoiUnitID, 30);
    END;
END;
GO

UPDATE userUnit
SET userUnit.PositionID = position.PositionID
FROM dbo.UserUnits userUnit
INNER JOIN dbo.Positions position
    ON position.UnitID = userUnit.UnitID
   AND position.PositionName = userUnit.Position
WHERE userUnit.PositionID IS NULL
  AND userUnit.Position IS NOT NULL;
GO
