@echo off
setlocal EnableExtensions

rem "========================================================================"
rem  Cross-platform LaTeX build wrapper for compile.py
rem
rem  Handles every contingency: missing Python, missing compile.py,
rem  missing pdflatex/biber. Delegates the actual build to compile.py
rem  and propagates its exit code.
rem
rem  Usage:
rem      compile.bat
rem      compile.bat main.tex
rem      compile.bat main.tex --no-clean-after
rem "========================================================================"

cd /d "%~dp0"

rem ---------------------------------------------------------------------------
rem 1. Find Python (py launcher -> python -> python3)
rem ---------------------------------------------------------------------------
set "PYTHON="
where py >nul 2>&1 && set "PYTHON=py"
if not defined PYTHON where python >nul 2>&1 && set "PYTHON=python"
if not defined PYTHON where python3 >nul 2>&1 && set "PYTHON=python3"

if not defined PYTHON (
    >&2 echo ERROR: Python was not found in PATH.
    >&2 echo.
    >&2 echo Please install Python 3, then re-run this script:
    >&2 echo   - Windows: install from https://www.python.org/downloads/
    >&2 echo     check "Add Python to PATH" during setup
    >&2 echo   - Or via winget:  winget install Python.Python.3.12
    exit /b 1
)

rem ---------------------------------------------------------------------------
rem 2. Ensure compile.py is present
rem ---------------------------------------------------------------------------
if not exist "compile.py" (
    >&2 echo ERROR: compile.py not found next to this script.
    >&2 echo.
    >&2 echo Make sure both files ^(compile.bat and compile.py^) are in the
    >&2 echo same directory, then re-run this script.
    exit /b 1
)

rem ---------------------------------------------------------------------------
rem 3. Check required LaTeX tools
rem ---------------------------------------------------------------------------
set "MISSING=NO"
>nul 2>&1 where pdflatex || set "MISSING=YES"
>nul 2>&1 where biber    || set "MISSING=YES"

if "%MISSING%"=="YES" (
    >&2 echo ERROR: pdflatex and/or biber was not found in PATH.
    >&2 echo.
    >&2 echo Please install a full TeX distribution that includes both:
    >&2 echo   - MiKTeX:        winget install MiKTeX.MiKTeX
    >&2 echo   - TeX Live:      install via https://tug.org/texlive/
    >&2 echo.
    >&2 echo Afterwards, open a NEW terminal so PATH picks up the tools.
    >&2 echo Verify with:  pdflatex --version   and   biber --version
    exit /b 1
)

rem ---------------------------------------------------------------------------
rem 4. Run the build
rem ---------------------------------------------------------------------------
%PYTHON% compile.py %*
exit /b %ERRORLEVEL%
