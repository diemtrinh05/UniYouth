/*
Mục tiêu:
- Chống cộng điểm điểm danh trùng (race-condition safe) cho bảng ActivityPoints
- Mỗi (EventID, UserID) chỉ có tối đa 1 bản ghi PointType = 'Attendance'

SQL Server:
- Dùng filtered unique index để KHÔNG ảnh hưởng các PointType khác (Bonus/Penalty)
*/

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'UQ_ActivityPoints_Attendance_EventID_UserID'
      AND object_id = OBJECT_ID(N'dbo.ActivityPoints')
)
BEGIN
    CREATE UNIQUE INDEX [UQ_ActivityPoints_Attendance_EventID_UserID]
        ON [dbo].[ActivityPoints] ([EventID], [UserID])
        WHERE [PointType] = N'Attendance';
END
