/*
Mục tiêu:
- Tối ưu truy vấn list events khi chỉ cần lấy thumbnail/banner.
- Query pattern: WHERE EventID = ? AND ImageType IN ('Thumbnail','Banner') ORDER BY DisplayOrder

SQL Server:
- Tạo nonclustered index theo (EventID, ImageType, DisplayOrder) và INCLUDE ImageUrl.
*/

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_EventImages_EventID_ImageType_DisplayOrder'
      AND object_id = OBJECT_ID(N'dbo.EventImages')
)
BEGIN
    CREATE INDEX [IX_EventImages_EventID_ImageType_DisplayOrder]
        ON [dbo].[EventImages] ([EventID], [ImageType], [DisplayOrder])
        INCLUDE ([ImageUrl]);
END

