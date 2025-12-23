@echo off
setlocal EnableExtensions

set "BUCKAL_LLD_LINK_MACHINE=X86"
python "%~dp0lld_link.py" %*
exit /b %errorlevel%
