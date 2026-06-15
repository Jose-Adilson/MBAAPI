# Build script for performance benchmarking
# Generates JIT and AOT builds for comparison

$ErrorActionPreference = "Stop"

Write-Host "MBAAPI Build Script - JIT and AOT Compilation" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

$outputDir = "./build-output"
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

# Build JIT Release
Write-Host "[1/4] Building JIT Release..." -ForegroundColor Yellow
dotnet build -c Release -o "$outputDir/jit-release" --no-incremental
if ($LASTEXITCODE -ne 0) { throw "JIT Release build failed" }
Write-Host "✓ JIT Release build completed" -ForegroundColor Green
Write-Host ""

# Publish JIT Release (self-contained optional)
Write-Host "[2/4] Publishing JIT Release..." -ForegroundColor Yellow
dotnet publish -c Release -o "$outputDir/jit-publish" --no-build --no-restore
if ($LASTEXITCODE -ne 0) { throw "JIT Release publish failed" }
Write-Host "✓ JIT Release publish completed" -ForegroundColor Green
Write-Host ""

# Build AOT Release
Write-Host "[3/4] Building ReleaseAOT..." -ForegroundColor Yellow
dotnet build -c ReleaseAOT -o "$outputDir/aot-release" --no-incremental
if ($LASTEXITCODE -ne 0) { throw "AOT Release build failed" }
Write-Host "✓ AOT Release build completed" -ForegroundColor Green
Write-Host ""

# Publish AOT Release
Write-Host "[4/4] Publishing ReleaseAOT..." -ForegroundColor Yellow
dotnet publish -c ReleaseAOT -o "$outputDir/aot-publish" --no-build --no-restore
if ($LASTEXITCODE -ne 0) { throw "AOT Release publish failed" }
Write-Host "✓ AOT Release publish completed" -ForegroundColor Green
Write-Host ""

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Build Summary:" -ForegroundColor Cyan
Write-Host ""

# Display sizes
$jitSize = (Get-ChildItem "$outputDir/jit-publish" -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
$aotSize = (Get-ChildItem "$outputDir/aot-publish" -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB

Write-Host "JIT Publish Size: $([Math]::Round($jitSize, 2)) MB" -ForegroundColor Cyan
Write-Host "AOT Publish Size: $([Math]::Round($aotSize, 2)) MB" -ForegroundColor Cyan
Write-Host ""
Write-Host "Output directories:" -ForegroundColor Green
Write-Host "  - JIT Release:  $outputDir/jit-release" -ForegroundColor Cyan
Write-Host "  - JIT Publish:  $outputDir/jit-publish" -ForegroundColor Cyan
Write-Host "  - AOT Release:  $outputDir/aot-release" -ForegroundColor Cyan
Write-Host "  - AOT Publish:  $outputDir/aot-publish" -ForegroundColor Cyan
Write-Host ""
