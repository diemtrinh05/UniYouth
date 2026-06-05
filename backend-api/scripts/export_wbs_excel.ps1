$ErrorActionPreference = "Stop"

function ColLetter([int]$n) {
  $s = ""
  while ($n -gt 0) {
    $m = ($n - 1) % 26
    $s = [char](65 + $m) + $s
    $n = [math]::Floor(($n - 1) / 26)
  }
  return $s
}

function XEsc([string]$s) {
  if ($null -eq $s) { return "" }
  return [System.Security.SecurityElement]::Escape($s)
}

$headers = @(
  "STT","MÃ CÔNG VIỆC","TÊN CÔNG VIỆC","MO","ML","MP",
  "EST tạm (làm tròn 2 số lẻ)","LOẠI DỰ ÁN","MÔI TRƯỜNG",
  "HỆ SỐ DỰ ÁN","SỐ NĂM KINH NGHIỆM","HỆ SỐ KINH NGHIỆM","Tổng EST","ĐVT"
)

$rows = @(
  @(1, "1.1", "Khảo sát và SRS", 3, 5, 8),
  @(2, "1.2", "Thiết kế Database (ERD)", 3, 5, 8),
  @(3, "1.3", "Thiết kế UI/UX", 4, 7, 11),
  @(4, "1.4", "Thiết kế Kiến trúc (Solution Design)", 4, 7, 10),
  @(5, "1.5", "Setup Dev Environment (Config)", 2, 4, 6),
  @(6, "2.1", "Phân công nhiệm vụ", 1, 2, 3),
  @(7, "2.2", "Theo dõi tiến độ", 2, 4, 6),
  @(8, "2.3", "Quản lý rủi ro", 2, 3, 5),
  @(9, "2.4", "Quản lý ngân sách", 2, 3, 5),
  @(10, "2.5", "Giao tiếp và báo cáo nhóm", 2, 4, 6),
  @(11, "2.6", "Quản lý tài liệu dự án", 2, 3, 5),
  @(12, "2.7", "Đánh giá và phản hồi", 2, 3, 5),
  @(13, "3.1", "Đăng nhập/Đăng xuất (JWT)", 3, 5, 8),
  @(14, "3.2", "Quản lý Roles/Permissions", 4, 7, 10),
  @(15, "3.3", "Quản lý Menu/Navigation", 3, 5, 8),
  @(16, "3.4", "Audit Log (Lịch sử hệ thống)", 3, 6, 9),
  @(17, "3.5", "Cấu hình hệ thống (Settings)", 3, 5, 8),
  @(18, "4.1", "CRUD Thông tin Đoàn viên", 4, 7, 11),
  @(19, "4.2", "Chức năng Import Excel", 3, 6, 10),
  @(20, "4.3", "Chức năng Export Danh sách", 2, 4, 6),
  @(21, "4.4", "Chuyển sinh hoạt đoàn", 3, 5, 8),
  @(22, "4.5", "Quản lý Trưởng đoàn chấm điểm", 4, 7, 10),
  @(23, "4.6", "Thống kê số lượng đoàn viên", 2, 4, 7),
  @(24, "5.1", "CRUD Sự kiện/Hoạt động", 5, 8, 12),
  @(25, "5.2", "Duyệt đăng ký tham gia", 3, 5, 8),
  @(26, "5.3", "Tạo mã QR Check-in", 3, 5, 9),
  @(27, "5.4", "API Check-in (Mobile/Web)", 5, 9, 14),
  @(28, "5.5", "Xử lý điểm danh tự động", 4, 8, 13),
  @(29, "5.6", "Thống kê tham gia sự kiện", 3, 5, 8),
  @(30, "6.1", "Cấu hình tiêu chí chấm điểm (Jobs)", 4, 7, 11),
  @(31, "6.2", "Tự động tính điểm (Job)", 5, 9, 14),
  @(32, "6.3", "Chấm điểm/Cập nhật tự động", 4, 7, 12),
  @(33, "6.4", "Xếp loại đoàn viên", 3, 6, 10),
  @(34, "6.5", "Xuất phiếu đánh giá", 3, 5, 8),
  @(36, "7.1", "Thống kê danh sách điểm danh", 2, 4, 7),
  @(37, "7.2", "Thống kê danh sách sự kiện", 2, 4, 7),
  @(38, "7.3", "Báo cáo Tổng hợp (Dashboard)", 4, 7, 11),
  @(39, "7.4", "Báo cáo chi tiết (PDF/Excel)", 4, 7, 12),
  @(40, "8.1", "Unit Testing (Core Logic)", 3, 6, 9),
  @(41, "8.2", "Integration Testing (API)", 4, 7, 11),
  @(42, "8.3", "UAT (User Acceptance Test)", 3, 5, 8),
  @(43, "8.4", "Deploy Staging/Production", 2, 4, 7),
  @(44, "8.5", "Tài liệu HDSD và Bàn giao", 2, 4, 6)
)

$tmpRoot = Join-Path (Get-Location) ".tmp_wbs_xlsx"
if (Test-Path $tmpRoot) { Remove-Item $tmpRoot -Recurse -Force }

New-Item -Path $tmpRoot -ItemType Directory | Out-Null
New-Item -Path (Join-Path $tmpRoot "_rels") -ItemType Directory | Out-Null
New-Item -Path (Join-Path $tmpRoot "xl") -ItemType Directory | Out-Null
New-Item -Path (Join-Path $tmpRoot "xl\_rels") -ItemType Directory | Out-Null
New-Item -Path (Join-Path $tmpRoot "xl\worksheets") -ItemType Directory | Out-Null

$contentTypes = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
  <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
</Types>
'@

$rels = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>
'@

$workbook = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <sheets>
    <sheet name="WBS Ước lượng" sheetId="1" r:id="rId1"/>
  </sheets>
</workbook>
'@

$workbookRels = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>
'@

$styles = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <fonts count="1"><font><sz val="11"/><name val="Calibri"/></font></fonts>
  <fills count="1"><fill><patternFill patternType="none"/></fill></fills>
  <borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>
  <cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
  <cellXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/></cellXfs>
  <cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>
</styleSheet>
'@

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
[void]$sb.AppendLine('<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">')
[void]$sb.AppendLine('  <sheetData>')

[void]$sb.AppendLine('    <row r="1">')
for ($c = 1; $c -le $headers.Count; $c++) {
  $ref = "$(ColLetter $c)1"
  $val = XEsc $headers[$c - 1]
  [void]$sb.AppendLine("      <c r=`"$ref`" t=`"inlineStr`"><is><t>$val</t></is></c>")
}
[void]$sb.AppendLine('    </row>')

foreach ($item in $rows) {
  $idx = [int]$item[0]
  $r = $idx + 1
  [void]$sb.AppendLine("    <row r=`"$r`">")
  [void]$sb.AppendLine("      <c r=`"A$r`"><v>$($item[0])</v></c>")
  [void]$sb.AppendLine("      <c r=`"B$r`" t=`"inlineStr`"><is><t>$(XEsc $item[1])</t></is></c>")
  [void]$sb.AppendLine("      <c r=`"C$r`" t=`"inlineStr`"><is><t>$(XEsc $item[2])</t></is></c>")
  [void]$sb.AppendLine("      <c r=`"D$r`"><v>$($item[3])</v></c>")
  [void]$sb.AppendLine("      <c r=`"E$r`"><v>$($item[4])</v></c>")
  [void]$sb.AppendLine("      <c r=`"F$r`"><v>$($item[5])</v></c>")
  [void]$sb.AppendLine("      <c r=`"G$r`"><f>ROUND((D$r+4*E$r+F$r)/6,2)</f></c>")
  [void]$sb.AppendLine("      <c r=`"H$r`" t=`"inlineStr`"><is><t>Mới</t></is></c>")
  [void]$sb.AppendLine("      <c r=`"I$r`" t=`"inlineStr`"><is><t>Mới</t></is></c>")
  [void]$sb.AppendLine("      <c r=`"J$r`"><f>IF(AND(H$r=""Cũ"",I$r=""Cũ""),1,IF(OR(AND(H$r=""Cũ"",I$r=""Mới""),AND(H$r=""Mới"",I$r=""Cũ"")),1.4,IF(AND(H$r=""Mới"",I$r=""Mới""),2,"""")))</f></c>")
  [void]$sb.AppendLine("      <c r=`"K$r`"><v>2</v></c>")
  [void]$sb.AppendLine("      <c r=`"L$r`"><f>IF(K$r=10,0.5,IF(K$r=8,0.6,IF(K$r=6,0.8,IF(K$r=4,1,IF(K$r=2,1.4,IF(K$r=1,2.6,""""))))))</f></c>")
  [void]$sb.AppendLine("      <c r=`"M$r`"><f>ROUND(G$r*(J$r+L$r-1),2)</f></c>")
  [void]$sb.AppendLine("      <c r=`"N$r`" t=`"inlineStr`"><is><t>Ngày công</t></is></c>")
  [void]$sb.AppendLine("    </row>")
}

$lastDataRow = $rows.Count + 1
$totalRow = $lastDataRow + 1
[void]$sb.AppendLine("    <row r=`"$totalRow`">")
[void]$sb.AppendLine("      <c r=`"L$totalRow`" t=`"inlineStr`"><is><t>Tổng cộng</t></is></c>")
[void]$sb.AppendLine("      <c r=`"M$totalRow`"><f>ROUND(SUM(M2:M$lastDataRow),2)</f></c>")
[void]$sb.AppendLine("      <c r=`"N$totalRow`" t=`"inlineStr`"><is><t>Ngày công</t></is></c>")
[void]$sb.AppendLine("    </row>")

[void]$sb.AppendLine("  </sheetData>")
[void]$sb.AppendLine("</worksheet>")
$sheetXml = $sb.ToString()

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText((Join-Path $tmpRoot "[Content_Types].xml"), $contentTypes, $utf8NoBom)
[System.IO.File]::WriteAllText((Join-Path $tmpRoot "_rels\.rels"), $rels, $utf8NoBom)
[System.IO.File]::WriteAllText((Join-Path $tmpRoot "xl\workbook.xml"), $workbook, $utf8NoBom)
[System.IO.File]::WriteAllText((Join-Path $tmpRoot "xl\_rels\workbook.xml.rels"), $workbookRels, $utf8NoBom)
[System.IO.File]::WriteAllText((Join-Path $tmpRoot "xl\styles.xml"), $styles, $utf8NoBom)
[System.IO.File]::WriteAllText((Join-Path $tmpRoot "xl\worksheets\sheet1.xml"), $sheetXml, $utf8NoBom)

$outPath = Join-Path (Get-Location) "WBS_UOC_LUONG_NGAY_CONG.xlsx"
$zipPath = Join-Path (Get-Location) "WBS_UOC_LUONG_NGAY_CONG.zip"

if (Test-Path $outPath) { Remove-Item $outPath -Force }
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

Compress-Archive -Path (Join-Path $tmpRoot "*") -DestinationPath $zipPath -Force
Move-Item -Path $zipPath -Destination $outPath -Force
Remove-Item -Path $tmpRoot -Recurse -Force

Write-Output $outPath
