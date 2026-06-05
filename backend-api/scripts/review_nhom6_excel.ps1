$ErrorActionPreference = "Stop"

$src = Join-Path (Get-Location) "Bang_uoc_luong_ngay_cong_Nhom6 (2).xlsx"
$tmp = Join-Path (Get-Location) ".tmp_check_nhom6"
$zip = Join-Path (Get-Location) ".tmp_check_nhom6.zip"

if (Test-Path $tmp) {
  Remove-Item $tmp -Recurse -Force
}
if (Test-Path $zip) {
  Remove-Item $zip -Force
}

Copy-Item -Path $src -Destination $zip -Force
Expand-Archive -Path $zip -DestinationPath $tmp -Force

Write-Output "=== SHEETS ==="
Get-ChildItem -Path (Join-Path $tmp "xl\worksheets") -File | Select-Object -ExpandProperty Name

Write-Output "=== WORKBOOK ==="
Get-Content -Path (Join-Path $tmp "xl\workbook.xml")

Write-Output "=== SHEET1 FORMULAS (first 120 matches) ==="
$sheet1 = Join-Path $tmp "xl\worksheets\sheet1.xml"
Select-String -Path $sheet1 -Pattern "<f>.*</f>" | Select-Object -First 120 | ForEach-Object { $_.Line }

Write-Output "=== SHEET1 KEYWORDS ==="
Select-String -Path $sheet1 -Pattern "Cũ|Mới|ROUND|SUM|IF\\(" | Select-Object -First 200 | ForEach-Object { $_.Line }

Write-Output "=== SHARED STRINGS (first 200 lines) ==="
$ss = Join-Path $tmp "xl\sharedStrings.xml"
if (Test-Path $ss) {
  Get-Content -Path $ss -TotalCount 200
} else {
  Write-Output "No sharedStrings.xml"
}
