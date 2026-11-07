<#
  build.ps1 — replace the placeholder base URL with your real one.

  Usage (PowerShell):
    .\build.ps1 -BaseUrl "https://kullanici.github.io/ekransiz-android-scrcpy/"

  Then upload the contents of this folder to GitHub Pages, Cloudflare Pages,
  Netlify, or any static host.
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$BaseUrl
)

if (-not $BaseUrl.EndsWith('/')) { $BaseUrl += '/' }

$old  = 'https://USERNAME.github.io/ekransiz-android-scrcpy/'
$root = $PSScriptRoot

$files = Get-ChildItem -Path $root -Recurse -File | Where-Object {
    $_.Extension -in '.html', '.xml', '.txt', '.md'
}

$changed = 0
foreach ($f in $files) {
    $c = Get-Content -Path $f.FullName -Raw
    if ($c -and $c.Contains($old)) {
        $c = $c.Replace($old, $BaseUrl)
        Set-Content -Path $f.FullName -Value $c -NoNewline -Encoding utf8
        Write-Output ("updated: " + $f.FullName)
        $changed++
    }
}

Write-Output ("done. files updated: " + $changed)
Write-Output ("base url: " + $BaseUrl)
