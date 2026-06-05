IF EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE name = N'FK_LocationPresets_Units'
)
BEGIN
    ALTER TABLE dbo.LocationPresets DROP CONSTRAINT FK_LocationPresets_Units;
END
GO

IF EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_LocationPresets_UnitID'
      AND object_id = OBJECT_ID(N'dbo.LocationPresets')
)
BEGIN
    DROP INDEX IX_LocationPresets_UnitID ON dbo.LocationPresets;
END
GO

IF EXISTS (
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.LocationPresets')
      AND name = N'UnitID'
)
BEGIN
    ALTER TABLE dbo.LocationPresets DROP COLUMN UnitID;
END
GO
