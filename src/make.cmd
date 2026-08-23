@echo off
setlocal
cd /d %~dp0

if not defined UPDATER_VERSION set UPDATER_VERSION=0.0.6

echo [1/6] Checking for pyinstaller...
pyinstaller --version >nul 2>&1
if errorlevel 1 (
    echo PyInstaller not found. Installing...
    pip install pyinstaller || goto :error
)

echo [2/6] Generating version info (%UPDATER_VERSION%)...
python gen_version_info.py || goto :error

echo [3/6] Compiling update_radio_gui.py to standalone EXE...
python -m PyInstaller --onefile --noupx update_radio_gui.py --name wingflight-lua-ethos-suite-updater --windowed --version-file version_info.txt --icon icon.ico || goto :error

echo [4/6] Moving wingflight-lua-ethos-suite-updater.exe into parent folder...
if exist ..\wingflight-lua-ethos-suite-updater.exe (
    del ..\wingflight-lua-ethos-suite-updater.exe
)
move /Y dist\wingflight-lua-ethos-suite-updater.exe ..\wingflight-lua-ethos-suite-updater.exe >nul

echo [5/6] Cleaning up build tree...
rd /s /q build
rd /s /q dist
del /q wingflight-lua-ethos-suite-updater.spec

echo [6/6] ✅ Build complete. wingflight-lua-ethos-suite-updater.exe is ready at: ..\wingflight-lua-ethos-suite-updater.exe
goto :eof

:error
echo ❌ Build failed.
exit /b 1
