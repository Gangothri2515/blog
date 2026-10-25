<#
  Turns diagram sources into the PNGs that Medium needs.

  Medium accepts only JPG/PNG/GIF, so Mermaid and SVG cannot be used directly,
  and an image narrower than 1192px loses Medium's full-width placement
  options. This script renders every .mmd in a post's diagrams/ folder to both
  .svg and .png, and rasterises any hand-authored .svg alongside them.

  Usage:
    powershell -ExecutionPolicy Bypass -File tools\render-diagrams.ps1 -Post 001-work-that-cannot-be-parallelised

  Requires Chrome (or Edge) installed. No Node or npm needed.
#>
param(
  [Parameter(Mandatory = $true)][string]$Post,
  [string]$Only,
  [int]$MinWidth = 1400
)

# Chrome logs unrelated warnings to stderr; with Stop those would become fatal.
$ErrorActionPreference = "Continue"

$repo     = Split-Path $PSScriptRoot -Parent
$postDir  = Join-Path $repo "posts\$Post"
$diagrams = Join-Path $postDir "diagrams"
$assets   = Join-Path $postDir "assets"
$scratch  = Join-Path $repo ".render"
$host_    = Join-Path $PSScriptRoot "mermaid-host.html"

if (-not (Test-Path $diagrams)) { throw "No diagrams folder at $diagrams" }
New-Item -ItemType Directory -Force -Path $assets, $scratch | Out-Null

$chrome = @(
  "C:\Program Files\Google\Chrome\Application\chrome.exe",
  "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
  "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
  "C:\Program Files\Microsoft\Edge\Application\msedge.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $chrome) { throw "Neither Chrome nor Edge found." }

function ConvertTo-FileUrl([string]$p) { "file:///" + ($p -replace '\\', '/') }
function Write-Utf8([string]$p, [string]$s) {
  [System.IO.File]::WriteAllText($p, $s, (New-Object System.Text.UTF8Encoding $false))
}

# Rasterise an .svg at a scale that clears Medium's 1192px minimum.
function Export-Png([string]$svgPath, [string]$pngPath, [int]$w, [int]$h) {
  $scale = [math]::Max(2.0, [math]::Round($MinWidth / $w, 1))
  $cssW  = [int]($w * $scale)
  $cssH  = [int]($h * $scale)
  $wrap  = @"
<!doctype html><html><head><meta charset="utf-8"><style>
html,body{margin:0;padding:0;background:#fff}
img{display:block;width:${cssW}px;height:${cssH}px}
</style></head><body><img src="$(ConvertTo-FileUrl $svgPath)"></body></html>
"@
  $wrapPath = Join-Path $scratch ("wrap-" + [System.IO.Path]::GetFileNameWithoutExtension($svgPath) + ".html")
  Write-Utf8 $wrapPath $wrap

  & $chrome --headless --disable-gpu --hide-scrollbars --default-background-color=FFFFFFFF `
            --force-device-scale-factor=2 --window-size="$cssW,$cssH" `
            --screenshot="$pngPath" (ConvertTo-FileUrl $wrapPath) 2>&1 | Out-Null
  Start-Sleep -Milliseconds 1500
  return "{0}x{1} css -> {2}x{3} px" -f $cssW, $cssH, ($cssW * 2), ($cssH * 2)
}

# --- Mermaid sources -------------------------------------------------------
Get-ChildItem $diagrams -Filter *.mmd | Where-Object { -not $Only -or $_.BaseName -eq $Only } | ForEach-Object {
  $name = $_.BaseName
  $url  = (ConvertTo-FileUrl $host_) + "#" + [uri]::EscapeDataString((ConvertTo-FileUrl $_.FullName))

  # Chrome emits UTF-8; without this PowerShell decodes stdout using the console
  # codepage and every em dash and middot becomes mojibake.
  $prev = [Console]::OutputEncoding
  [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false
  try {
    $dom = & $chrome --headless --disable-gpu --allow-file-access-from-files `
                     --virtual-time-budget=20000 --dump-dom $url 2>$null | Out-String
  } finally { [Console]::OutputEncoding = $prev }

  $m = [regex]::Match($dom, '<svg[\s\S]*?</svg>')
  if (-not $m.Success) {
    $err = [regex]::Match($dom, '<div id="c">RENDER_ERROR: ([^<]*)</div>')
    if ($err.Success) { Write-Error "$name : $($err.Groups[1].Value)"; return }
    Write-Error "$name : no SVG produced"; return
  }

  $svg = $m.Value
  $vb  = [regex]::Match($svg, 'viewBox="([-\d.]+) ([-\d.]+) ([\d.]+) ([\d.]+)"')
  if (-not $vb.Success) { Write-Error "$name : no viewBox"; return }
  $w = [math]::Ceiling([double]$vb.Groups[3].Value)
  $h = [math]::Ceiling([double]$vb.Groups[4].Value)

  # Opaque white background, so the diagram survives dark mode on any platform.
  $svg = $svg -replace '(<svg[^>]*>)', ('$1<rect x="' + $vb.Groups[1].Value + '" y="' + $vb.Groups[2].Value +
         '" width="' + $w + '" height="' + $h + '" fill="#ffffff"/>')
  if ($svg -notmatch 'xmlns=') { $svg = $svg -replace '<svg', '<svg xmlns="http://www.w3.org/2000/svg"' }

  $svgOut = Join-Path $diagrams "$name.svg"
  Write-Utf8 $svgOut $svg
  $info = Export-Png $svgOut (Join-Path $assets "$name.png") $w $h
  "mmd  {0,-26} {1}" -f $name, $info
}

# --- Hand-authored SVGs ----------------------------------------------------
Get-ChildItem $diagrams -Filter *.svg | Where-Object {
  (-not $Only -or $_.BaseName -eq $Only) -and
  -not (Test-Path (Join-Path $diagrams "$($_.BaseName).mmd"))
} | ForEach-Object {
  $head = Get-Content $_.FullName -TotalCount 2 | Out-String
  $vb = [regex]::Match($head, 'viewBox="([-\d.]+) ([-\d.]+) ([\d.]+) ([\d.]+)"')
  if (-not $vb.Success) { Write-Error "$($_.BaseName) : no viewBox"; return }
  $info = Export-Png $_.FullName (Join-Path $assets "$($_.BaseName).png") `
            ([math]::Ceiling([double]$vb.Groups[3].Value)) ([math]::Ceiling([double]$vb.Groups[4].Value))
  "svg  {0,-26} {1}" -f $_.BaseName, $info
}
