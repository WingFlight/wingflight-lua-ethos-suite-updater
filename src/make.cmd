@echo off
setlocal
cd /d %~dp0

if not defined UPDATER_VERSION set UPDATER_VERSION=0.0.6

REM Build in a private venv so the global Python's packages cannot leak in.
REM In particular the old `hid` package also imports as `hid` and shadows
REM hidapi, which would ship an updater without working USB HID support.
set BUILD_VENV=%~dp0.build-venv
set PY=%BUILD_VENV%\Scripts\python.exe

echo [1/7] Preparing build environment (%BUILD_VENV%)...
if not exist "%PY%" (
    python -m venv "%BUILD_VENV%" || goto :error
)

echo [2/7] Installing updater requirements and PyInstaller...
"%PY%" -m pip install --disable-pip-version-check -q -r requirements_updater.txt pyinstaller || goto :error

echo [3/7] Checking HID and Windows modules will be bundled...
"%PY%" -c "import hid, win32api, win32file; assert hasattr(hid, 'device'), 'hid is not hidapi: ' + hid.__file__; print('    HID module:', hid.__file__)" || goto :error

echo [4/7] Generating version info (%UPDATER_VERSION%)...
"%PY%" gen_version_info.py || goto :error

echo [5/7] Compiling update_radio_gui.py to standalone EXE...
"%PY%" -m PyInstaller --onefile --noupx update_radio_gui.py --name wingflight-lua-ethos-suite-updater --windowed --version-file version_info.txt --icon icon.ico || goto :error

echo [6/7] Moving wingflight-lua-ethos-suite-updater.exe into parent folder...
if exist ..\wingflight-lua-ethos-suite-updater.exe (
    del ..\wingflight-lua-ethos-suite-updater.exe
)
move /Y dist\wingflight-lua-ethos-suite-updater.exe ..\wingflight-lua-ethos-suite-updater.exe >nul

echo [7/7] Cleaning up build tree...
rd /s /q build
rd /s /q dist
del /q wingflight-lua-ethos-suite-updater.spec

echo Build complete. wingflight-lua-ethos-suite-updater.exe is ready at: ..\wingflight-lua-ethos-suite-updater.exe
goto :eof

:error
echo Build failed.
exit /b 1
