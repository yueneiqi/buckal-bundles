@echo off
setlocal EnableExtensions

rem Resolve Rust sysroot and host triple, then invoke the bundled lld-link.exe.

for /f "delims=" %%I in ('rustc --print sysroot') do set "SYSROOT=%%I"

set "HOST_TRIPLE="
for /f "tokens=1,* delims=:" %%A in ('rustc -vV ^| findstr /b "host:"') do (
  set "HOST_TRIPLE=%%B"
)
set "HOST_TRIPLE=%HOST_TRIPLE: =%"

if "%HOST_TRIPLE%"=="" (
  echo lld-link.bat: failed to determine Rust host triple via "rustc -vV" 1>&2
  exit /b 1
)

set "LLD_LINK=%SYSROOT%\lib\rustlib\%HOST_TRIPLE%\bin\gcc-ld\lld-link.exe"
if exist "%LLD_LINK%" goto :run

set "LLD_LINK=%SYSROOT%\bin\rust-lld.exe"
if exist "%LLD_LINK%" goto :run

echo lld-link.bat: lld-link executable not found under "%SYSROOT%" 1>&2
exit /b 1

:run
"%LLD_LINK%" %*
exit /b %errorlevel%

