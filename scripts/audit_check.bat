@echo off
setlocal

cd /d "%~dp0.."

python "%~dp0audit_check.py"
exit /b %errorlevel%
