@echo off
setlocal
set INSTALLSRCDIR=.

set BUILDDIR=build\
rem set JAWSDIR=%appdata%\Freedom Scientific\JAWS\17.0\settings\enu
rem source files
rem set SCRIPTSRC=audacity.jdf audacity.jkm audacity.jsd audacity.jsm audacity.jss audacity.qs audacity.qsm
rem set OTHERSRC=readme_vi.txt copying.txt "What's new.txt"
REM These are basenames of .md files that should be staged as .txt files.
rem set markdownsrc=readme
set INSTALLSRC=JFW.nsh JFW_lang_deu.nsh JFW_lang_enu.nsh JFW_lang_esn.nsh jawsutil.vbs sample\vwapp.nsi sample\notepad.nsi readme.md
set UNINSTLOGDIR=uninstlog
set UNINSTLOGSRC=%UNINSTLOGDIR%\uninstlog.nsh %UNINSTLOGDIR%\uninstlog_deu.nsh %UNINSTLOGDIR%\uninstlog_enu.nsh %UNINSTLOGDIR%\uninstlog_esn.nsh %UNINSTLOGDIR%\logging.nsh
if "%1"=="/?" goto help
if "%1"=="-?" goto help
if "%1"=="-h" goto help
if "%1"=="--help" goto help
if not "%1"=="" goto loop
:help
echo usage: build opt...
echo where opt is:
echo b - remove and make build folder structure
echo c - remove build folder
echo i - make vwapp installer
echo n - make notepad installer
goto done

:loop
if "%1"=="" goto done
if "%1"=="b" goto build
if "%1"=="c" goto clean
if "%1"=="i" goto vwapp
if "%1"=="v" goto vwapp
if "%1"=="n" goto notepad
echo invalid option "%1"
goto help

:clean
rd /q /s %BUILDDIR%
goto next

:build
if exist %BUILDDIR% rd /q /s %BUILDDIR%
mkdir %BUILDDIR% %BUILDDIR%\script %BUILDDIR%\script\lang %BUILDDIR%\script\lang\esn
for %%i in (%INSTALLSRC% %UNINSTLOGSRC%) do copy %INSTALLSRCDIR%\%%i %BUILDDIR%
rem for %%i in (%SCRIPTSRC% %OTHERSRC%) do copy %%i %BUILDDIR%script
xcopy sample\script %BUILDDIR%\script /S
rem for %%i in (%markdownsrc%) do copy %%i.md %BUILDDIR%script\%%i.txt
goto next
:notepad
set instfile=notepad
goto installer
:vwapp
set instfile=vwapp
:installer
if not exist "%programfiles(x86)%" goto installer32
"%programfiles(x86)%\nsis\makensis" "%BUILDDIR%\%instfile%.nsi"
goto next
:installer32
"%programfiles%\nsis\makensis" "%BUILDDIR%\%instfile%.nsi"
goto next
:next
shift
goto loop
:done
