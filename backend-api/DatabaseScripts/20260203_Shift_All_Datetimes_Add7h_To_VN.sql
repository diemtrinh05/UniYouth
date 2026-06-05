/*
MIGRATION SCRIPT (RỦI RO CAO) — SHIFT TOÀN BỘ DATETIME SANG GIỜ VN (UTC+7)
========================================================================

Bạn đã xác nhận: chấp nhận rủi ro dữ liệu đã là VN sẽ bị cộng thêm +7 giờ.

⚠️ CẢNH BÁO QUAN TRỌNG:
- Script này sẽ cộng +7 giờ cho TẤT CẢ các cột kiểu datetime/datetime2/smalldatetime trong toàn DB.
- Nếu một phần dữ liệu đang là giờ VN, dữ liệu đó sẽ bị sai thêm +7 giờ.
- CHỈ chạy khi bạn đã có FULL BACKUP và hiểu rõ hậu quả.

Cách chạy an toàn:
1) Chạy script với @DoCommit = 0 để DRY-RUN (script sẽ ROLLBACK).
2) Kiểm tra dữ liệu (SELECT) ở các bảng quan trọng.
3) Đổi @DoCommit = 1 và chạy lại để COMMIT.
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @DoCommit BIT = 0; -- 0 = DRY-RUN (ROLLBACK), 1 = COMMIT

BEGIN TRY
    BEGIN TRAN;

    IF OBJECT_ID(N'dbo.__TimezoneShift_AllDateTimes_Log', N'U') IS NULL
    BEGIN
        CREATE TABLE dbo.__TimezoneShift_AllDateTimes_Log
        (
            LogId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK___TimezoneShift_AllDateTimes_Log PRIMARY KEY,
            StartedAt DATETIME NOT NULL CONSTRAINT DF___TimezoneShift_AllDateTimes_Log_StartedAt DEFAULT (GETDATE()),
            CompletedAt DATETIME NULL,
            DoCommit BIT NOT NULL,
            ShiftHours INT NOT NULL,
            Status NVARCHAR(20) NOT NULL,
            Note NVARCHAR(4000) NULL
        );
    END

    DECLARE @LogId INT;
    INSERT INTO dbo.__TimezoneShift_AllDateTimes_Log (DoCommit, ShiftHours, Status, Note)
    VALUES (@DoCommit, 7, N'Running', N'Shift all datetime/datetime2/smalldatetime by +7 hours');
    SET @LogId = SCOPE_IDENTITY();

    -- Lấy danh sách cột kiểu datetime/datetime2/smalldatetime (loại bỏ computed/identity)
    IF OBJECT_ID('tempdb..#Cols', 'U') IS NOT NULL DROP TABLE #Cols;
    CREATE TABLE #Cols
    (
        SchemaName SYSNAME NOT NULL,
        TableName SYSNAME NOT NULL,
        ColumnName SYSNAME NOT NULL
    );

    INSERT INTO #Cols (SchemaName, TableName, ColumnName)
    SELECT
        s.name AS SchemaName,
        t.name AS TableName,
        c.name AS ColumnName
    FROM sys.tables t
    INNER JOIN sys.schemas s ON s.schema_id = t.schema_id
    INNER JOIN sys.columns c ON c.object_id = t.object_id
    INNER JOIN sys.types ty ON ty.user_type_id = c.user_type_id
    WHERE
        t.is_ms_shipped = 0
        AND c.is_computed = 0
        AND c.is_identity = 0
        AND ty.name IN (N'datetime', N'datetime2', N'smalldatetime');

    IF NOT EXISTS (SELECT 1 FROM #Cols)
    BEGIN
        UPDATE dbo.__TimezoneShift_AllDateTimes_Log
        SET Status = N'NoOp', CompletedAt = GETDATE(), Note = N'Không tìm thấy cột datetime/datetime2/smalldatetime để shift.'
        WHERE LogId = @LogId;

        IF @DoCommit = 1 COMMIT;
        ELSE ROLLBACK;

        RETURN;
    END

    -- Tạo câu lệnh UPDATE theo từng table (SET col1=DATEADD..., col2=DATEADD...)
    IF OBJECT_ID('tempdb..#Stmt', 'U') IS NOT NULL DROP TABLE #Stmt;
    CREATE TABLE #Stmt
    (
        StmtId INT IDENTITY(1,1) NOT NULL,
        FullName NVARCHAR(512) NOT NULL,
        SqlText NVARCHAR(MAX) NOT NULL
    );

    ;WITH g AS
    (
        SELECT
            SchemaName,
            TableName,
            STRING_AGG(QUOTENAME(ColumnName) + N' = DATEADD(HOUR, 7, ' + QUOTENAME(ColumnName) + N')', N', ') AS SetClause
        FROM #Cols
        GROUP BY SchemaName, TableName
    )
    INSERT INTO #Stmt (FullName, SqlText)
    SELECT
        QUOTENAME(SchemaName) + N'.' + QUOTENAME(TableName) AS FullName,
        N'UPDATE ' + QUOTENAME(SchemaName) + N'.' + QUOTENAME(TableName) + N'
SET ' + SetClause + N';' AS SqlText
    FROM g;

    DECLARE @sql NVARCHAR(MAX);
    DECLARE @full NVARCHAR(512);
    DECLARE @stmtId INT;

    DECLARE c CURSOR LOCAL FAST_FORWARD FOR
        SELECT StmtId, FullName, SqlText FROM #Stmt ORDER BY StmtId;

    OPEN c;
    FETCH NEXT FROM c INTO @stmtId, @full, @sql;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT '--- [' + CAST(@stmtId AS NVARCHAR(20)) + '] ' + @full;
        EXEC sp_executesql @sql;

        FETCH NEXT FROM c INTO @stmtId, @full, @sql;
    END

    CLOSE c;
    DEALLOCATE c;

    UPDATE dbo.__TimezoneShift_AllDateTimes_Log
    SET Status = N'Completed', CompletedAt = GETDATE()
    WHERE LogId = @LogId;

    IF @DoCommit = 1
    BEGIN
        COMMIT;
        PRINT 'DONE: COMMIT (đã shift toàn bộ cột datetime/datetime2/smalldatetime +7 giờ).';
    END
    ELSE
    BEGIN
        ROLLBACK;
        PRINT 'DONE: ROLLBACK (DRY-RUN). Đổi @DoCommit = 1 để commit.';
    END
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK;

    DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
    PRINT 'ERROR: ' + @Err;
    THROW;
END CATCH;

