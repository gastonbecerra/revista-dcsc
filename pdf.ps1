param(
    [string]$Paper,
    [switch]$All
)

$root = Split-Path -Parent $PSCommandPath
$preview = Join-Path $root "_preview"
$python = "C:\Users\Gaston\AppData\Local\Programs\Python\Python313\python.exe"
$print_script = Join-Path $root "print_pdf.py"

if (-not (Test-Path $preview)) { New-Item -ItemType Directory -Path $preview -Force | Out-Null }

function Invoke-PrintPDF {
    param($HtmlPath)
    $name = [System.IO.Path]::GetFileName($HtmlPath)
    $dest = Join-Path $preview $name
    Copy-Item $HtmlPath $dest -Force
    # inject @page rule
    $content = Get-Content $dest -Raw
    if ($content -notmatch '@page') {
        $content = $content -replace '<style>', "<style>`n@page { size: A4; margin: 0.75cm; }"
        Set-Content $dest -Value $content -NoNewline
    }
    Write-Host "Generando PDF: $name" -ForegroundColor Cyan
    & $python $print_script $dest
}

if ($All) {
    Get-ChildItem -Path $root -Directory | Where-Object {
        $_.Name -notin @("template", "plantillas", ".git", "_preview") -and
        (Test-Path (Join-Path $_.FullName "outputs\*.html"))
    } | ForEach-Object {
        $html = Get-ChildItem -Path (Join-Path $_.FullName "outputs") -Filter "*.html" | Select-Object -First 1
        if ($html) { Invoke-PrintPDF $html.FullName }
    }
    exit
}

if ($Paper) {
    $dir = Join-Path $root $Paper
    $html = Get-ChildItem -Path (Join-Path $dir "outputs") -Filter "*.html" | Select-Object -First 1
    if (-not $html) { Write-Error "No se encontró .html en $dir\outputs"; exit 1 }
    Invoke-PrintPDF $html.FullName
    exit
}

Write-Error "Uso: .\pdf.ps1 <carpeta>    o    .\pdf.ps1 -All"
exit 1
