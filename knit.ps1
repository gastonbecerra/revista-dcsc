param(
    [string]$Paper,
    [switch]$All
)

$Rscript = "D:\Rbin\R-4.4.1\bin\Rscript.exe"
$root = Split-Path -Parent $PSCommandPath

function Invoke-Knit {
    param($Dir)
    $rmd = Get-ChildItem -Path $Dir -Filter "*.Rmd" | Select-Object -First 1
    if (-not $rmd) {
        Write-Warning "  No se encontró .Rmd en $Dir"
        return
    }
    Write-Host "`n=== Knitteando $($rmd.Directory.Name)/$($rmd.Name) ===" -ForegroundColor Cyan
    Push-Location $Dir
    try {
        & $Rscript -e "rmarkdown::render('$($rmd.Name)', output_dir = './outputs')"
    } finally {
        Pop-Location
    }
}

if ($All) {
    Get-ChildItem -Path $root -Directory | Where-Object {
        $_.Name -notin @("template", "plantillas", ".git") -and
        (Get-ChildItem -Path $_.FullName -Filter "*.Rmd")
    } | ForEach-Object { Invoke-Knit $_.FullName }
    exit
}

if ($Paper) {
    $dir = Join-Path $root $Paper
    if (-not (Test-Path $dir)) {
        Write-Error "No existe la carpeta: $dir"
        exit 1
    }
    Invoke-Knit $dir
    exit
}

# Sin argumentos: knittea el directorio actual si tiene .Rmd
$cur = (Get-Location).Path
if (Get-ChildItem -Path $cur -Filter "*.Rmd") {
    Invoke-Knit $cur
} else {
    Write-Error "Uso: .\knit.ps1 <carpeta>    o    .\knit.ps1 -All"
    exit 1
}
