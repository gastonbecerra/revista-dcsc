param(
    [string]$Paper,
    [switch]$All
)

$root = Split-Path -Parent $PSCommandPath
$python = "C:\Users\Gaston\AppData\Local\Programs\Python\Python313\python.exe"
$print_script = Join-Path $root "print_pdf.py"

function Invoke-PrintPDF {
    param($HtmlPath)
    $Dir = Split-Path (Split-Path $HtmlPath -Parent) -Parent
    $PaperName = Split-Path $Dir -Leaf
    # inject @page rule if missing (outputs/ is gitignored)
    $content = Get-Content $HtmlPath -Raw
    if ($content -notmatch '@page') {
        $content = $content -replace '<style>', "<style>`n@page { size: A4; margin: 0.75cm; }"
        Set-Content $HtmlPath -Value $content
    }
    Write-Host "Generando PDF: $PaperName" -ForegroundColor Cyan
    Push-Location $Dir
    try {
        & $python $print_script $HtmlPath
    } finally {
        Pop-Location
    }
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
