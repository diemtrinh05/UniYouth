/*
  Seed dữ liệu sự kiện demo từ 18/05/2026 đến 01/06/2026.

  Nội dung tạo/cập nhật:
  - 15 sự kiện, mỗi ngày 1 sự kiện.
  - Mỗi sự kiện có 1 mã QR active, thời gian hiệu lực nằm trong thời gian diễn ra sự kiện.
  - Mỗi sự kiện có cấu hình điểm Participant.
  - Tất cả sự kiện tắt xác thực khuôn mặt.
  - Vị trí được lấy từ bản ghi LocationPresets đang active đầu tiên; nếu chưa có preset thì dùng tọa độ fallback.

  Ghi chú:
  - Script idempotent theo EventName và QRToken; chạy lại sẽ cập nhật dữ liệu seed thay vì tạo trùng.
  - Status = 1 tương ứng EventStatus.Open.
*/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;

DECLARE @Seed TABLE
(
    RowNo INT IDENTITY(1,1) PRIMARY KEY,
    EventName NVARCHAR(200) NOT NULL,
    Description NVARCHAR(MAX) NULL,
    StartTime DATETIME NOT NULL,
    EndTime DATETIME NOT NULL,
    RegistrationDeadline DATETIME NOT NULL,
    EventTypeName NVARCHAR(100) NOT NULL,
    MaxParticipants INT NOT NULL,
    ParticipantPoints INT NOT NULL,
    QRToken NVARCHAR(255) NOT NULL,
    QRValidFrom DATETIME NOT NULL,
    QRValidUntil DATETIME NOT NULL
);

INSERT INTO @Seed
(
    EventName,
    Description,
    StartTime,
    EndTime,
    RegistrationDeadline,
    EventTypeName,
    MaxParticipants,
    ParticipantPoints,
    QRToken,
    QRValidFrom,
    QRValidUntil
)
VALUES
(N'[DEMO 2026-05] Workshop kỹ năng số', N'Sự kiện demo phục vụ kiểm thử đăng ký, QR và điểm danh.', '2026-05-18T13:00:00', '2026-05-18T18:00:00', '2026-05-18T12:59:00', N'Hội thảo', 120, 10, N'DEMO-QR-20260518-WORKSHOP-KY-NANG-SO', '2026-05-18T13:00:00', '2026-05-18T18:00:00'),
(N'[DEMO 2026-05] Sinh hoạt chuyên đề chuyển đổi số', N'Sự kiện demo phục vụ kiểm thử đăng ký, QR và điểm danh.', '2026-05-19T08:00:00', '2026-05-19T11:30:00', '2026-05-18T23:59:00', N'Hội thảo', 100, 8, N'DEMO-QR-20260519-SINH-HOAT-CHUYEN-DE', '2026-05-19T08:00:00', '2026-05-19T11:30:00'),
(N'[DEMO 2026-05] Tập huấn cán bộ Đoàn Hội', N'Sự kiện demo phục vụ kiểm thử đăng ký, QR và điểm danh.', '2026-05-20T14:00:00', '2026-05-20T17:00:00', '2026-05-19T23:59:00', N'Hội thảo', 80, 10, N'DEMO-QR-20260520-TAP-HUAN-CAN-BO', '2026-05-20T14:00:00', '2026-05-20T17:00:00'),
(N'[DEMO 2026-05] Giao lưu văn nghệ sinh viên', N'Sự kiện demo phục vụ kiểm thử đăng ký, QR và điểm danh.', '2026-05-21T18:00:00', '2026-05-21T20:30:00', '2026-05-20T23:59:00', N'Văn hóa', 150, 7, N'DEMO-QR-20260521-GIAO-LUU-VAN-NGHE', '2026-05-21T18:00:00', '2026-05-21T20:30:00'),
(N'[DEMO 2026-05] Ngày chủ nhật xanh', N'Sự kiện demo phục vụ kiểm thử đăng ký, QR và điểm danh.', '2026-05-22T07:30:00', '2026-05-22T10:30:00', '2026-05-21T23:59:00', N'Tình nguyện', 200, 12, N'DEMO-QR-20260522-NGAY-CHU-NHAT-XANH', '2026-05-22T07:30:00', '2026-05-22T10:30:00'),
(N'[DEMO 2026-05] Tư vấn học thuật và nghề nghiệp', N'Sự kiện demo phục vụ kiểm thử đăng ký, QR và điểm danh.', '2026-05-23T13:30:00', '2026-05-23T16:30:00', '2026-05-22T23:59:00', N'Hội thảo', 90, 8, N'DEMO-QR-20260523-TU-VAN-HOC-THUAT', '2026-05-23T13:30:00', '2026-05-23T16:30:00'),
(N'[DEMO 2026-05] Tối kết nối tân sinh viên', N'Sự kiện demo buổi tối phục vụ kiểm thử đăng ký, QR và điểm danh.', '2026-05-18T18:30:00', '2026-05-18T20:30:00', '2026-05-18T18:00:00', N'Văn hóa', 160, 7, N'DEMO-QR-20260518-TOI-KET-NOI-TAN-SINH-VIEN', '2026-05-18T18:30:00', '2026-05-18T20:30:00'),
(N'[DEMO 2026-05] Talkshow kỹ năng học đại học', N'Sự kiện demo buổi tối phục vụ kiểm thử đăng ký, QR và điểm danh.', '2026-05-19T18:30:00', '2026-05-19T20:30:00', '2026-05-19T18:00:00', N'Hội thảo', 120, 8, N'DEMO-QR-20260519-TALKSHOW-KY-NANG-HOC', '2026-05-19T18:30:00', '2026-05-19T20:30:00'),
(N'[DEMO 2026-05] Hoạt động qua đêm Phú Tân 2', N'Sự kiện demo diễn ra qua đêm phục vụ kiểm thử QR, GPS và điểm danh.', '2026-05-19T19:00:00', '2026-05-20T07:00:00', '2026-05-19T18:59:00', N'Tình nguyện', 120, 12, N'DEMO-QR-20260519-HOAT-DONG-QUA-DEM-PHU-TAN-2', '2026-05-19T19:00:00', '2026-05-20T07:00:00'),
(N'[DEMO 2026-05] Đêm sinh hoạt câu lạc bộ', N'Sự kiện demo buổi tối phục vụ kiểm thử đăng ký, QR và điểm danh.', '2026-05-22T18:30:00', '2026-05-22T20:30:00', '2026-05-22T18:00:00', N'Văn hóa', 140, 7, N'DEMO-QR-20260522-DEM-SINH-HOAT-CLB', '2026-05-22T18:30:00', '2026-05-22T20:30:00'),
(N'[DEMO 2026-05] Workshop định hướng nghề nghiệp buổi tối', N'Sự kiện demo buổi tối phục vụ kiểm thử đăng ký, QR và điểm danh.', '2026-05-23T18:30:00', '2026-05-23T20:30:00', '2026-05-23T18:00:00', N'Hội thảo', 130, 8, N'DEMO-QR-20260523-WORKSHOP-NGHE-NGHIEP-TOI', '2026-05-23T18:30:00', '2026-05-23T20:30:00'),
(N'[DEMO 2026-05] Giải chạy sinh viên UniYouth', N'Sự kiện demo phục vụ kiểm thử đăng ký, QR và điểm danh.', '2026-05-24T08:00:00', '2026-05-24T11:00:00', '2026-05-23T23:59:00', N'Thể thao', 250, 10, N'DEMO-QR-20260524-GIAI-CHAY-SINH-VIEN', '2026-05-24T08:00:00', '2026-05-24T11:00:00'),
(N'[DEMO 2026-05] Workshop thiết kế CV', N'Sự kiện demo phục vụ kiểm thử đăng ký, QR và điểm danh.', '2026-05-25T15:00:00', '2026-05-25T18:00:00', '2026-05-24T23:59:00', N'Hội thảo', 110, 8, N'DEMO-QR-20260525-WORKSHOP-THIET-KE-CV', '2026-05-25T15:00:00', '2026-05-25T18:00:00'),
(N'[DEMO 2026-05] Đêm hội sinh viên công nghệ', N'Sự kiện demo phục vụ kiểm thử đăng ký, QR và điểm danh.', '2026-05-26T18:00:00', '2026-05-26T20:00:00', '2026-05-25T23:59:00', N'Văn hóa', 180, 7, N'DEMO-QR-20260526-DEM-HOI-SINH-VIEN', '2026-05-26T18:00:00', '2026-05-26T20:00:00'),
(N'[DEMO 2026-05] Tọa đàm nghiên cứu khoa học', N'Sự kiện demo phục vụ kiểm thử đăng ký, QR và điểm danh.', '2026-05-27T09:00:00', '2026-05-27T11:30:00', '2026-05-26T23:59:00', N'Hội thảo', 100, 8, N'DEMO-QR-20260527-TOA-DAM-NCKH', '2026-05-27T09:00:00', '2026-05-27T11:30:00'),
(N'[DEMO 2026-05] Tập huấn truyền thông số', N'Sự kiện demo phục vụ kiểm thử đăng ký, QR và điểm danh.', '2026-05-28T13:00:00', '2026-05-28T16:00:00', '2026-05-27T23:59:00', N'Hội thảo', 90, 10, N'DEMO-QR-20260528-TAP-HUAN-TRUYEN-THONG', '2026-05-28T13:00:00', '2026-05-28T16:00:00'),
(N'[DEMO 2026-05] Hoạt động tình nguyện cộng đồng', N'Sự kiện demo phục vụ kiểm thử đăng ký, QR và điểm danh.', '2026-05-29T07:30:00', '2026-05-29T10:30:00', '2026-05-28T23:59:00', N'Tình nguyện', 200, 12, N'DEMO-QR-20260529-TINH-NGUYEN-CONG-DONG', '2026-05-29T07:30:00', '2026-05-29T10:30:00'),
(N'[DEMO 2026-05] Chung kết thể thao sinh viên', N'Sự kiện demo phục vụ kiểm thử đăng ký, QR và điểm danh.', '2026-05-30T18:00:00', '2026-05-30T21:00:00', '2026-05-29T23:59:00', N'Thể thao', 220, 10, N'DEMO-QR-20260530-CHUNG-KET-THE-THAO', '2026-05-30T18:00:00', '2026-05-30T21:00:00'),
(N'[DEMO 2026-05] Hội nghị tổng kết hoạt động tháng 5', N'Sự kiện demo phục vụ kiểm thử đăng ký, QR và điểm danh.', '2026-05-31T08:00:00', '2026-05-31T11:00:00', '2026-05-30T23:59:00', N'Hội thảo', 120, 8, N'DEMO-QR-20260531-HOI-NGHI-TONG-KET', '2026-05-31T08:00:00', '2026-05-31T11:00:00'),
(N'[DEMO 2026-06] Khởi động hoạt động tháng 6', N'Sự kiện demo phục vụ kiểm thử đăng ký, QR và điểm danh.', '2026-06-01T13:00:00', '2026-06-01T18:00:00', '2026-06-01T12:59:00', N'Hội thảo', 120, 10, N'DEMO-QR-20260601-KHOI-DONG-THANG-6', '2026-06-01T13:00:00', '2026-06-01T18:00:00');

DECLARE
    @CreatedBy INT,
    @InstituteID INT,
    @DefaultEventTypeID INT,
    @LocationName NVARCHAR(200),
    @Latitude DECIMAL(10, 6),
    @Longitude DECIMAL(10, 6),
    @AllowRadius INT;

DECLARE @CustomEventLocations TABLE
(
    EventName NVARCHAR(200) NOT NULL PRIMARY KEY,
    LocationName NVARCHAR(200) NOT NULL,
    Latitude DECIMAL(10, 6) NOT NULL,
    Longitude DECIMAL(10, 6) NOT NULL,
    AllowRadius INT NOT NULL
);

INSERT INTO @CustomEventLocations
(
    EventName,
    LocationName,
    Latitude,
    Longitude,
    AllowRadius
)
VALUES
(
    N'[DEMO 2026-05] Hoạt động qua đêm Phú Tân 2',
    N'Đường số 73, Phú Tân 2, Phường Bình Dương, Thành phố Tân Uyên, Thành phố Hồ Chí Minh, Việt Nam',
    11.052114,
    106.710353,
    100
);

SELECT TOP (1) @CreatedBy = UserID
FROM dbo.Users
WHERE Status = 1
ORDER BY CASE WHEN Code = N'ADMIN001' THEN 0 ELSE 1 END, UserID;

IF @CreatedBy IS NULL
BEGIN
    THROW 51000, N'Không tìm thấy user active để gán CreatedBy cho dữ liệu sự kiện.', 1;
END;

SELECT TOP (1) @InstituteID = InstituteID
FROM dbo.Institutes
WHERE Status = 1
ORDER BY InstituteID;

IF @InstituteID IS NULL
BEGIN
    THROW 51001, N'Không tìm thấy Institute active để gán InstituteID cho dữ liệu sự kiện.', 1;
END;

SELECT TOP (1) @DefaultEventTypeID = TypeID
FROM dbo.EventType
ORDER BY TypeID;

IF @DefaultEventTypeID IS NULL
BEGIN
    THROW 51002, N'Không tìm thấy EventType để gán EventTypeID cho dữ liệu sự kiện.', 1;
END;

SELECT TOP (1)
    @LocationName = [Name],
    @Latitude = Latitude,
    @Longitude = Longitude,
    @AllowRadius = ISNULL(RadiusMeters, 100)
FROM dbo.LocationPresets
WHERE IsActive = 1
ORDER BY LocationPresetID;

IF @LocationName IS NULL
BEGIN
    SET @LocationName = N'TDMU - Viện Công nghệ số';
    SET @Latitude = 11.065890;
    SET @Longitude = 106.702950;
    SET @AllowRadius = 100;
END;

DECLARE
    @RowNo INT = 1,
    @MaxRowNo INT,
    @EventID INT,
    @EventName NVARCHAR(200),
    @Description NVARCHAR(MAX),
    @StartTime DATETIME,
    @EndTime DATETIME,
    @RegistrationDeadline DATETIME,
    @EventTypeName NVARCHAR(100),
    @EventTypeID INT,
    @MaxParticipants INT,
    @ParticipantPoints INT,
    @QRToken NVARCHAR(255),
    @QRValidFrom DATETIME,
    @QRValidUntil DATETIME,
    @EffectiveLocationName NVARCHAR(200),
    @EffectiveLatitude DECIMAL(10, 6),
    @EffectiveLongitude DECIMAL(10, 6),
    @EffectiveAllowRadius INT;

SELECT @MaxRowNo = MAX(RowNo) FROM @Seed;

WHILE @RowNo <= @MaxRowNo
BEGIN
    SELECT
        @EventName = EventName,
        @Description = Description,
        @StartTime = StartTime,
        @EndTime = EndTime,
        @RegistrationDeadline = RegistrationDeadline,
        @EventTypeName = EventTypeName,
        @MaxParticipants = MaxParticipants,
        @ParticipantPoints = ParticipantPoints,
        @QRToken = QRToken,
        @QRValidFrom = QRValidFrom,
        @QRValidUntil = QRValidUntil
    FROM @Seed
    WHERE RowNo = @RowNo;

    SELECT TOP (1) @EventTypeID = TypeID
    FROM dbo.EventType
    WHERE TypeName = @EventTypeName
    ORDER BY TypeID;

    SET @EventTypeID = ISNULL(@EventTypeID, @DefaultEventTypeID);
    SET @EffectiveLocationName = @LocationName;
    SET @EffectiveLatitude = @Latitude;
    SET @EffectiveLongitude = @Longitude;
    SET @EffectiveAllowRadius = @AllowRadius;

    SELECT
        @EffectiveLocationName = LocationName,
        @EffectiveLatitude = Latitude,
        @EffectiveLongitude = Longitude,
        @EffectiveAllowRadius = AllowRadius
    FROM @CustomEventLocations
    WHERE EventName = @EventName;

    SELECT TOP (1) @EventID = EventID
    FROM dbo.Events
    WHERE EventName = @EventName
    ORDER BY EventID DESC;

    IF @EventID IS NULL
    BEGIN
        INSERT INTO dbo.Events
        (
            EventName,
            [Description],
            StartTime,
            EndTime,
            LocationName,
            Latitude,
            Longitude,
            AllowRadius,
            MaxParticipants,
            CurrentParticipants,
            CreatedBy,
            EventTypeID,
            InstituteID,
            [Status],
            EnableFaceVerification,
            RegistrationDeadline,
            CreatedDate,
            UpdatedDate
        )
        VALUES
        (
            @EventName,
            @Description,
            @StartTime,
            @EndTime,
            @EffectiveLocationName,
            @EffectiveLatitude,
            @EffectiveLongitude,
            @EffectiveAllowRadius,
            @MaxParticipants,
            0,
            @CreatedBy,
            @EventTypeID,
            @InstituteID,
            1,
            0,
            @RegistrationDeadline,
            GETDATE(),
            GETDATE()
        );

        SET @EventID = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        UPDATE dbo.Events
        SET
            [Description] = @Description,
            StartTime = @StartTime,
            EndTime = @EndTime,
            LocationName = @EffectiveLocationName,
            Latitude = @EffectiveLatitude,
            Longitude = @EffectiveLongitude,
            AllowRadius = @EffectiveAllowRadius,
            MaxParticipants = @MaxParticipants,
            CreatedBy = @CreatedBy,
            EventTypeID = @EventTypeID,
            InstituteID = @InstituteID,
            [Status] = 1,
            EnableFaceVerification = 0,
            RegistrationDeadline = @RegistrationDeadline,
            UpdatedDate = GETDATE()
        WHERE EventID = @EventID;
    END;

    UPDATE dbo.EventQRCodes
    SET IsActive = 0,
        UpdatedDate = GETDATE()
    WHERE EventID = @EventID
      AND IsActive = 1
      AND QRToken <> @QRToken;

    IF EXISTS (SELECT 1 FROM dbo.EventQRCodes WHERE QRToken = @QRToken)
    BEGIN
        UPDATE dbo.EventQRCodes
        SET
            EventID = @EventID,
            ValidFrom = @QRValidFrom,
            ValidUntil = @QRValidUntil,
            IsActive = 1,
            ScanLimit = NULL,
            CreatedBy = @CreatedBy,
            UpdatedDate = GETDATE()
        WHERE QRToken = @QRToken;
    END
    ELSE
    BEGIN
        INSERT INTO dbo.EventQRCodes
        (
            EventID,
            QRToken,
            ValidFrom,
            ValidUntil,
            IsActive,
            ScanLimit,
            CurrentScans,
            CreatedBy,
            CreatedDate,
            UpdatedDate
        )
        VALUES
        (
            @EventID,
            @QRToken,
            @QRValidFrom,
            @QRValidUntil,
            1,
            NULL,
            0,
            @CreatedBy,
            GETDATE(),
            GETDATE()
        );
    END;

    IF EXISTS (SELECT 1 FROM dbo.EventPoints WHERE EventID = @EventID AND RoleType = N'Participant')
    BEGIN
        UPDATE dbo.EventPoints
        SET
            Points = @ParticipantPoints,
            [Description] = N'Điểm danh tham gia'
        WHERE EventID = @EventID
          AND RoleType = N'Participant';
    END
    ELSE
    BEGIN
        INSERT INTO dbo.EventPoints
        (
            EventID,
            RoleType,
            Points,
            [Description],
            CreatedDate
        )
        VALUES
        (
            @EventID,
            N'Participant',
            @ParticipantPoints,
            N'Điểm danh tham gia',
            GETDATE()
        );
    END;

    SET @EventID = NULL;
    SET @EventTypeID = NULL;
    SET @RowNo += 1;
END;

COMMIT TRANSACTION;

SELECT
    e.EventID,
    e.EventName,
    e.StartTime,
    e.EndTime,
    e.RegistrationDeadline,
    e.LocationName,
    e.Latitude,
    e.Longitude,
    e.AllowRadius,
    e.EnableFaceVerification,
    qr.QRToken,
    qr.ValidFrom AS QRValidFrom,
    qr.ValidUntil AS QRValidUntil,
    ep.Points AS ParticipantPoints
FROM dbo.Events e
LEFT JOIN dbo.EventQRCodes qr
    ON qr.EventID = e.EventID
   AND qr.IsActive = 1
LEFT JOIN dbo.EventPoints ep
    ON ep.EventID = e.EventID
   AND ep.RoleType = N'Participant'
WHERE e.EventName LIKE N'[[]DEMO 2026-05]%'
   OR e.EventName LIKE N'[[]DEMO 2026-06]%'
ORDER BY e.StartTime;
