/*
  Location Presets (vị trí cố định) cho Web Admin khi tạo/cập nhật sự kiện.
  - Hỗ trợ chọn nhanh các vị trí chuẩn: "Hội trường A", "Phòng học B", ...
  - Có thể giới hạn theo Institute/Unit (nullable).
  - Dùng thêm RadiusMeters để phục vụ check-in GPS (nếu có).
*/

IF OBJECT_ID(N'dbo.LocationPresets', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.LocationPresets
    (
        LocationPresetID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_LocationPresets PRIMARY KEY,
        [Name] NVARCHAR(200) NOT NULL,
        [Address] NVARCHAR(500) NULL,
        Latitude DECIMAL(10,6) NOT NULL,
        Longitude DECIMAL(10,6) NOT NULL,
        RadiusMeters INT NULL,
        InstituteID INT NULL,
        UnitID INT NULL,
        IsActive BIT NOT NULL CONSTRAINT DF_LocationPresets_IsActive DEFAULT (1),
        CreatedBy INT NULL,
        CreatedDate DATETIME NOT NULL CONSTRAINT DF_LocationPresets_CreatedDate DEFAULT (GETDATE()),
        UpdatedDate DATETIME NOT NULL CONSTRAINT DF_LocationPresets_UpdatedDate DEFAULT (GETDATE())
    );

    -- FK (tuỳ chọn). Không cascade delete để tránh mất dữ liệu preset khi xoá viện/đơn vị.
    ALTER TABLE dbo.LocationPresets WITH CHECK
        ADD CONSTRAINT FK_LocationPresets_Institutes
        FOREIGN KEY (InstituteID) REFERENCES dbo.Institutes(InstituteID);

    ALTER TABLE dbo.LocationPresets WITH CHECK
        ADD CONSTRAINT FK_LocationPresets_Units
        FOREIGN KEY (UnitID) REFERENCES dbo.Units(UnitID);

    ALTER TABLE dbo.LocationPresets WITH CHECK
        ADD CONSTRAINT FK_LocationPresets_Users
        FOREIGN KEY (CreatedBy) REFERENCES dbo.Users(UserID);

    CREATE INDEX IX_LocationPresets_IsActive ON dbo.LocationPresets(IsActive);
    CREATE INDEX IX_LocationPresets_InstituteID ON dbo.LocationPresets(InstituteID);
    CREATE INDEX IX_LocationPresets_UnitID ON dbo.LocationPresets(UnitID);
    CREATE INDEX IX_LocationPresets_Name ON dbo.LocationPresets([Name]);
END

