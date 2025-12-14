@echo off
setlocal EnableExtensions

set "BUCKAL_LLD_LINK_MACHINE=ARM64"
python "%~dp0lld_link.py" %*
exit /b %errorlevel%
