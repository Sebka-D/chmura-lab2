# Otwiera adres w nowym oknie Edge (świeży, tymczasowy profil) i robi zrzut całego ekranu z paskiem adresu.
# Użycie: powershell -File scripts/zrzut.ps1 -Url <adres> -Out <plik.png> [-Wait 6]
param([string]$Url, [string]$Out, [int]$Wait = 6)
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
Add-Type @"
using System; using System.Runtime.InteropServices;
public class W {
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
}
"@
[W]::SetProcessDPIAware() | Out-Null
$tag  = "edge-lab2-" + (Get-Random)
$prof = Join-Path $env:TEMP $tag
Start-Process "msedge.exe" -ArgumentList "--user-data-dir=$prof", "--no-first-run", "--no-default-browser-check",
  "--lang=pl", "--disable-features=Translate,TranslateUI,msEdgeTranslate", "--new-window", "--start-maximized", $Url | Out-Null

function Get-LabProcs { Get-CimInstance Win32_Process -Filter "Name='msedge.exe'" | Where-Object { $_.CommandLine -like "*$tag*" } }
$win = $null
for ($i = 0; $i -lt 30 -and -not $win; $i++) {
  Start-Sleep -Milliseconds 500
  $ids = (Get-LabProcs).ProcessId
  $win = Get-Process -Id $ids -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
}
Start-Sleep -Seconds $Wait
if ($win) { [W]::ShowWindow($win.MainWindowHandle, 3) | Out-Null; [W]::SetForegroundWindow($win.MainWindowHandle) | Out-Null }
Start-Sleep -Milliseconds 800
[System.Windows.Forms.SendKeys]::SendWait("{ESC}")
Start-Sleep -Milliseconds 800

$b = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$bmp = New-Object System.Drawing.Bitmap $b.Width, $b.Height
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($b.Location, [System.Drawing.Point]::Empty, $b.Size)
$bmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()

if ($win) { $win.CloseMainWindow() | Out-Null; Start-Sleep -Seconds 2 }
Get-LabProcs | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
Start-Sleep -Milliseconds 500
Remove-Item $prof -Recurse -Force -ErrorAction SilentlyContinue
"zapisano $Out"
