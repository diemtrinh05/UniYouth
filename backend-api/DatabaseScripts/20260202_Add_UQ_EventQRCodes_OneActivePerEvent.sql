/*
Mục tiêu:
- Đảm bảo mỗi Event chỉ có tối đa 1 QR đang active tại một thời điểm.
- Chống race condition khi có nhiều request tạo QR đồng thời.

SQL Server:
- Dùng filtered unique index theo EventID, chỉ áp dụng khi IsActive = 1.
*/

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'UQ_EventQRCodes_Active_EventID'
      AND object_id = OBJECT_ID(N'dbo.EventQRCodes')
)
BEGIN
    CREATE UNIQUE INDEX [UQ_EventQRCodes_Active_EventID]
        ON [dbo].[EventQRCodes] ([EventID])
        WHERE [IsActive] = 1;
END

