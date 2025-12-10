# ==============================================================================
# Vivado XSim Simulation Script (PowerShell)
# Project: Register Map Comparison Testbench
# Created: 2025-12-05
# ==============================================================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Register Map Simulation Runner" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Set Vivado installation path
$VivadoPath = "C:\xilinx\Vivado\2024.2\bin"
$env:PATH = "$VivadoPath;" + $env:PATH

# Set working directory
$WorkDir = Join-Path $PSScriptRoot "build\reg_map.sim\sim_1\behav\xsim"
Set-Location $WorkDir

Write-Host "Current directory: $PWD" -ForegroundColor Gray
Write-Host "Vivado version: 2024.2" -ForegroundColor Gray
Write-Host ""

# Step 1: Clean previous simulation files
Write-Host "[STEP 1/4] Cleaning previous simulation files..." -ForegroundColor Yellow
if (Test-Path "xsim.dir") {
    Remove-Item -Recurse -Force xsim.dir -ErrorAction SilentlyContinue
    Write-Host "  - Removed xsim.dir" -ForegroundColor Gray
}
Remove-Item webtalk* -ErrorAction SilentlyContinue
Write-Host "  Done." -ForegroundColor Green
Write-Host ""

# Step 2: Compile source files
Write-Host "[STEP 2/4] Compiling source files..." -ForegroundColor Yellow
& .\compile.bat
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Compilation failed!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "  Done." -ForegroundColor Green
Write-Host ""

# Step 3: Elaborate design
Write-Host "[STEP 3/4] Elaborating design..." -ForegroundColor Yellow
& .\elaborate.bat
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Elaboration failed!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "  Done." -ForegroundColor Green
Write-Host ""

# Step 4: Run simulation
Write-Host "[STEP 4/4] Running simulation..." -ForegroundColor Yellow
Write-Host "  (Output will be saved to simulation_result.log)" -ForegroundColor Gray

# Kill any existing xsim processes
Get-Process -Name "xsim*" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

# Run simulation and capture output
xsim tb_reg_map_compare_behav -runall | Tee-Object -FilePath simulation_result.log
Write-Host "  Done." -ForegroundColor Green
Write-Host ""

# Display summary from log file
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Test Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$summary = Get-Content simulation_result.log | Select-String -Pattern "Total Tests|Passed|Failed|Pass Rate|Data Matches|Data Mismatches"
if ($summary) {
    $summary | ForEach-Object {
        if ($_.Line -match "Total Tests") {
            Write-Host $_.Line -ForegroundColor White
        }
        elseif ($_.Line -match "Passed") {
            Write-Host $_.Line -ForegroundColor Green
        }
        elseif ($_.Line -match "Failed|Mismatches") {
            Write-Host $_.Line -ForegroundColor Red
        }
        else {
            Write-Host $_.Line -ForegroundColor Gray
        }
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Simulation complete!" -ForegroundColor Green
Write-Host "Full results saved to: $WorkDir\simulation_result.log" -ForegroundColor Gray
Write-Host ""

# Return to project root
Set-Location $PSScriptRoot

# Auto-exit (comment out next line if you want to pause)
# Read-Host "Press Enter to exit"
