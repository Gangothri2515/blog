<#
  Pulls the long fenced blocks out of a post into gists/ as standalone files.

  Medium has no syntax highlighting and wraps long lines, which destroys the
  column alignment of console output. The fix is to embed those blocks as GitHub
  Gists instead. This script writes each one to a file named with the extension
  that makes Gist pick the right highlighting, ready to paste.

  Usage:
    powershell -ExecutionPolicy Bypass -File tools\extract-gists.ps1 -Post 001-work-that-cannot-be-parallelised
#>
param(
  [Parameter(Mandatory = $true)][string]$Post,
  [int]$MinLines = 6
)

$ErrorActionPreference = "Stop"

$repo    = Split-Path $PSScriptRoot -Parent
$postDir = Join-Path $repo "posts\$Post"
$index   = Join-Path $postDir "index.md"
$outDir  = Join-Path $postDir "gists"

if (-not (Test-Path $index)) { throw "No index.md at $index" }
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$ext = @{ sql = "sql"; diff = "diff"; bash = "sh"; powershell = "ps1"; "" = "txt" }

$lines   = Get-Content $index
$inFence = $false
$buf     = @()
$lang    = ""
$start   = 0
$n       = 0

foreach ($i in 0..($lines.Count - 1)) {
  $l = $lines[$i]
  if ($l -match '^```(.*)$') {
    if (-not $inFence) {
      $inFence = $true; $lang = $matches[1].Trim(); $buf = @(); $start = $i + 1
    } else {
      $inFence = $false
      # Mermaid blocks become PNGs, not Gists.
      if ($lang -ne 'mermaid' -and $buf.Count -ge $MinLines) {
        $n++
        $e    = if ($ext.ContainsKey($lang)) { $ext[$lang] } else { "txt" }
        $name = "{0:D2}-line{1}.{2}" -f $n, $start, $e
        [System.IO.File]::WriteAllLines((Join-Path $outDir $name), $buf,
          (New-Object System.Text.UTF8Encoding $false))
        $widest = ($buf | Measure-Object -Property Length -Maximum).Maximum
        "{0,-22} from line {1,4}  {2,3} lines  widest {3,3} chars{4}" -f `
          $name, $start, $buf.Count, $widest,
          $(if ($widest -gt 80) { "  <- would wrap in a Medium code block" } else { "" })
      }
      $lang = ""
    }
  } elseif ($inFence) {
    $buf += $l
  }
}

if ($n -eq 0) { "No blocks of $MinLines+ lines found." }
