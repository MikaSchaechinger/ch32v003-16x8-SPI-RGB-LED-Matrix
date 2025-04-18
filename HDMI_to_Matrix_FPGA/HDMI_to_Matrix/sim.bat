@echo off
setlocal enabledelayedexpansion

set "source_folder=src"
set "output_folder=sim"
set "object_folder=objects"
set "testbenches="

:: Durchsuche das Quellverzeichnis und seine Unterordner nach Verilog-Dateien
set /a testbench_folder_counter=0
for /r %source_folder%\%testbench_folder% %%i in (*_tb.v *_tb.sv) do (
    set "filename=%%~ni"
    set "testbenches=!testbenches!,!filename!"
    set /a testbench_folder_counter+=1
)

:: Durchsuche das Quellverzeichnis und seine Unterordner nach Verilog-Dateien
::for /r %source_folder% %%i in (*.v *.sv) do (
::    set "files=!files! "%%i""
::)
:: Verwende PowerShell, um alle .v/.sv Dateien zu finden, die **nicht** 'pragma protect' enthalten
for /f "usebackq delims=" %%i in (`powershell -Command "Get-ChildItem -Recurse -Include *.v,*.sv -Path '%source_folder%' | Where-Object { -not ($_ | Select-String -Pattern 'pragma protect' -quiet) } | ForEach-Object { $_.FullName }"`) do (
    set "files=!files! "%%i""
)


:: Entferne das erste Komma, falls die Liste nicht leer ist
if not "!testbenches!"=="" set "testbenches=!testbenches:~1!"



echo =============================================================
echo %testbench_folder_counter% Testbenches found: %testbenches%
echo:
::echo Compiling Verilog files in %source_folder% and its subfolders
::echo:



:: Erzeuge das Ausgabeverzeichnis und das Objektverzeichnis, falls sie nicht existieren
if not exist %output_folder% mkdir %output_folder%
if not exist %output_folder%\%object_folder% mkdir %output_folder%\%object_folder%

REM Delete all .o files in the object folder
del %output_folder%\%object_folder%\*.o >nul 2>nul


REM Success and Error Counter
set /a success_counter=0
set /a error_counter=0

:: Trenne die Liste der Testbenches in ein Array auf
for %%b in (%testbenches%) do (
    echo.
    echo Compiling %%b
    iverilog -g2012 -o %output_folder%\%object_folder%\%%b.o -s %%b %files%
    REM for /f %%A in ('iverilog -g2012 -o %output_folder%\%object_folder%\%%b.o -s %%b %files%') do set temp_output=%%A
    
    REM Check if .o file was created
    if exist %output_folder%\%object_folder%\%%b.o (
        vvp %output_folder%\%object_folder%\%%b.o >nul
        move *.vcd %output_folder%\ >nul 2>nul
        set /a success_counter+=1
    ) else (
        REM Compilation error
        set /a error_counter+=1
        echo:
    )
    
)

REM Show Success and error counter
echo %success_counter% Testbenches successfully compiled, %error_counter% errors occured.
echo:



endlocal


