<#
  build.ps1 — replace the placeholder base URL with your real one.

  Usage (PowerShell):
    .\build.ps1 -BaseUrl "https://kullanici.github.io/ekransiz-android-scrcpy/"

  Reads and writes explicit UTF-8 (no BOM) so Turkish/Unicode text is not
  re-encoded by the console code page.
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$BaseUrl
)

if (-not $BaseUrl.EndsWith('/')) { $BaseUrl += '/' }

$old  = 'https://USERNAME.github.io/ekransiz-android-scrcpy/'
$root = $PSScriptRoot
$utf8 = New-Object System.Text.UTF8Encoding($false)

$files = Get-ChildItem -Path $root -Recurse -File | Where-Object {
    $_.Extension -in '.html', '.xml', '.txt', '.md'
}

$changed = 0
foreach ($f in $files) {
    $c = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
    if ($c -and $c.Contains($old)) {
        $c = $c.Replace($old, $BaseUrl)
        [System.IO.File]::WriteAllText($f.FullName, $c, $utf8)
        Write-Output ("updated: " + $f.FullName)
        $changed++
    }
}

Write-Output ("done. files updated: " + $changed)
Write-Output ("base url: " + $BaseUrl)
