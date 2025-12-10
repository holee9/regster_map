@echo off
REM ==============================================================================
REM Vivado XSim Simulation Script
REM Project: Register Map Comparison Testbench
REM Created: 2025-12-05
REM ==============================================================================

echo ========================================
echo  Register Map Simulation Runner
echo ========================================
echo.

REM Set Vivado installation path
set VIVADO_PATH=C:\xilinx\Vivado\2024.2\bin
set PATH=%VIVADO_PATH%;%PATH%

REM Set working directory
set WORK_DIR=%~dp0build\reg_map.sim\sim_1\behav\xsim
cd /d "%WORK_DIR%"

echo Current directory: %CD%
echo Vivado version: 2024.2
echo.

REM Step 1: Clean previous simulation files
echo [STEP 1/4] Cleaning previous simulation files...
if exist xsim.dir (
    rmdir /s /q xsim.dir
    echo   - Removed xsim.dir
)
if exist webtalk.jou (
    del /q webtalk*
    echo   - Removed webtalk files
)
echo   Done.
echo.

REM Step 2: Compile source files
echo [STEP 2/4] Compiling source files...
call compile.bat
if %errorlevel% neq 0 (
    echo ERROR: Compilation failed!
    pause
    exit /b 1
)
echo   Done.
echo.

REM Step 3: Elaborate design
echo [STEP 3/4] Elaborating design...
call elaborate.bat
if %errorlevel% neq 0 (
    echo ERROR: Elaboration failed!
    pause
    exit /b 1
)
echo   Done.
echo.

REM Step 4: Run simulation
echo [STEP 4/4] Running simulation...
echo   (Output will be saved to simulation_result.log)
xsim tb_reg_map_compare_behav -runall > simulation_result.log 2>&1
if %errorlevel% neq 0 (
    echo WARNING: Simulation may have warnings/errors
)
echo   Done.
echo.

REM Display summary from log file
echo ========================================
echo  Test Summary
echo ========================================
findstr /C:"Total Tests" /C:"Passed" /C:"Failed" /C:"Pass Rate" simulation_result.log
echo ========================================
echo.

echo Simulation complete!
echo Full results saved to: %WORK_DIR%\simulation_result.log
echo.

REM Return to project root
cd /d "%~dp0"

pause
