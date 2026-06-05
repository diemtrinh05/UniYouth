param(
    [Parameter(Mandatory = $true)]
    [string]$InputFile,

    [string]$OutputJson = ".\calibration-summary.json",

    [string]$OutputMarkdown = ".\calibration-report.generated.md"
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path -Parent $scriptDir
$pythonExe = Join-Path $rootDir ".python\python.exe"
$toolPath = Join-Path $scriptDir "calibrate_thresholds.py"

& $pythonExe $toolPath `
  --input-file $InputFile `
  --output-json $OutputJson `
  --output-markdown $OutputMarkdown
