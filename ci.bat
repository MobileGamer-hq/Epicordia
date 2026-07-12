@echo off
echo Running Flutter Analyze...
call flutter analyze
if %errorlevel% neq 0 exit /b %errorlevel%

echo Running Flutter Test...
call flutter test
if %errorlevel% neq 0 exit /b %errorlevel%

echo CI checks passed successfully!
